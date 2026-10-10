import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DTOs/user_profile_dto.dart';

const authAccessTokenKey = 'auth_access_token';
const authRefreshTokenKey = 'auth_refresh_token';
const authUserProfileKey = 'auth_user_profile';
const authAccessExpiresAtKey = 'auth_access_expires_at';
const authRefreshExpiresAtKey = 'auth_refresh_expires_at';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
    required this.rememberMe,
  });

  factory AuthSession.fromResponse(
    Map<String, dynamic> response, {
    required UserProfileDto user,
    required bool rememberMe,
  }) {
    final accessToken = response['accessToken']?.toString() ?? '';
    final refreshToken = response['refreshToken']?.toString() ?? '';
    final accessTokenExpiresAt = DateTime.tryParse(
      response['accessTokenExpiresAt']?.toString() ?? '',
    );
    final refreshTokenExpiresAt = DateTime.tryParse(
      response['refreshTokenExpiresAt']?.toString() ?? '',
    );

    if (accessToken.isEmpty ||
        refreshToken.isEmpty ||
        accessTokenExpiresAt == null ||
        refreshTokenExpiresAt == null) {
      throw const FormatException('Session de connexion incomplète.');
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      accessTokenExpiresAt: accessTokenExpiresAt,
      refreshTokenExpiresAt: refreshTokenExpiresAt,
      rememberMe: rememberMe,
    );
  }

  final String accessToken;
  final String refreshToken;
  final UserProfileDto user;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;
  final bool rememberMe;

  AuthSession refreshed(Map<String, dynamic> response) {
    return AuthSession.fromResponse(
      response,
      user: user,
      rememberMe: rememberMe,
    );
  }
}

class AuthSessionService {
  static const inactivityDuration = Duration(minutes: 30);
  static final ValueNotifier<AuthSession?> session = ValueNotifier(null);

  static AuthSession? get current => session.value;

  static Future<void> activate(AuthSession value) async {
    session.value = value;
    if (value.rememberMe) {
      await _persist(value);
    } else {
      await _clearStoredSession();
    }
  }

  static Future<AuthSession?> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final accessToken = preferences.getString(authAccessTokenKey);
    final refreshToken = preferences.getString(authRefreshTokenKey);
    final profileJson = preferences.getString(authUserProfileKey);
    final accessExpiresAtMs = preferences.getInt(authAccessExpiresAtKey);
    final refreshExpiresAtMs = preferences.getInt(authRefreshExpiresAtKey);

    if (accessToken == null ||
        refreshToken == null ||
        profileJson == null ||
        accessExpiresAtMs == null ||
        refreshExpiresAtMs == null) {
      await _clearStoredSession();
      return null;
    }

    final refreshTokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(
      refreshExpiresAtMs,
    );
    if (!refreshTokenExpiresAt.isAfter(DateTime.now())) {
      await clear();
      return null;
    }

    try {
      final decoded = jsonDecode(profileJson) as Map<String, dynamic>;
      final restored = AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: UserProfileDto.fromJson(decoded),
        accessTokenExpiresAt: DateTime.fromMillisecondsSinceEpoch(
          accessExpiresAtMs,
        ),
        refreshTokenExpiresAt: refreshTokenExpiresAt,
        rememberMe: true,
      );
      session.value = restored;
      return restored;
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    session.value = null;
    await _clearStoredSession();
  }

  static Future<void> _persist(AuthSession value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(authAccessTokenKey, value.accessToken);
    await preferences.setString(authRefreshTokenKey, value.refreshToken);
    await preferences.setString(
      authUserProfileKey,
      jsonEncode(value.user.toJson()),
    );
    await preferences.setInt(
      authAccessExpiresAtKey,
      value.accessTokenExpiresAt.millisecondsSinceEpoch,
    );
    await preferences.setInt(
      authRefreshExpiresAtKey,
      value.refreshTokenExpiresAt.millisecondsSinceEpoch,
    );
  }

  static Future<void> _clearStoredSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(authAccessTokenKey);
    await preferences.remove(authRefreshTokenKey);
    await preferences.remove(authUserProfileKey);
    await preferences.remove(authAccessExpiresAtKey);
    await preferences.remove(authRefreshExpiresAtKey);
    await preferences.remove('auth_expires_at');
  }
}
