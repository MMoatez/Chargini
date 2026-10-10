import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Schema as MongooseSchema, Types } from 'mongoose';
import { VehiculeConnector } from '../vehicule-connector.enum';

export type VehiculeDocument = HydratedDocument<Vehicule>;

@Schema({ timestamps: true, versionKey: false })
export class Vehicule {
  @Prop({
    required: true,
    type: MongooseSchema.Types.ObjectId,
    ref: 'User',
    index: true,
  })
  userId: Types.ObjectId;

  @Prop({ required: true, trim: true })
  brand: string;

  @Prop({ required: true, trim: true })
  model: string;

  @Prop({ required: true, min: 1 })
  batteryCapacity: number;

  @Prop({ required: true, min: 1 })
  rangeKm: number;

  @Prop({ required: true, enum: Object.values(VehiculeConnector) })
  connector: VehiculeConnector;

  @Prop({ required: true, trim: true, uppercase: true })
  registrationNumber: string;

  @Prop({ required: true, default: false })
  isPrimary: boolean;

  createdAt?: Date;
  updatedAt?: Date;
}

export const VehiculeSchema = SchemaFactory.createForClass(Vehicule);
VehiculeSchema.index({ userId: 1, registrationNumber: 1 }, { unique: true });
