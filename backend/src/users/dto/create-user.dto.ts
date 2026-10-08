import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsPhoneNumber,
  IsString,
  MinLength,
} from 'class-validator';

export enum UserGender {
  Male = 'male',
  Female = 'female',
}

export enum UserRole {
  User = 'user',
  StationOwner = 'station_owner',
}

export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @IsString()
  @IsNotEmpty()
  lastName: string;

  @IsDateString()
  birthDate: string;

  @IsEmail()
  email: string;

  @IsPhoneNumber('TN')
  phone: string;

  @IsEnum(UserGender)
  gender: UserGender;

  @IsEnum(UserRole)
  role: UserRole;

  @IsString()
  @MinLength(8)
  password: string;
}
