import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Screens/auth/auth_routes.dart';
import 'Screens/auth/login_screen.dart';
import 'Screens/auth/register_screen.dart';
import 'Screens/auth/welcome_screen.dart';
import 'Screens/onboarding/onboarding_screen.dart';

const onboardingCompletedKey = 'onboarding_completed';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      preferences.getBool(onboardingCompletedKey) ?? false;

  runApp(
    CharginiApp(
      preferences: preferences,
      showOnboarding: !hasCompletedOnboarding,
    ),
  );
}

class CharginiApp extends StatelessWidget {
  const CharginiApp({
    super.key,
    required this.preferences,
    required this.showOnboarding,
  });

  final SharedPreferences preferences;
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chargini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BF4F),
          primary: const Color(0xFF00BF4F),
          surface: Colors.white,
        ),
      ),
      routes: {
        AuthRoutes.welcome: (_) => const WelcomeScreen(),
        AuthRoutes.login: (_) => const LoginScreen(),
        AuthRoutes.register: (_) => const RegisterScreen(),
      },
      home: showOnboarding
          ? OnboardingScreen(
              onFinished: () =>
                  preferences.setBool(onboardingCompletedKey, true),
            )
          : const WelcomeScreen(),
    );
  }
}
