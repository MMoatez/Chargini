import { IsString, MinLength } from 'class-validator';

export class RequestPasswordChangeDto {
  @IsString()
  @MinLength(8)
  currentPassword: string;

  @IsString()
  @MinLength(8, {
    message: 'Le nouveau mot de passe doit contenir au moins 8 caractères.',
  })
  newPassword: string;
}
