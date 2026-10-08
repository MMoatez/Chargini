import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../DTOs/register_user_dto.dart';
import '../../Services/user_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import 'auth_routes.dart';

enum UserGender { male, female }

enum UserRole { user, stationOwner }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();

  DateTime? _birthDate;
  UserGender _gender = UserGender.male;
  UserRole _role = UserRole.user;
  bool _acceptTerms = true;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (selectedDate == null) return;
    _birthDate = selectedDate;
    _birthDateController.text =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  Future<void> _submit() async {
    final validForm = _formKey.currentState?.validate() ?? false;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez accepter les conditions d’utilisation.'),
        ),
      );
      return;
    }
    if (!validForm) return;

    setState(() => _isSubmitting = true);
    try {
      final registration = RegisterUserDto(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        birthDate: _birthDate!,
        email: _emailController.text,
        phone: _normalizePhone(_phoneController.text),
        gender: _gender.name,
        role: _role == UserRole.user ? 'user' : 'station_owner',
        password: _passwordController.text,
      );
      await _userService.createUser(registration);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: CharginiColors.green,
            size: 52,
          ),
          title: const Text('Compte créé'),
          content: const Text(
            'Votre compte a bien été enregistré. Vous pouvez maintenant vous connecter.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (mounted) {
        await Navigator.pushReplacementNamed(context, AuthRoutes.login);
      }
    } on UserServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Connexion au serveur impossible. Vérifiez que NestJS et MongoDB sont démarrés.',
            ),
          ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: const [
                          Positioned(
                            left: 0,
                            top: 5,
                            child: CharginiBackButton(),
                          ),
                          CharginiLogo(width: 136, height: 92),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Créer un compte',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CharginiColors.navy,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Renseignez vos informations pour rejoindre Chargini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CharginiColors.bodyText,
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: charginiInputDecoration(
                              hintText: 'Prénom',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            validator: _requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: charginiInputDecoration(
                              hintText: 'Nom',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _birthDateController,
                      readOnly: true,
                      onTap: _pickBirthDate,
                      decoration: charginiInputDecoration(
                        hintText: 'Date de naissance',
                        prefixIcon: Icons.calendar_today_outlined,
                        suffixIcon: IconButton(
                          onPressed: _pickBirthDate,
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            color: CharginiColors.bodyText,
                          ),
                        ),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 14),
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
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: charginiInputDecoration(
                        hintText: 'XX XXX XXX',
                        prefixIcon: Icons.phone_outlined,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 16, right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                color: CharginiColors.bodyText,
                              ),
                              SizedBox(width: 12),
                              _TunisiaFlag(),
                              SizedBox(width: 8),
                              Text(
                                '+216',
                                style: TextStyle(
                                  color: CharginiColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 10),
                              SizedBox(
                                height: 32,
                                child: VerticalDivider(
                                  color: CharginiColors.border,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      validator: (value) {
                        final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                        if (!RegExp(r'^[24579]\d{7}$').hasMatch(phone)) {
                          return 'Saisissez un numéro tunisien valide à 8 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Genre',
                      style: TextStyle(
                        color: CharginiColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ChoiceCard(
                            selected: _gender == UserGender.male,
                            icon: Icons.person_outline_rounded,
                            label: 'Homme',
                            onTap: () =>
                                setState(() => _gender = UserGender.male),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChoiceCard(
                            selected: _gender == UserGender.female,
                            icon: Icons.person_outline_rounded,
                            label: 'Femme',
                            onTap: () =>
                                setState(() => _gender = UserGender.female),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Rôle',
                      style: TextStyle(
                        color: CharginiColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ChoiceCard(
                            selected: _role == UserRole.user,
                            icon: Icons.person_outline_rounded,
                            label: 'Utilisateur',
                            onTap: () => setState(() => _role = UserRole.user),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChoiceCard(
                            selected: _role == UserRole.stationOwner,
                            icon: Icons.ev_station_outlined,
                            label: 'Propriétaire de station',
                            onTap: () =>
                                setState(() => _role = UserRole.stationOwner),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                      validator: (value) {
                        if ((value?.length ?? 0) < 8) {
                          return 'Utilisez au moins 8 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      obscureText: _obscureConfirmation,
                      decoration: charginiInputDecoration(
                        hintText: 'Confirmer le mot de passe',
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirmation = !_obscureConfirmation,
                          ),
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: CharginiColors.bodyText,
                          ),
                        ),
                      ),
                      validator: (value) => value != _passwordController.text
                          ? 'Les mots de passe ne correspondent pas'
                          : null,
                    ),
                    CheckboxListTile(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() => _acceptTerms = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: CharginiColors.green,
                      title: const Text.rich(
                        TextSpan(
                          text: 'J’accepte les ',
                          children: [
                            TextSpan(
                              text: 'conditions d’utilisation',
                              style: TextStyle(
                                color: CharginiColors.green,
                                decoration: TextDecoration.underline,
                                decorationColor: CharginiColors.green,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: CharginiColors.bodyText,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CharginiPrimaryButton(
                      label: _isSubmitting
                          ? 'Création en cours...'
                          : 'Créer mon compte',
                      onPressed: _isSubmitting ? null : _submit,
                      showArrow: !_isSubmitting,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: AuthFooterLink(
                        prefix: 'Déjà un compte ? ',
                        action: 'Se connecter',
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AuthRoutes.login,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    return (value?.trim().isEmpty ?? true) ? 'Ce champ est obligatoire' : null;
  }

  String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return '+216$digits';
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? CharginiColors.paleGreen : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? CharginiColors.green : CharginiColors.border,
              width: selected ? 1.8 : 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? CharginiColors.green
                        : CharginiColors.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          color: CharginiColors.green,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Icon(icon, color: CharginiColors.navy, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? CharginiColors.navy
                        : CharginiColors.bodyText,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TunisiaFlag extends StatelessWidget {
  const _TunisiaFlag();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFFE70013),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: CharginiColors.border, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          '☪',
          style: TextStyle(
            color: Color(0xFFE70013),
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
