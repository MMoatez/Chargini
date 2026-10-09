import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

import { UserGender, UserRole } from '../dto/create-user.dto';

export type UserDocument = HydratedDocument<User>;

@Schema({ timestamps: true, versionKey: false })
export class User {
  @Prop({ required: true, trim: true })
  firstName: string;

  @Prop({ required: true, trim: true })
  lastName: string;

  @Prop({ required: true })
  birthDate: Date;

  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email: string;

  @Prop({ required: true, trim: true })
  phone: string;

  @Prop({ required: true, enum: UserGender })
  gender: UserGender;

  @Prop({ required: true, enum: UserRole, default: UserRole.User })
  role: UserRole;

  @Prop({ required: true, select: false })
  passwordHash: string;

  @Prop({ select: false })
  passwordResetCodeHash?: string;

  @Prop({ select: false })
  passwordResetCodeExpiresAt?: Date;

  @Prop({ select: false, default: 0 })
  passwordResetCodeAttempts?: number;

  @Prop({ select: false })
  passwordResetTokenHash?: string;

  @Prop({ select: false })
  passwordResetTokenExpiresAt?: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);
