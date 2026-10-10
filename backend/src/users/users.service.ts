import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import * as bcrypt from 'bcrypt';
import { createHmac, randomBytes, randomInt, timingSafeEqual } from 'crypto';
import { Model } from 'mongoose';

import { CreateUserDto } from './dto/create-user.dto';
import { MailService } from './mail.service';
import { User, UserDocument } from './schemas/user.schema';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly configService: ConfigService,
    private readonly mailService: MailService,
    private readonly jwtService: JwtService,
  ) {}

  async create(createUserDto: CreateUserDto) {
    const normalizedEmail = createUserDto.email.trim().toLowerCase();
    const existingUser = await this.userModel.exists({ email: normalizedEmail });
    if (existingUser) {
      throw new ConflictException('Un compte existe déjà avec cette adresse e-mail.');
    }

    const { password, ...profile } = createUserDto;
    const passwordHash = await bcrypt.hash(password, 12);
    const user = await this.userModel.create({
      ...profile,
      email: normalizedEmail,
      birthDate: new Date(createUserDto.birthDate),
      passwordHash,
    });

    return this.toPublicUser(user);
  }

  async findAll() {
    return this.userModel
      .find()
      .select('-passwordHash')
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  async login(rawEmail: string, password: string, rememberMe: boolean) {
    const email = rawEmail.trim().toLowerCase();
    const user = await this.userModel
      .findOne({ email })
      .select('+passwordHash')
      .exec();

    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      throw new UnauthorizedException('Adresse e-mail ou mot de passe incorrect.');
    }

    return this.createSession(user, rememberMe);
  }

  async refreshSession(refreshToken: string) {
    const refreshTokenHash = this.hashRefreshToken(refreshToken);
    const user = await this.userModel
      .findOne({
        refreshTokenHash,
        refreshTokenExpiresAt: { $gt: new Date() },
      })
      .select('+refreshTokenHash +refreshTokenExpiresAt')
      .exec();

    if (!user?.refreshTokenExpiresAt) {
      throw new UnauthorizedException('Votre session a expiré.');
    }

    return this.createSession(user, true, user.refreshTokenExpiresAt);
  }

  async logout(refreshToken: string) {
    await this.userModel
      .updateOne(
        { refreshTokenHash: this.hashRefreshToken(refreshToken) },
        { $unset: { refreshTokenHash: 1, refreshTokenExpiresAt: 1 } },
      )
      .exec();
    return { message: 'Déconnexion réussie.' };
  }

  async requestPasswordChange(
    authorization: string | undefined,
    currentPassword: string,
    newPassword: string,
  ) {
    const userId = await this.userIdFromAuthorization(authorization);
    const user = await this.userModel
      .findById(userId)
      .select('+passwordHash')
      .exec();
    if (!user || !(await bcrypt.compare(currentPassword, user.passwordHash))) {
      throw new UnauthorizedException('Le mot de passe actuel est incorrect.');
    }
    if (await bcrypt.compare(newPassword, user.passwordHash)) {
      throw new BadRequestException(
        'Le nouveau mot de passe doit être différent du mot de passe actuel.',
      );
    }

    user.pendingPasswordHash = await bcrypt.hash(newPassword, 12);
    return this.issuePasswordChangeCode(user);
  }

  async resendPasswordChangeCode(authorization: string | undefined) {
    const userId = await this.userIdFromAuthorization(authorization);
    const user = await this.userModel
      .findById(userId)
      .select('+pendingPasswordHash')
      .exec();
    if (!user?.pendingPasswordHash) {
      throw new BadRequestException(
        'Aucune demande de changement de mot de passe n’est en attente.',
      );
    }
    return this.issuePasswordChangeCode(user);
  }

  async confirmPasswordChange(
    authorization: string | undefined,
    code: string,
  ) {
    const userId = await this.userIdFromAuthorization(authorization);
    const user = await this.userModel
      .findById(userId)
      .select(
        '+pendingPasswordHash +passwordChangeCodeHash +passwordChangeCodeExpiresAt +passwordChangeCodeAttempts +refreshTokenExpiresAt',
      )
      .exec();
    const invalidCode = new BadRequestException(
      'Le code est invalide ou a expiré.',
    );
    if (
      !user?.pendingPasswordHash ||
      !user.passwordChangeCodeHash ||
      !user.passwordChangeCodeExpiresAt ||
      user.passwordChangeCodeExpiresAt.getTime() <= Date.now()
    ) {
      throw invalidCode;
    }

    const attempts = user.passwordChangeCodeAttempts ?? 0;
    if (attempts >= 5) throw invalidCode;
    if (!this.secretsMatch(user.passwordChangeCodeHash, code)) {
      user.passwordChangeCodeAttempts = attempts + 1;
      if (user.passwordChangeCodeAttempts >= 5) {
        user.passwordChangeCodeHash = undefined;
        user.passwordChangeCodeExpiresAt = undefined;
      }
      await user.save();
      throw invalidCode;
    }

    const existingRefreshExpiry = user.refreshTokenExpiresAt;
    user.passwordHash = user.pendingPasswordHash;
    user.pendingPasswordHash = undefined;
    user.passwordChangeCodeHash = undefined;
    user.passwordChangeCodeExpiresAt = undefined;
    user.passwordChangeCodeAttempts = 0;

    const session = await this.createSession(
      user,
      true,
      existingRefreshExpiry,
    );
    try {
      await this.mailService.sendPasswordChangedNotification(user.email);
    } catch (error) {
      console.warn('Password changed, but the notification email failed.', error);
    }
    return session;
  }

  async requestPasswordReset(rawEmail: string) {
    const email = rawEmail.trim().toLowerCase();
    const user = await this.userModel.findOne({ email }).exec();
    const response = {
      message:
        'Si un compte correspond à cette adresse, un code de vérification a été envoyé.',
    };

    if (!user) return response;

    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    user.passwordResetCodeHash = this.hashResetSecret(code);
    user.passwordResetCodeExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
    user.passwordResetCodeAttempts = 0;
    user.passwordResetTokenHash = undefined;
    user.passwordResetTokenExpiresAt = undefined;
    await user.save();

    const emailSent = await this.mailService.sendPasswordResetCode(email, code);
    if (!emailSent && this.configService.get('NODE_ENV') !== 'production') {
      return { ...response, debugCode: code };
    }
    return response;
  }

  async verifyPasswordResetCode(rawEmail: string, code: string) {
    const email = rawEmail.trim().toLowerCase();
    const user = await this.userModel
      .findOne({ email })
      .select(
        '+passwordResetCodeHash +passwordResetCodeExpiresAt +passwordResetCodeAttempts',
      )
      .exec();

    const invalidCode = new BadRequestException(
      'Le code est invalide ou a expiré.',
    );
    if (
      !user?.passwordResetCodeHash ||
      !user.passwordResetCodeExpiresAt ||
      user.passwordResetCodeExpiresAt.getTime() <= Date.now()
    ) {
      throw invalidCode;
    }

    const attempts = user.passwordResetCodeAttempts ?? 0;
    if (attempts >= 5) throw invalidCode;

    if (!this.secretsMatch(user.passwordResetCodeHash, code)) {
      user.passwordResetCodeAttempts = attempts + 1;
      if (user.passwordResetCodeAttempts >= 5) {
        user.passwordResetCodeHash = undefined;
        user.passwordResetCodeExpiresAt = undefined;
      }
      await user.save();
      throw invalidCode;
    }

    const resetToken = randomBytes(32).toString('hex');
    user.passwordResetTokenHash = this.hashResetSecret(resetToken);
    user.passwordResetTokenExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
    user.passwordResetCodeHash = undefined;
    user.passwordResetCodeExpiresAt = undefined;
    user.passwordResetCodeAttempts = 0;
    await user.save();

    return { resetToken };
  }

  async resetPassword(resetToken: string, newPassword: string) {
    const tokenHash = this.hashResetSecret(resetToken);
    const user = await this.userModel
      .findOne({
        passwordResetTokenHash: tokenHash,
        passwordResetTokenExpiresAt: { $gt: new Date() },
      })
      .select('+passwordResetTokenHash +passwordResetTokenExpiresAt')
      .exec();

    if (!user) {
      throw new BadRequestException(
        'La demande de réinitialisation est invalide ou a expiré.',
      );
    }

    user.passwordHash = await bcrypt.hash(newPassword, 12);
    user.passwordResetTokenHash = undefined;
    user.passwordResetTokenExpiresAt = undefined;
    user.refreshTokenHash = undefined;
    user.refreshTokenExpiresAt = undefined;
    await user.save();

    return { message: 'Votre mot de passe a été réinitialisé avec succès.' };
  }

  private hashResetSecret(value: string) {
    const secret =
      this.configService.get<string>('PASSWORD_RESET_SECRET') ??
      'chargini-development-reset-secret-change-me';
    return createHmac('sha256', secret).update(value).digest('hex');
  }

  private hashRefreshToken(value: string) {
    const secret =
      this.configService.get<string>('JWT_SECRET') ??
      'chargini-development-jwt-secret-change-me';
    return createHmac('sha256', secret).update(value).digest('hex');
  }

  private async userIdFromAuthorization(authorization?: string) {
    const match = authorization?.match(/^Bearer\s+(.+)$/i);
    if (!match) throw new UnauthorizedException('Authentification requise.');
    try {
      const payload = await this.jwtService.verifyAsync<{ sub?: string }>(
        match[1],
      );
      if (!payload.sub) throw new Error('Missing subject');
      return payload.sub;
    } catch (_) {
      throw new UnauthorizedException('Votre session a expiré.');
    }
  }

  private async issuePasswordChangeCode(user: UserDocument) {
    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    user.passwordChangeCodeHash = this.hashResetSecret(code);
    user.passwordChangeCodeExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
    user.passwordChangeCodeAttempts = 0;
    await user.save();

    const response = {
      message: 'Un code de vérification a été envoyé à votre adresse e-mail.',
    };
    const emailSent = await this.mailService.sendPasswordChangeCode(
      user.email,
      code,
    );
    if (!emailSent && this.configService.get('NODE_ENV') !== 'production') {
      return { ...response, debugCode: code };
    }
    return response;
  }

  private async createSession(
    user: UserDocument,
    rememberMe: boolean,
    existingRefreshExpiry?: Date,
  ) {
    const accessToken = await this.jwtService.signAsync({
      sub: user.id,
      email: user.email,
      role: user.role,
    });
    const refreshToken = randomBytes(48).toString('hex');
    const refreshTokenExpiresAt =
      existingRefreshExpiry ??
      new Date(
        Date.now() +
          (rememberMe ? 30 * 24 * 60 * 60 * 1000 : 24 * 60 * 60 * 1000),
      );

    user.refreshTokenHash = this.hashRefreshToken(refreshToken);
    user.refreshTokenExpiresAt = refreshTokenExpiresAt;
    await user.save();

    return {
      accessToken,
      accessTokenExpiresAt: new Date(Date.now() + 30 * 60 * 1000),
      refreshToken,
      refreshTokenExpiresAt,
      user: this.toPublicUser(user),
    };
  }

  private secretsMatch(storedHash: string, value: string) {
    const candidate = Buffer.from(this.hashResetSecret(value), 'hex');
    const stored = Buffer.from(storedHash, 'hex');
    return candidate.length === stored.length && timingSafeEqual(candidate, stored);
  }

  private toPublicUser(user: UserDocument) {
    const object = user.toObject();
    const {
      passwordHash: _passwordHash,
      passwordResetCodeHash: _passwordResetCodeHash,
      passwordResetCodeExpiresAt: _passwordResetCodeExpiresAt,
      passwordResetCodeAttempts: _passwordResetCodeAttempts,
      passwordResetTokenHash: _passwordResetTokenHash,
      passwordResetTokenExpiresAt: _passwordResetTokenExpiresAt,
      refreshTokenHash: _refreshTokenHash,
      refreshTokenExpiresAt: _refreshTokenExpiresAt,
      pendingPasswordHash: _pendingPasswordHash,
      passwordChangeCodeHash: _passwordChangeCodeHash,
      passwordChangeCodeExpiresAt: _passwordChangeCodeExpiresAt,
      passwordChangeCodeAttempts: _passwordChangeCodeAttempts,
      ...publicUser
    } = object;
    return publicUser;
  }
}
