import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../DTOs/forgot_password_dto.dart';
import '../../DTOs/user_profile_dto.dart';
import '../../DTOs/verify_reset_code_dto.dart';
import '../../Services/auth_session_service.dart';
import '../../Services/user_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import '../user/user_routes.dart';
import 'auth_routes.dart';

class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  final _userService = UserService();
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_refreshCodeBoxes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController
      ..removeListener(_refreshCodeBoxes)
      ..dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _refreshCodeBoxes() {
    if (!mounted) return;
    setState(() => _errorMessage = null);
  }

  Future<void> _continue() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorMessage = 'Saisissez le code à 6 chiffres');
      _codeFocusNode.requestFocus();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isPasswordChangeFlow(context)) {
        await _confirmPasswordChange();
        return;
      }

      final email = _emailFromArguments(context);
      final resetToken = await _userService.verifyPasswordResetCode(
        VerifyResetCodeDto(email: email, code: _codeController.text),
      );
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AuthRoutes.newPassword,
        arguments: {'email': email, 'resetToken': resetToken},
      );
    } on UserServiceException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Connexion au serveur impossible.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    final passwordChangeFlow = _isPasswordChangeFlow(context);
    final email = _emailFromArguments(context);
    final accessToken = AuthSessionService.current?.accessToken ?? '';
    _codeController.clear();
    _codeFocusNode.requestFocus();
    setState(() => _isResending = true);
    try {
      final response = passwordChangeFlow
          ? await _userService.resendPasswordChangeCode(accessToken)
          : await _userService.requestPasswordReset(
              ForgotPasswordDto(email: email),
            );
      if (!mounted) return;
      final debugCode = response['debugCode']?.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            debugCode == null
                ? 'Un nouveau code a été envoyé.'
                : 'Code de développement : $debugCode',
          ),
        ),
      );
    } on UserServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _emailFromArguments(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) return arguments['email']?.toString() ?? '';
    return arguments is String ? arguments : '';
  }

  bool _isPasswordChangeFlow(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is Map && arguments['flow'] == 'passwordChange';
  }

  Future<void> _confirmPasswordChange() async {
    final currentSession = AuthSessionService.current;
    if (currentSession == null) {
      await AuthSessionService.clear();
      return;
    }

    final response = await _userService.confirmPasswordChange(
      code: _codeController.text,
      accessToken: currentSession.accessToken,
    );
    final rawUser = response['user'];
    final user = rawUser is Map
        ? UserProfileDto.fromJson(Map<String, dynamic>.from(rawUser))
        : currentSession.user;
    final refreshedSession = AuthSession.fromResponse(
      response,
      user: user,
      rememberMe: currentSession.rememberMe,
    );
    await AuthSessionService.activate(refreshedSession);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Votre mot de passe a été modifié avec succès.'),
        backgroundColor: CharginiColors.green,
      ),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      UserRoutes.profile,
      (route) => false,
      arguments: refreshedSession,
    );
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final email = _emailFromArguments(context);
    final debugCode = arguments is Map
        ? arguments['debugCode']?.toString()
        : null;
    final passwordChangeFlow = _isPasswordChangeFlow(context);

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
                            Positioned(
                              left: 0,
                              child: CharginiBackButton(
                                fallbackRoute: passwordChangeFlow
                                    ? UserRoutes.changePassword
                                    : AuthRoutes.forgotPassword,
                              ),
                            ),
                            const Positioned(
                              left: 72,
                              right: 0,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Code de vérification',
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
                        height: compact ? 245 : 330,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/verification_code.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      SizedBox(height: compact ? 12 : 24),
                      const Text(
                        'Nous avons envoyé un code par e-mail à',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CharginiColors.bodyText,
                          fontSize: 18,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email.isEmpty ? 'votre adresse e-mail' : email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CharginiColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (debugCode != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Code de développement : $debugCode',
                          style: const TextStyle(
                            color: CharginiColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      SizedBox(height: compact ? 22 : 34),
                      _CodeInput(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        hasError: _errorMessage != null,
                        onSubmitted: _continue,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      const Text(
                        'Vous n’avez pas reçu le code ?',
                        style: TextStyle(
                          color: CharginiColors.bodyText,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: _isResending ? null : _resendCode,
                        style: TextButton.styleFrom(
                          foregroundColor: CharginiColors.green,
                        ),
                        child: Text(
                          _isResending
                              ? 'Envoi en cours...'
                              : 'Renvoyer le code',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CharginiPrimaryButton(
                        label: _isSubmitting ? 'Vérification...' : 'Continuer',
                        onPressed: _isSubmitting ? null : _continue,
                        showArrow: !_isSubmitting,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: CharginiColors.border),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: passwordChangeFlow
                                ? TextButton(
                                    onPressed: () =>
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          UserRoutes.profile,
                                          (route) => false,
                                          arguments: AuthSessionService.current,
                                        ),
                                    child: const Text(
                                      'Retour au profil',
                                      style: TextStyle(
                                        color: CharginiColors.green,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                : AuthFooterLink(
                                    prefix: 'Retour à la ',
                                    action: 'connexion',
                                    onTap: () =>
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          AuthRoutes.login,
                                          (route) => false,
                                        ),
                                  ),
                          ),
                          const Expanded(
                            child: Divider(color: CharginiColors.border),
                          ),
                        ],
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

class _CodeInput extends StatelessWidget {
  const _CodeInput({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Code de vérification à 6 chiffres',
      child: GestureDetector(
        onTap: focusNode.requestFocus,
        child: Stack(
          children: [
            Row(
              children: List.generate(6, (index) {
                final hasDigit = controller.text.length > index;
                final digit = hasDigit ? controller.text[index] : '';
                final selected = controller.text.length == index;

                return Expanded(
                  child: Container(
                    height: 58,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasError
                            ? Colors.redAccent
                            : selected && focusNode.hasFocus
                            ? CharginiColors.green
                            : CharginiColors.border,
                        width: selected && focusNode.hasFocus ? 1.8 : 1.4,
                      ),
                    ),
                    child: Text(
                      digit,
                      style: const TextStyle(
                        color: CharginiColors.navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  showCursor: false,
                  enableSuggestions: false,
                  autocorrect: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => onSubmitted(),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
