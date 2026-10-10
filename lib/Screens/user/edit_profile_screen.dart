import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../DTOs/user_profile_dto.dart';
import '../../UI_Components/chargini_auth_components.dart';
import 'user_routes.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _birthDate;
  UserProfileDto? _user;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is UserProfileDto) {
      _user = argument;
      _firstNameController.text = argument.firstName;
      _lastNameController.text = argument.lastName;
      _emailController.text = argument.email;
      _phoneController.text = _formatPhone(argument.phone);
      _birthDate = argument.birthDate;
      _birthDateController.text = _formatNumericDate(argument.birthDate);
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );
    if (selected == null) return;
    setState(() {
      _birthDate = selected;
      _birthDateController.text = _formatNumericDate(selected);
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Le formulaire est prêt. La modification MongoDB sera connectée à la prochaine étape.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _user?.role == 'station_owner'
        ? 'Propriétaire de station'
        : 'Conducteur';

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
                  const _PageHeader(title: 'Modifier le profil'),
                  const SizedBox(height: 4),
                  const Text(
                    'Mettez à jour vos informations personnelles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CharginiColors.bodyText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _FieldLabel('PRÉNOM'),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _profileInputDecoration(
                      hintText: 'Prénom',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 22),
                  _FieldLabel('NOM'),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _profileInputDecoration(
                      hintText: 'Nom',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 22),
                  _FieldLabel('E-MAIL'),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _profileInputDecoration(
                      hintText: 'Adresse e-mail',
                      icon: Icons.mail_outline_rounded,
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(email)) {
                        return 'Saisissez une adresse e-mail valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  _FieldLabel('TÉLÉPHONE'),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    decoration: _profileInputDecoration(
                      hintText: '+216 XX XXX XXX',
                      icon: Icons.phone_outlined,
                    ),
                    validator: (value) {
                      final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                      final local = digits.startsWith('216')
                          ? digits.substring(3)
                          : digits;
                      if (!RegExp(r'^[24579]\d{7}$').hasMatch(local)) {
                        return 'Saisissez un numéro tunisien valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  _FieldLabel('DATE DE NAISSANCE'),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: _pickBirthDate,
                    decoration: _profileInputDecoration(
                      hintText: 'JJ/MM/AAAA',
                      icon: Icons.calendar_month_outlined,
                      suffix: IconButton(
                        onPressed: _pickBirthDate,
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          color: CharginiColors.bodyText,
                        ),
                      ),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 22),
                  _FieldLabel('RÔLE'),
                  const SizedBox(height: 9),
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FFF6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFCDEED8)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDF8E6),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.directions_car_outlined,
                            color: CharginiColors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: CharginiColors.navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: CharginiColors.bodyText,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  CharginiPrimaryButton(
                    label: 'Enregistrer les modifications',
                    onPressed: _save,
                  ),
                  const SizedBox(height: 12),
                  _CancelButton(onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return (value?.trim().isEmpty ?? true) ? 'Ce champ est obligatoire' : null;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
                title,
                style: const TextStyle(
                  color: CharginiColors.navy,
                  fontSize: 28,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: CharginiColors.bodyText,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
      ),
    );
  }
}

InputDecoration _profileInputDecoration({
  required String hintText,
  required IconData icon,
  Widget? suffix,
}) {
  return charginiInputDecoration(
    hintText: hintText,
    prefixIcon: icon,
    suffixIcon: suffix,
  ).copyWith(
    hintStyle: const TextStyle(
      color: CharginiColors.navy,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
  );
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CharginiColors.navy,
          side: const BorderSide(color: CharginiColors.border, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        child: const Text('Annuler'),
      ),
    );
  }
}

String _formatNumericDate(DateTime? date) {
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('216')) {
    final local = digits.substring(3);
    return '+216 ${local.substring(0, 2)} ${local.substring(2, 5)} '
        '${local.substring(5)}';
  }
  return phone;
}
