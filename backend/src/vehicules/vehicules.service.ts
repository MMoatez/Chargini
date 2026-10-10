import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { isValidObjectId, Model } from 'mongoose';

import { MailService } from '../users/mail.service';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CreateVehiculeDto } from './dto/create-vehicule.dto';
import { UpdateVehiculeDto } from './dto/update-vehicule.dto';
import { Vehicule, VehiculeDocument } from './schemas/vehicule.schema';
import { VehiculeConnector } from './vehicule-connector.enum';

@Injectable()
export class VehiculesService implements OnModuleInit {
  constructor(
    @InjectModel(Vehicule.name)
    private readonly vehiculeModel: Model<Vehicule>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly jwtService: JwtService,
    private readonly mailService: MailService,
  ) {}

  async onModuleInit() {
    await this.vehiculeModel.updateMany(
      { connector: { $in: ['Type 2', 'type 2', 'TYPE 2'] } },
      { $set: { connector: VehiculeConnector.Mennekes } },
    );
  }

  async findAll(authorization?: string) {
    const userId = await this.userIdFromAuthorization(authorization);
    return this.vehiculeModel
      .find({ userId })
      .sort({ isPrimary: -1, createdAt: 1 })
      .lean()
      .exec();
  }

  async findOne(authorization: string | undefined, id: string) {
    const userId = await this.userIdFromAuthorization(authorization);
    this.assertValidId(id);
    const vehicule = await this.vehiculeModel.findOne({ _id: id, userId }).lean();
    if (!vehicule) throw new NotFoundException('Véhicule introuvable.');
    return vehicule;
  }

  async create(authorization: string | undefined, dto: CreateVehiculeDto) {
    const userId = await this.userIdFromAuthorization(authorization);
    const existingCount = await this.vehiculeModel.countDocuments({ userId });
    const registrationNumber = this.normalizeRegistration(
      dto.registrationNumber,
    );

    if (await this.vehiculeModel.exists({ userId, registrationNumber })) {
      throw new ConflictException(
        'Un véhicule avec cette immatriculation existe déjà.',
      );
    }

    const isPrimary = existingCount === 0 || dto.isPrimary === true;
    if (isPrimary) {
      await this.vehiculeModel.updateMany(
        { userId, isPrimary: true },
        { $set: { isPrimary: false } },
      );
    }

    const vehicule = await this.vehiculeModel.create({
      userId,
      brand: dto.brand.trim(),
      model: dto.model.trim(),
      batteryCapacity: dto.batteryCapacity,
      rangeKm: dto.rangeKm,
      connector: dto.connector,
      registrationNumber,
      isPrimary,
    });
    const user = await this.userModel.findByIdAndUpdate(
      userId,
      { $inc: { vehiculeCount: 1 } },
      { returnDocument: 'after' },
    );

    if (user) {
      try {
        await this.mailService.sendVehiculeAddedNotification(
          user.email,
          user.firstName,
          this.toMailDetails(vehicule),
        );
      } catch (error) {
        console.warn('Vehicule added, but its notification email failed.', error);
      }
    }
    return vehicule.toObject();
  }

  async update(
    authorization: string | undefined,
    id: string,
    dto: UpdateVehiculeDto,
  ) {
    const userId = await this.userIdFromAuthorization(authorization);
    this.assertValidId(id);
    if (Object.keys(dto).length === 0) {
      throw new BadRequestException('Aucune modification fournie.');
    }
    const vehicule = await this.vehiculeModel.findOne({ _id: id, userId });
    if (!vehicule) throw new NotFoundException('Véhicule introuvable.');

    if (dto.registrationNumber != null) {
      const normalized = this.normalizeRegistration(dto.registrationNumber);
      const duplicate = await this.vehiculeModel.exists({
        userId,
        registrationNumber: normalized,
        _id: { $ne: id },
      });
      if (duplicate) {
        throw new ConflictException(
          'Un véhicule avec cette immatriculation existe déjà.',
        );
      }
      vehicule.registrationNumber = normalized;
    }

    if (dto.brand != null) vehicule.brand = dto.brand.trim();
    if (dto.model != null) vehicule.set('model', dto.model.trim());
    if (dto.batteryCapacity != null) {
      vehicule.batteryCapacity = dto.batteryCapacity;
    }
    if (dto.rangeKm != null) vehicule.rangeKm = dto.rangeKm;
    if (dto.connector != null) vehicule.connector = dto.connector;

    if (dto.isPrimary === true) {
      await this.vehiculeModel.updateMany(
        { userId, _id: { $ne: id }, isPrimary: true },
        { $set: { isPrimary: false } },
      );
      vehicule.isPrimary = true;
    } else if (dto.isPrimary === false && vehicule.isPrimary) {
      const replacement = await this.vehiculeModel
        .findOne({ userId, _id: { $ne: id } })
        .sort({ createdAt: 1 });
      if (replacement) {
        replacement.isPrimary = true;
        await replacement.save();
        vehicule.isPrimary = false;
      }
    }

    await vehicule.save();
    return vehicule.toObject();
  }

  async remove(authorization: string | undefined, id: string) {
    const userId = await this.userIdFromAuthorization(authorization);
    this.assertValidId(id);
    const vehicule = await this.vehiculeModel.findOneAndDelete({ _id: id, userId });
    if (!vehicule) throw new NotFoundException('Véhicule introuvable.');

    if (vehicule.isPrimary) {
      const replacement = await this.vehiculeModel
        .findOne({ userId })
        .sort({ createdAt: 1 });
      if (replacement) {
        replacement.isPrimary = true;
        await replacement.save();
      }
    }

    const user = await this.userModel.findByIdAndUpdate(
      userId,
      { $inc: { vehiculeCount: -1 } },
      { returnDocument: 'after' },
    );
    if (user && user.vehiculeCount < 0) {
      user.vehiculeCount = 0;
      await user.save();
    }
    if (user) {
      try {
        await this.mailService.sendVehiculeRemovedNotification(
          user.email,
          user.firstName,
          this.toMailDetails(vehicule),
        );
      } catch (error) {
        console.warn('Vehicule removed, but its notification email failed.', error);
      }
    }
    return { message: 'Le véhicule a été supprimé avec succès.' };
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

  private assertValidId(id: string) {
    if (!isValidObjectId(id)) {
      throw new NotFoundException('Véhicule introuvable.');
    }
  }

  private normalizeRegistration(value: string) {
    return value.trim().replace(/\s+/g, ' ').toUpperCase();
  }

  private toMailDetails(vehicule: VehiculeDocument) {
    return {
      brand: vehicule.brand,
      model: String(vehicule.get('model')),
      batteryCapacity: vehicule.batteryCapacity,
      rangeKm: vehicule.rangeKm,
      connector: vehicule.connector,
      registrationNumber: vehicule.registrationNumber,
      isPrimary: vehicule.isPrimary,
    };
  }
}
