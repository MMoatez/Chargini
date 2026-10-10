import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../DTOs/vehicule_dto.dart';

class VehiculeService {
  VehiculeService({http.Client? client, String? baseUrl})
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

  Future<List<VehiculeDto>> getVehicules(String accessToken) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/vehicules'),
      headers: _headers(accessToken),
    );
    final body = _decode(response);
    if (body is! List) {
      throw const VehiculeServiceException('Réponse des véhicules invalide.');
    }
    return body
        .map((item) => VehiculeDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<VehiculeDto> createVehicule(
    String accessToken,
    VehiculeDto vehicule,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/vehicules'),
      headers: _headers(accessToken),
      body: jsonEncode(vehicule.toRequestJson()),
    );
    return VehiculeDto.fromJson(_asMap(_decode(response)));
  }

  Future<VehiculeDto> updateVehicule(
    String accessToken,
    VehiculeDto vehicule,
  ) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/vehicules/${vehicule.id}'),
      headers: _headers(accessToken),
      body: jsonEncode(vehicule.toRequestJson()),
    );
    return VehiculeDto.fromJson(_asMap(_decode(response)));
  }

  Future<void> deleteVehicule(String accessToken, String vehiculeId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/vehicules/$vehiculeId'),
      headers: _headers(accessToken),
    );
    _decode(response);
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  dynamic _decode(http.Response response) {
    final dynamic body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final raw = body is Map<String, dynamic> ? body['message'] : null;
      final message = raw is List
          ? raw.join('\n')
          : raw?.toString() ?? 'Connexion au serveur impossible.';
      throw VehiculeServiceException(message, statusCode: response.statusCode);
    }
    return body;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const VehiculeServiceException('Réponse du serveur invalide.');
  }
}

class VehiculeServiceException implements Exception {
  const VehiculeServiceException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
