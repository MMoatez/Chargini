import 'package:chargini/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
}
