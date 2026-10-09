import 'package:flutter/material.dart';

import '../../UI_Components/chargini_auth_components.dart';
import 'auth_routes.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AuthRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 62,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Positioned(
                              left: 0,
                              child: CharginiBackButton(
                                fallbackRoute: AuthRoutes.login,
                              ),
                            ),
                            const Positioned(
                              left: 72,
                              right: 0,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Mot de passe réinitialisé',
                                  style: TextStyle(
                                    color: CharginiColors.navy,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 20 : 52),
                      SizedBox(
                        height: compact ? 290 : 410,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/password_reset_success.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      SizedBox(height: compact ? 24 : 48),
                      const Text(
                        'Votre mot de passe a été\nréinitialisé avec succès.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CharginiColors.bodyText,
                          fontSize: 23,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: compact ? 32 : 54),
                      CharginiPrimaryButton(
                        label: 'Valider et connecter',
                        onPressed: () => _openLogin(context),
                      ),
                      const SizedBox(height: 36),
                      AuthFooterLink(
                        prefix: 'Retour à la ',
                        action: 'connexion',
                        onTap: () => _openLogin(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

