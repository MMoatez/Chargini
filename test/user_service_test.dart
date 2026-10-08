import 'dart:convert';

import 'package:chargini/DTOs/register_user_dto.dart';
import 'package:chargini/Services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('createUser posts the registration payload', () async {
    late Map<String, dynamic> requestBody;
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'http://api.test/users');
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;

      return http.Response(
        jsonEncode({
          '_id': 'user-id',
          'firstName': requestBody['firstName'],
          'email': requestBody['email'],
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = UserService(client: client, baseUrl: 'http://api.test');

    final user = await service.createUser(
      RegisterUserDto(
        firstName: 'Yassin',
        lastName: 'Jendoubi',
        birthDate: DateTime.utc(2000, 1, 15),
        email: 'YASSIN@EXAMPLE.COM',
        phone: '+21654136555',
        gender: 'male',
        role: 'user',
        password: 'Test1234!',
      ),
    );

    expect(user['_id'], 'user-id');
    expect(requestBody['email'], 'yassin@example.com');
    expect(requestBody['phone'], '+21654136555');
    expect(requestBody['password'], 'Test1234!');
    expect(requestBody['role'], 'user');
  });

  test('createUser exposes the API error message', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'message': 'Un compte existe déjà.'}),
        409,
        headers: {'content-type': 'application/json'},
      ),
    );
    final service = UserService(client: client, baseUrl: 'http://api.test');

    expect(
      () => service.createUser(
        RegisterUserDto(
          firstName: 'Yassin',
          lastName: 'Jendoubi',
          birthDate: DateTime.utc(2000, 1, 15),
          email: 'yassin@example.com',
          phone: '+21654136555',
          gender: 'male',
          role: 'user',
          password: 'Test1234!',
        ),
      ),
      throwsA(
        isA<UserServiceException>().having(
          (error) => error.statusCode,
          'statusCode',
          409,
        ),
      ),
    );
  });
}
