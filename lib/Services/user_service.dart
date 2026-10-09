import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../DTOs/register_user_dto.dart';
import '../DTOs/forgot_password_dto.dart';
import '../DTOs/login_dto.dart';
import '../DTOs/reset_password_dto.dart';
import '../DTOs/verify_reset_code_dto.dart';

class UserService {
  UserService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _resolveBaseUrl();

  final http.Client _client;
  final String _baseUrl;

  static String _resolveBaseUrl() {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  Future<Map<String, dynamic>> createUser(RegisterUserDto dto) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/users'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(dto.toJson()),
    );

    final responseBody = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      final rawMessage = responseBody['message'];
      final message = rawMessage is List
          ? rawMessage.join('\n')
          : rawMessage?.toString() ?? 'Impossible de créer le compte.';
      throw UserServiceException(message, statusCode: response.statusCode);
    }

    return responseBody;
  }

  Future<Map<String, dynamic>> requestPasswordReset(
    ForgotPasswordDto dto,
  ) {
    return _post('/users/forgot-password', dto.toJson());
  }

  Future<Map<String, dynamic>> login(LoginDto dto) {
    return _post('/users/login', dto.toJson());
  }

  Future<String> verifyPasswordResetCode(VerifyResetCodeDto dto) async {
    final response = await _post('/users/verify-reset-code', dto.toJson());
    final resetToken = response['resetToken']?.toString();
    if (resetToken == null || resetToken.isEmpty) {
      throw const UserServiceException(
        'Le serveur n’a pas retourné de jeton de réinitialisation.',
      );
    }
    return resetToken;
  }

  Future<void> resetPassword(ResetPasswordDto dto) async {
    await _post('/users/reset-password', dto.toJson());
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final responseBody = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final rawMessage = responseBody['message'];
      final message = rawMessage is List
          ? rawMessage.join('\n')
          : rawMessage?.toString() ?? 'Une erreur est survenue.';
      throw UserServiceException(message, statusCode: response.statusCode);
    }

    return responseBody;
  }
}

class UserServiceException implements Exception {
  const UserServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
