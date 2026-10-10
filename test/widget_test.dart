import 'package:chargini/main.dart';
import 'package:chargini/DTOs/user_profile_dto.dart';
import 'package:chargini/Services/auth_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => AuthSessionService.session.value = null);

  testWidgets('shows onboarding on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      CharginiApp(preferences: preferences, showOnboarding: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trouvez les bornes\nprès de vous'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
  });

  testWidgets('advances through all onboarding pages', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      CharginiApp(preferences: preferences, showOnboarding: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Réservez votre borne\nà l’avance'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Suivez votre recharge\nen temps réel'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur\nChargini'), findsOneWidget);
    expect(preferences.getBool(onboardingCompletedKey), isTrue);
  });

  testWidgets('skips onboarding when already completed', (tester) async {
    SharedPreferences.setMockInitialValues({onboardingCompletedKey: true});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      CharginiApp(preferences: preferences, showOnboarding: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur\nChargini'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('opens login from the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({onboardingCompletedKey: true});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      CharginiApp(preferences: preferences, showOnboarding: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se connecter').first);
    await tester.pumpAndSettle();

    expect(find.text('Accédez à votre compte pour continuer.'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
  });

  testWidgets('opens registration from the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({onboardingCompletedKey: true});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      CharginiApp(preferences: preferences, showOnboarding: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(
      find.text('Renseignez vos informations pour rejoindre Chargini.'),
      findsOneWidget,
    );
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
  });

  testWidgets('opens forgot password from the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({onboardingCompletedKey: true});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      CharginiApp(preferences: preferences, showOnboarding: false),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Entrez votre adresse e-mail pour\nrecevoir un code de vérification.',
      ),
      findsOneWidget,
    );
    expect(find.text('Envoyer le code'), findsOneWidget);
  });

  testWidgets('remembered user opens the profile and can log out', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({onboardingCompletedKey: true});
    final preferences = await SharedPreferences.getInstance();
    final session = AuthSession(
      accessToken: 'jwt-token',
      refreshToken: List.filled(96, 'r').join(),
      user: const UserProfileDto(
        id: 'user-1',
        firstName: 'Yassine',
        lastName: 'Jendoubi',
        email: 'yassine@example.com',
        phone: '+21654136655',
        birthDate: null,
        role: 'user',
      ),
      accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
      refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
      rememberMe: true,
    );
    await AuthSessionService.activate(session);

    await tester.pumpWidget(
      CharginiApp(
        preferences: preferences,
        showOnboarding: false,
        rememberedSession: session,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mon compte'), findsOneWidget);
    expect(find.text('Yassine Jendoubi'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Se déconnecter'),
      450,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsWidgets);
    expect(preferences.getString(authAccessTokenKey), isNull);
  });
}
