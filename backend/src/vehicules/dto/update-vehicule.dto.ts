import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { VehiculeConnector } from '../vehicule-connector.enum';

export class UpdateVehiculeDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  brand?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  model?: string;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  @Max(1000)
  batteryCapacity?: number;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(1)
  @Max(3000)
  rangeKm?: number;

  @IsOptional()
  @IsEnum(VehiculeConnector, {
    message: 'Le connecteur doit être Mennekes ou CCS Combo.',
  })
  connector?: VehiculeConnector;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  registrationNumber?: string;

  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;
}
