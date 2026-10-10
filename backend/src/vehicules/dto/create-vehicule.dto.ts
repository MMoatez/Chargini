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

export class CreateVehiculeDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  brand: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  model: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  @Max(1000)
  batteryCapacity: number;

  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(1)
  @Max(3000)
  rangeKm: number;

  @IsEnum(VehiculeConnector, {
    message: 'Le connecteur doit être Mennekes ou CCS Combo.',
  })
  connector: VehiculeConnector;

  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  registrationNumber: string;

  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;
}
