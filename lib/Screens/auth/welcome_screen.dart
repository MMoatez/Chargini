import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../UI_Components/chargini_auth_components.dart';
import 'auth_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 900;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 26,
                ),
                child: Column(
                  children: [
                    CharginiLogo(
                      width: compact ? 125 : 150,
                      height: compact ? 82 : 105,
                    ),
                    SizedBox(height: compact ? 4 : 12),
                    Image.asset(
                      'assets/images/3.png',
                      width: double.infinity,
                      height: compact ? 210 : 285,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    SizedBox(height: compact ? 8 : 16),
                    Text.rich(
                      const TextSpan(
                        text: 'Bienvenue sur\n',
                        children: [
                          TextSpan(
                            text: 'Chargini',
                            style: TextStyle(color: CharginiColors.green),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CharginiColors.navy,
                        fontSize: compact ? 32 : 38,
                        height: 1.06,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    const Text(
                      'Connectez-vous pour réserver une borne, suivre vos '
                      'recharges et gérer votre compte facilement.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CharginiColors.bodyText,
                        fontSize: 16,
                        height: 1.42,
                      ),
                    ),
                    SizedBox(height: compact ? 18 : 26),
                    CharginiPrimaryButton(
                      label: 'Se connecter',
                      onPressed: () =>
                          Navigator.pushNamed(context, AuthRoutes.login),
                    ),
                    const SizedBox(height: 12),
                    CharginiOutlinedButton(
                      label: 'Créer un compte',
                      onPressed: () =>
                          Navigator.pushNamed(context, AuthRoutes.register),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showComingSoon(
                        context,
                        'La récupération du mot de passe sera connectée au backend.',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: CharginiColors.green,
                      ),
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const AuthDivider(),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        text: 'En continuant, vous acceptez nos ',
                        style: const TextStyle(
                          color: CharginiColors.bodyText,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: 'conditions d’utilisation.',
                            style: const TextStyle(
                              color: CharginiColors.green,
                              decoration: TextDecoration.underline,
                              decorationColor: CharginiColors.green,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showComingSoon(
                                context,
                                'Les conditions d’utilisation seront ajoutées prochainement.',
                              ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
