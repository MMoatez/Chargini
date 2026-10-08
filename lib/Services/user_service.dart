import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../DTOs/register_user_dto.dart';

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
}

class UserServiceException implements Exception {
  const UserServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
