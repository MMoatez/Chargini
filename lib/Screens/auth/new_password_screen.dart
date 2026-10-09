import 'package:flutter/material.dart';

import '../../DTOs/reset_password_dto.dart';
import '../../Services/user_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import 'auth_routes.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _userService = UserService();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _validatePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final resetToken = arguments is Map
        ? arguments['resetToken']?.toString() ?? ''
        : '';
    if (resetToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La demande de réinitialisation est invalide.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _userService.resetPassword(
        ResetPasswordDto(
          resetToken: resetToken,
          newPassword: _passwordController.text,
        ),
      );
      if (!mounted) return;
      await Navigator.pushReplacementNamed(
        context,
        AuthRoutes.passwordResetSuccess,
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
                                  fallbackRoute: AuthRoutes.verificationCode,
                                ),
                              ),
                              Positioned(
                                left: 72,
                                right: 0,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Nouveau mot de passe',
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
                        SizedBox(height: compact ? 12 : 26),
                        SizedBox(
                          height: compact ? 245 : 340,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/images/new_password.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        SizedBox(height: compact ? 14 : 26),
                        const Text(
                          'Saisissez votre nouveau mot de passe\npuis confirmez-le.',
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
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: charginiInputDecoration(
                            hintText: 'Nouveau mot de passe',
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: CharginiColors.bodyText,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value?.length ?? 0) < 8) {
                              return 'Utilisez au moins 8 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmationController,
                          obscureText: _obscureConfirmation,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _validatePassword(),
                          decoration: charginiInputDecoration(
                            hintText: 'Confirmer le mot de passe',
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmation
                                  ? 'Afficher la confirmation'
                                  : 'Masquer la confirmation',
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: CharginiColors.bodyText,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        CharginiPrimaryButton(
                          label: _isSubmitting
                              ? 'Réinitialisation...'
                              : 'Valider et connecter',
                          onPressed: _isSubmitting ? null : _validatePassword,
                          showArrow: !_isSubmitting,
                        ),
                        const SizedBox(height: 28),
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

