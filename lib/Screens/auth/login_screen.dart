import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../DTOs/login_dto.dart';
import '../../Services/user_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import 'auth_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await _userService.login(
        LoginDto(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
      final token = response['accessToken']?.toString();
      if (token == null || token.isEmpty) {
        throw const UserServiceException('Jeton de connexion manquant.');
      }

      final preferences = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await preferences.setString('auth_access_token', token);
      } else {
        await preferences.remove('auth_access_token');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion réussie.'),
          backgroundColor: CharginiColors.green,
        ),
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
            final compact = constraints.maxHeight < 900;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: compact ? 82 : 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: const [
                              Positioned(
                                left: 0,
                                top: 5,
                                child: CharginiBackButton(),
                              ),
                              CharginiLogo(width: 142, height: 96),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/images/3.png',
                          width: double.infinity,
                          height: compact ? 175 : 225,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        SizedBox(height: compact ? 6 : 14),
                        Text(
                          'Se connecter',
                          style: TextStyle(
                            color: CharginiColors.navy,
                            fontSize: compact ? 32 : 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Accédez à votre compte pour continuer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CharginiColors.bodyText,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: compact ? 18 : 26),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: charginiInputDecoration(
                            hintText: 'Adresse e-mail',
                            prefixIcon: Icons.mail_outline_rounded,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return 'Saisissez une adresse e-mail valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: charginiInputDecoration(
                            hintText: 'Mot de passe',
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
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
                          validator: (value) => (value?.isEmpty ?? true)
                              ? 'Saisissez votre mot de passe'
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AuthRoutes.forgotPassword,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: CharginiColors.green,
                            ),
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        CheckboxListTile(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: CharginiColors.green,
                          title: const Text(
                            'Se souvenir de moi',
                            style: TextStyle(
                              color: CharginiColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        CharginiPrimaryButton(
                          label: _isSubmitting
                              ? 'Connexion en cours...'
                              : 'Se connecter',
                          onPressed: _isSubmitting ? null : _submit,
                          showArrow: !_isSubmitting,
                        ),
                        const SizedBox(height: 24),
                        AuthFooterLink(
                          prefix: 'Vous n’avez pas de compte ? ',
                          action: 'Créer un compte',
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            AuthRoutes.register,
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
