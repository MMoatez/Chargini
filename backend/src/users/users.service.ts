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

  async login(rawEmail: string, password: string) {
    const email = rawEmail.trim().toLowerCase();
    const user = await this.userModel
      .findOne({ email })
      .select('+passwordHash')
      .exec();

    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      throw new UnauthorizedException('Adresse e-mail ou mot de passe incorrect.');
    }

    const accessToken = await this.jwtService.signAsync({
      sub: user.id,
      email: user.email,
      role: user.role,
    });

    return { accessToken, user: this.toPublicUser(user) };
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
    await user.save();

    return { message: 'Votre mot de passe a été réinitialisé avec succès.' };
  }

  private hashResetSecret(value: string) {
    const secret =
      this.configService.get<string>('PASSWORD_RESET_SECRET') ??
      'chargini-development-reset-secret-change-me';
    return createHmac('sha256', secret).update(value).digest('hex');
  }

  private secretsMatch(storedHash: string, value: string) {
    const candidate = Buffer.from(this.hashResetSecret(value), 'hex');
    const stored = Buffer.from(storedHash, 'hex');
    return candidate.length === stored.length && timingSafeEqual(candidate, stored);
  }

  private toPublicUser(user: UserDocument) {
    const object = user.toObject();
    const { passwordHash: _passwordHash, ...publicUser } = object;
    return publicUser;
  }
}
