import 'package:flutter/material.dart';

import '../../Services/auth_session_service.dart';
import '../../Services/user_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import 'user_routes.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _userService = UserService();
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirmation = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final session = AuthSessionService.current;
    if (session == null) {
      await AuthSessionService.clear();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _userService.requestPasswordChange(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        accessToken: session.accessToken,
      );
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        UserRoutes.verifyPasswordChange,
        arguments: {
          'flow': 'passwordChange',
          'email': session.user.email,
          'debugCode': response['debugCode'],
        },
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
      backgroundColor: const Color(0xFFFBFDFE),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                children: [
                  const _ChangePasswordHeader(),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7FF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        _InfoIcon(),
                        SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            'Pour sécuriser votre compte, choisissez un mot de passe fort.',
                            style: TextStyle(
                              color: CharginiColors.navy,
                              fontSize: 17,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: CharginiColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PasswordLabel('Mot de passe actuel'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _hideCurrent,
                          textInputAction: TextInputAction.next,
                          decoration: _passwordDecoration(
                            'Entrez votre mot de passe actuel',
                            _hideCurrent,
                            () => setState(() => _hideCurrent = !_hideCurrent),
                          ),
                          validator: (value) => (value?.isEmpty ?? true)
                              ? 'Saisissez votre mot de passe actuel'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        const _PasswordLabel('Nouveau mot de passe'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _hideNew,
                          textInputAction: TextInputAction.next,
                          decoration: _passwordDecoration(
                            'Entrez un nouveau mot de passe',
                            _hideNew,
                            () => setState(() => _hideNew = !_hideNew),
                          ),
                          validator: (value) => (value?.length ?? 0) < 8
                              ? 'Utilisez au moins 8 caractères'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F9FB),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: CharginiColors.navy,
                                size: 30,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Votre mot de passe doit contenir :',
                                      style: TextStyle(
                                        color: CharginiColors.navy,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: CharginiColors.green,
                                          size: 9,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Au moins 8 caractères',
                                          style: TextStyle(
                                            color: CharginiColors.bodyText,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _PasswordLabel(
                          'Confirmer le nouveau mot de passe',
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _confirmationController,
                          obscureText: _hideConfirmation,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          decoration: _passwordDecoration(
                            'Confirmez votre nouveau mot de passe',
                            _hideConfirmation,
                            () => setState(
                              () => _hideConfirmation = !_hideConfirmation,
                            ),
                          ),
                          validator: (value) =>
                              value != _newPasswordController.text
                              ? 'Les mots de passe ne correspondent pas'
                              : null,
                        ),
                        const SizedBox(height: 28),
                        CharginiPrimaryButton(
                          label: _isSubmitting
                              ? 'Envoi du code...'
                              : 'Enregistrer',
                          onPressed: _isSubmitting ? null : _save,
                          showArrow: false,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF0F4F7),
                              foregroundColor: CharginiColors.navy,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordHeader extends StatelessWidget {
  const _ChangePasswordHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Positioned(
            left: 0,
            child: CharginiBackButton(fallbackRoute: UserRoutes.profile),
          ),
          Positioned(
            left: 72,
            right: 0,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Changer le mot de passe',
                style: TextStyle(
                  color: CharginiColors.navy,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFD7EEFF),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Icon(
        Icons.lock_outline_rounded,
        color: CharginiColors.navy,
        size: 33,
      ),
    );
  }
}

class _PasswordLabel extends StatelessWidget {
  const _PasswordLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: CharginiColors.navy,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

InputDecoration _passwordDecoration(
  String hint,
  bool hidden,
  VoidCallback toggle,
) {
  return charginiInputDecoration(
    hintText: hint,
    prefixIcon: Icons.lock_outline_rounded,
    suffixIcon: IconButton(
      onPressed: toggle,
      icon: Icon(
        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: CharginiColors.navy,
      ),
    ),
  );
}
