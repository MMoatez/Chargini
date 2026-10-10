import 'dart:convert';

import 'package:chargini/DTOs/vehicule_dto.dart';
import 'package:chargini/Services/vehicule_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const jsonVehicule = {
    '_id': 'vehicule-1',
    'brand': 'Tesla',
    'model': 'Model 3',
    'batteryCapacity': 60,
    'rangeKm': 430,
    'connector': 'Mennekes',
    'registrationNumber': 'TU-2456',
    'isPrimary': true,
  };

  test('getVehicules reads the authenticated vehicule list', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://api.test/vehicules');
      expect(request.headers['Authorization'], 'Bearer access-token');
      return http.Response(jsonEncode([jsonVehicule]), 200);
    });
    final service = VehiculeService(client: client, baseUrl: 'http://api.test');

    final vehicules = await service.getVehicules('access-token');

    expect(vehicules, hasLength(1));
    expect(vehicules.single.displayName, 'Tesla Model 3');
    expect(vehicules.single.isPrimary, isTrue);
  });

  test('legacy Type 2 connector is read as Mennekes', () {
    final legacy = Map<String, dynamic>.from(jsonVehicule)
      ..['connector'] = 'Type 2';

    expect(VehiculeDto.fromJson(legacy).connector, 'Mennekes');
  });

  test('createVehicule sends every vehicule detail', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['registrationNumber'], 'TU-2456');
      expect(body['batteryCapacity'], 60.0);
      return http.Response(jsonEncode(jsonVehicule), 201);
    });
    final service = VehiculeService(client: client, baseUrl: 'http://api.test');
    final draft = VehiculeDto.fromJson(jsonVehicule);

    final created = await service.createVehicule('access-token', draft);

    expect(created.id, 'vehicule-1');
  });

  test('API errors are exposed in French to the interface', () async {
    final client = MockClient(
      (_) async =>
          http.Response(jsonEncode({'message': 'Véhicule introuvable.'}), 404),
    );
    final service = VehiculeService(client: client, baseUrl: 'http://api.test');

    expect(
      () => service.deleteVehicule('access-token', 'missing'),
      throwsA(
        isA<VehiculeServiceException>().having(
          (error) => error.message,
          'message',
          'Véhicule introuvable.',
        ),
      ),
    );
  });
}
