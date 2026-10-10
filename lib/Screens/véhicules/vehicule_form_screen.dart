import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../DTOs/vehicule_dto.dart';
import '../../Services/auth_session_service.dart';
import '../../Services/vehicule_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import 'vehicule_components.dart';

class VehiculeFormScreen extends StatefulWidget {
  const VehiculeFormScreen({super.key, this.vehicule});
  final VehiculeDto? vehicule;

  @override
  State<VehiculeFormScreen> createState() => _VehiculeFormScreenState();
}

class _VehiculeFormScreenState extends State<VehiculeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = VehiculeService();
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _battery;
  late final TextEditingController _range;
  late String _connector;
  late final TextEditingController _registration;
  late bool _isPrimary;
  bool _submitting = false;

  bool get _editing => widget.vehicule != null;

  @override
  void initState() {
    super.initState();
    final vehicule = widget.vehicule;
    _brand = TextEditingController(text: vehicule?.brand ?? '');
    _model = TextEditingController(text: vehicule?.model ?? '');
    _battery = TextEditingController(
      text: vehicule == null ? '' : vehiculeNumber(vehicule.batteryCapacity),
    );
    _range = TextEditingController(
      text: vehicule == null ? '' : vehiculeNumber(vehicule.rangeKm),
    );
    _connector = VehiculeConnectors.normalize(vehicule?.connector);
    _registration = TextEditingController(
      text: vehicule?.registrationNumber ?? '',
    );
    _isPrimary = vehicule?.isPrimary ?? true;
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _battery.dispose();
    _range.dispose();
    _registration.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    final session = AuthSessionService.current;
    if (session == null) {
      _showError('Votre session a expiré.');
      return;
    }
    setState(() => _submitting = true);
    final value = VehiculeDto(
      id: widget.vehicule?.id ?? '',
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      batteryCapacity: double.parse(_battery.text.replaceAll(',', '.')),
      rangeKm: double.parse(_range.text.replaceAll(',', '.')),
      connector: _connector,
      registrationNumber: _registration.text.trim().toUpperCase(),
      isPrimary: _isPrimary,
    );
    try {
      final saved = _editing
          ? await _service.updateVehicule(session.accessToken, value)
          : await _service.createVehicule(session.accessToken, value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Véhicule modifié avec succès.'
                : 'Véhicule ajouté avec succès. Un e-mail de confirmation vous a été envoyé.',
          ),
          backgroundColor: CharginiColors.green,
        ),
      );
      Navigator.pop(context, _editing ? saved : true);
    } on VehiculeServiceException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Connexion au serveur impossible.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Ce champ est obligatoire.'
      : null;

  String? _positiveNumber(String? value) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (number == null || number <= 0) return 'Saisissez une valeur positive.';
    return null;
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  VehiculePageHeader(
                    title: _editing
                        ? 'Modifier le véhicule'
                        : 'Ajouter un véhicule',
                  ),
                  const SizedBox(height: 20),
                  if (_editing)
                    const VehiculeInfoBanner(
                      text:
                          'Modifiez les caractéristiques si votre véhicule a changé.',
                    )
                  else
                    const Text(
                      'Enregistrez votre véhicule électrique pour obtenir\nles bonnes bornes compatibles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CharginiColors.bodyText,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  const SizedBox(height: 24),
                  _VehiculeField(
                    label: 'Marque',
                    hint: 'Ex. Tesla',
                    controller: _brand,
                    icon: Icons.electric_car_outlined,
                    validator: _required,
                  ),
                  _VehiculeField(
                    label: 'Modèle',
                    hint: 'Ex. Model 3',
                    controller: _model,
                    icon: Icons.directions_car_outlined,
                    validator: _required,
                  ),
                  _VehiculeField(
                    label: 'Capacité batterie',
                    hint: 'Ex. 60',
                    controller: _battery,
                    icon: Icons.battery_5_bar_outlined,
                    suffix: 'kWh',
                    numeric: true,
                    validator: _positiveNumber,
                  ),
                  _VehiculeField(
                    label: 'Autonomie',
                    hint: 'Ex. 430',
                    controller: _range,
                    icon: Icons.route_outlined,
                    suffix: 'km',
                    numeric: true,
                    validator: _positiveNumber,
                  ),
                  _VehiculeConnectorDropdown(
                    value: _connector,
                    onChanged: (value) => setState(() => _connector = value),
                  ),
                  _VehiculeField(
                    label: 'Immatriculation',
                    hint: 'Ex. TU-2456',
                    controller: _registration,
                    icon: Icons.pin_outlined,
                    textCapitalization: TextCapitalization.characters,
                    validator: _required,
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: CharginiColors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAFBF0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.star_outline_rounded,
                            color: CharginiColors.green,
                            size: 33,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Définir comme véhicule principal',
                                style: TextStyle(
                                  color: CharginiColors.navy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ce véhicule sera utilisé par défaut dans l’application.',
                                style: TextStyle(
                                  color: CharginiColors.bodyText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPrimary,
                          activeTrackColor: CharginiColors.green,
                          onChanged: (value) =>
                              setState(() => _isPrimary = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  CharginiPrimaryButton(
                    label: _submitting
                        ? 'Enregistrement…'
                        : (_editing ? 'Enregistrer' : 'Ajouter le véhicule'),
                    onPressed: _submitting ? null : _submit,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CharginiColors.navy,
                        side: const BorderSide(color: CharginiColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _VehiculeField extends StatelessWidget {
  const _VehiculeField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.validator,
    this.suffix,
    this.numeric = false,
    this.textCapitalization = TextCapitalization.none,
  });
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final String? suffix;
  final bool numeric;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5A6D94),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))]
              : null,
          textCapitalization: textCapitalization,
          validator: validator,
          style: const TextStyle(color: CharginiColors.navy, fontSize: 17),
          decoration: charginiInputDecoration(
            hintText: hint,
            prefixIcon: icon,
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.all(17),
                    child: Text(
                      suffix!,
                      style: const TextStyle(
                        color: CharginiColors.bodyText,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

class _VehiculeConnectorDropdown extends StatelessWidget {
  const _VehiculeConnectorDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connecteur',
          style: TextStyle(
            color: Color(0xFF5A6D94),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: CharginiColors.navy,
          ),
          style: const TextStyle(color: CharginiColors.navy, fontSize: 17),
          decoration: charginiInputDecoration(
            hintText: 'Sélectionnez un connecteur',
            prefixIcon: Icons.electrical_services_outlined,
            prefix: Padding(
              padding: const EdgeInsets.all(14),
              child: VehiculeConnectorIcon(connector: value, size: 27),
            ),
          ),
          items: VehiculeConnectors.values
              .map(
                (connector) => DropdownMenuItem<String>(
                  value: connector,
                  child: Text(connector),
                ),
              )
              .toList(),
          onChanged: (connector) {
            if (connector != null) onChanged(connector);
          },
        ),
      ],
    ),
  );
}
