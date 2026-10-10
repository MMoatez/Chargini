import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Services/auth_session_service.dart';
import 'Services/auth_session_lifecycle.dart';
import 'Screens/auth/auth_routes.dart';
import 'Screens/auth/forgot_password_screen.dart';
import 'Screens/auth/login_screen.dart';
import 'Screens/auth/new_password_screen.dart';
import 'Screens/auth/password_reset_success_screen.dart';
import 'Screens/auth/register_screen.dart';
import 'Screens/auth/verification_code_screen.dart';
import 'Screens/auth/welcome_screen.dart';
import 'Screens/onboarding/onboarding_screen.dart';
import 'Screens/user/profile_screen.dart';
import 'Screens/user/edit_profile_screen.dart';
import 'Screens/user/change_password_screen.dart';
import 'Screens/user/delete_account_screen.dart';
import 'Screens/user/user_routes.dart';
import 'Screens/véhicules/vehicule_routes.dart';
import 'Screens/véhicules/vehicules_screen.dart';

const onboardingCompletedKey = 'onboarding_completed';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      preferences.getBool(onboardingCompletedKey) ?? false;
  final rememberedSession = await AuthSessionService.restore();

  runApp(
    CharginiApp(
      preferences: preferences,
      showOnboarding: !hasCompletedOnboarding,
      rememberedSession: rememberedSession,
    ),
  );
}

class CharginiApp extends StatelessWidget {
  const CharginiApp({
    super.key,
    required this.preferences,
    required this.showOnboarding,
    this.rememberedSession,
  });

  final SharedPreferences preferences;
  final bool showOnboarding;
  final AuthSession? rememberedSession;
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) => AuthSessionLifecycle(
        navigatorKey: navigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
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
        AuthRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AuthRoutes.verificationCode: (_) => const VerificationCodeScreen(),
        AuthRoutes.newPassword: (_) => const NewPasswordScreen(),
        AuthRoutes.passwordResetSuccess: (_) =>
            const PasswordResetSuccessScreen(),
        UserRoutes.profile: (_) => const ProfileScreen(),
        UserRoutes.editProfile: (_) => const EditProfileScreen(),
        UserRoutes.changePassword: (_) => const ChangePasswordScreen(),
        UserRoutes.verifyPasswordChange: (_) => const VerificationCodeScreen(),
        UserRoutes.deleteAccount: (_) => const DeleteAccountScreen(),
        VehiculeRoutes.list: (_) => const VehiculesScreen(),
      },
      home: showOnboarding
          ? OnboardingScreen(
              onFinished: () =>
                  preferences.setBool(onboardingCompletedKey, true),
            )
          : rememberedSession != null
          ? ProfileScreen(initialSession: rememberedSession)
          : const WelcomeScreen(),
    );
  }
}
