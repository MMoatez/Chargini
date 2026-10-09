import 'package:flutter/material.dart';

import '../../DTOs/forgot_password_dto.dart';
import '../../Services/user_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import 'auth_routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _userService = UserService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final response = await _userService.requestPasswordReset(
        ForgotPasswordDto(email: email),
      );
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AuthRoutes.verificationCode,
        arguments: {'email': email, 'debugCode': response['debugCode']},
      );
    } on UserServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion au serveur impossible.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 62,
                          child: Stack(
                            alignment: Alignment.center,
                            children: const [
                              Positioned(
                                left: 0,
                                child: CharginiBackButton(
                                  fallbackRoute: AuthRoutes.login,
                                ),
                              ),
                              Positioned(
                                left: 72,
                                right: 0,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Mot de passe oublié ?',
                                    textAlign: TextAlign.center,
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
                        SizedBox(height: compact ? 12 : 28),
                        Image.asset(
                          'assets/images/7.png',
                          width: double.infinity,
                          height: compact ? 280 : 390,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        SizedBox(height: compact ? 12 : 24),
                        const Text(
                          'Entrez votre adresse e-mail pour\nrecevoir un code de vérification.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CharginiColors.bodyText,
                            fontSize: 20,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: compact ? 22 : 38),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) => _sendCode(),
                          decoration: charginiInputDecoration(
                            hintText: 'Adresse e-mail',
                            prefixIcon: Icons.mail_outline_rounded,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            final validEmail = RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(email);
                            if (!validEmail) {
                              return 'Saisissez une adresse e-mail valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        CharginiPrimaryButton(
                          label: _isSubmitting
                              ? 'Envoi en cours...'
                              : 'Envoyer le code',
                          onPressed: _isSubmitting ? null : _sendCode,
                          showArrow: !_isSubmitting,
                        ),
                        const SizedBox(height: 30),
                        AuthFooterLink(
                          prefix: 'Retour à la ',
                          action: 'connexion',
                          onTap: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            AuthRoutes.login,
                            (route) => false,
                          ),
                        ),
                      ],
                    ),
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
