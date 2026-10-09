import { IsEmail, Matches } from 'class-validator';

export class VerifyResetCodeDto {
  @IsEmail()
  email: string;

  @Matches(/^\d{6}$/, { message: 'Le code doit contenir exactement 6 chiffres.' })
  code: string;
}
