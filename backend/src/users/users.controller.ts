import { Body, Controller, Get, Headers, Post } from '@nestjs/common';

import { ConfirmPasswordChangeDto } from './dto/confirm-password-change.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshSessionDto } from './dto/refresh-session.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { RequestPasswordChangeDto } from './dto/request-password-change.dto';
import { VerifyResetCodeDto } from './dto/verify-reset-code.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @Post('forgot-password')
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.usersService.requestPasswordReset(dto.email);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.usersService.login(dto.email, dto.password, dto.rememberMe ?? false);
  }

  @Post('refresh-token')
  refreshToken(@Body() dto: RefreshSessionDto) {
    return this.usersService.refreshSession(dto.refreshToken);
  }

  @Post('logout')
  logout(@Body() dto: RefreshSessionDto) {
    return this.usersService.logout(dto.refreshToken);
  }

  @Post('request-password-change')
  requestPasswordChange(
    @Headers('authorization') authorization: string | undefined,
    @Body() dto: RequestPasswordChangeDto,
  ) {
    return this.usersService.requestPasswordChange(
      authorization,
      dto.currentPassword,
      dto.newPassword,
    );
  }

  @Post('resend-password-change-code')
  resendPasswordChangeCode(
    @Headers('authorization') authorization: string | undefined,
  ) {
    return this.usersService.resendPasswordChangeCode(authorization);
  }

  @Post('confirm-password-change')
  confirmPasswordChange(
    @Headers('authorization') authorization: string | undefined,
    @Body() dto: ConfirmPasswordChangeDto,
  ) {
    return this.usersService.confirmPasswordChange(authorization, dto.code);
  }

  @Post('verify-reset-code')
  verifyResetCode(@Body() dto: VerifyResetCodeDto) {
    return this.usersService.verifyPasswordResetCode(dto.email, dto.code);
  }

  @Post('reset-password')
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.usersService.resetPassword(dto.resetToken, dto.newPassword);
  }
}
