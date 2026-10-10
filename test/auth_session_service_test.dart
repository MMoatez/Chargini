import 'package:chargini/DTOs/user_profile_dto.dart';
import 'package:chargini/Services/auth_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _user = UserProfileDto(
  id: 'user-1',
  firstName: 'Yassine',
  lastName: 'Jendoubi',
  email: 'yassine@example.com',
  phone: '+21654136655',
  birthDate: null,
  role: 'user',
);
final _refreshToken = List.filled(96, 'r').join();

AuthSession _rememberedSession({DateTime? refreshTokenExpiresAt}) {
  return AuthSession(
    accessToken: 'jwt-token',
    refreshToken: _refreshToken,
    user: _user,
    accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
    refreshTokenExpiresAt:
        refreshTokenExpiresAt ?? DateTime.now().add(const Duration(days: 30)),
    rememberMe: true,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthSessionService.session.value = null;
  });

  test('remember stores a session that can be restored', () async {
    final created = _rememberedSession();
    await AuthSessionService.activate(created);

    final restored = await AuthSessionService.restore();

    expect(restored?.accessToken, 'jwt-token');
    expect(restored?.user.email, _user.email);
    expect(
      restored?.refreshTokenExpiresAt.millisecondsSinceEpoch,
      created.refreshTokenExpiresAt.millisecondsSinceEpoch,
    );
  });

  test('restore removes an expired session', () async {
    SharedPreferences.setMockInitialValues({
      authAccessTokenKey: 'expired-token',
      authRefreshTokenKey: _refreshToken,
      authUserProfileKey:
          '{"_id":"user-1","firstName":"Yassine","lastName":"Jendoubi",'
          '"email":"yassine@example.com","phone":"+21654136655",'
          '"birthDate":null,"role":"user","vehiculeCount":0}',
      authAccessExpiresAtKey: DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
      authRefreshExpiresAtKey: DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    });

    expect(await AuthSessionService.restore(), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(authAccessTokenKey), isNull);
    expect(preferences.getString(authUserProfileKey), isNull);
    expect(preferences.getString(authRefreshTokenKey), isNull);
    expect(preferences.getInt(authAccessExpiresAtKey), isNull);
    expect(preferences.getInt(authRefreshExpiresAtKey), isNull);
  });

  test('clear forgets a remembered session immediately', () async {
    await AuthSessionService.activate(_rememberedSession());

    await AuthSessionService.clear();

    expect(await AuthSessionService.restore(), isNull);
  });
}
