import { ConflictException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import * as bcrypt from 'bcrypt';
import { Model } from 'mongoose';

import { CreateUserDto } from './dto/create-user.dto';
import { User, UserDocument } from './schemas/user.schema';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
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

  private toPublicUser(user: UserDocument) {
    const object = user.toObject();
    const { passwordHash: _passwordHash, ...publicUser } = object;
    return publicUser;
  }
}
