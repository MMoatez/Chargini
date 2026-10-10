import 'package:flutter/material.dart';

import '../../DTOs/vehicule_dto.dart';
import '../../UI_Components/chargini_auth_components.dart';
import '../../UI_Components/chargini_bottom_navigation.dart';
import 'delete_vehicule_screen.dart';
import 'vehicule_components.dart';
import 'vehicule_form_screen.dart';

class VehiculeDetailScreen extends StatefulWidget {
  const VehiculeDetailScreen({super.key, required this.vehicule});
  final VehiculeDto vehicule;

  @override
  State<VehiculeDetailScreen> createState() => _VehiculeDetailScreenState();
}

class _VehiculeDetailScreenState extends State<VehiculeDetailScreen> {
  late VehiculeDto _vehicule;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _vehicule = widget.vehicule;
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<VehiculeDto>(
      context,
      MaterialPageRoute(
        builder: (_) => VehiculeFormScreen(vehicule: _vehicule),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _vehicule = updated;
        _changed = true;
      });
    }
  }

  Future<void> _delete() async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DeleteVehiculeScreen(vehicule: _vehicule),
      ),
    );
    if (deleted == true && mounted) Navigator.pop(context, true);
  }

  Future<bool> _onPop() async {
    Navigator.pop(context, _changed);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFDFE),
        bottomNavigationBar: const CharginiBottomNavigation(),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  const VehiculePageHeader(title: 'Détails du véhicule'),
                  const SizedBox(height: 18),
                  _Hero(vehicule: _vehicule),
                  const SizedBox(height: 24),
                  const Text(
                    'INFORMATIONS',
                    style: TextStyle(
                      color: CharginiColors.bodyText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.business_outlined,
                    label: 'Marque',
                    value: _vehicule.brand,
                  ),
                  _DetailRow(
                    icon: Icons.electric_car_outlined,
                    label: 'Modèle',
                    value: _vehicule.model,
                  ),
                  _DetailRow(
                    icon: Icons.battery_5_bar_outlined,
                    label: 'Batterie',
                    value: '${vehiculeNumber(_vehicule.batteryCapacity)} kWh',
                  ),
                  _DetailRow(
                    icon: Icons.speed_rounded,
                    label: 'Autonomie estimée',
                    value: '${vehiculeNumber(_vehicule.rangeKm)} km',
                  ),
                  _DetailRow(
                    iconWidget: VehiculeConnectorIcon(
                      connector: _vehicule.connector,
                      size: 28,
                    ),
                    label: 'Connecteur',
                    value: _vehicule.connector,
                  ),
                  _DetailRow(
                    icon: Icons.pin_outlined,
                    label: 'Immatriculation',
                    value: _vehicule.registrationNumber,
                  ),
                  const SizedBox(height: 14),
                  const VehiculeInfoBanner(
                    text:
                        'Ce véhicule est utilisé pour suggérer les bornes compatibles.',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: CharginiPrimaryButton(
                          label: 'Modifier',
                          showArrow: false,
                          onPressed: _edit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: FilledButton.icon(
                            onPressed: _delete,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFEDF0),
                              foregroundColor: const Color(0xFFE91D43),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const FittedBox(
                              child: Text(
                                'Supprimer le véhicule',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _Hero extends StatelessWidget {
  const _Hero({required this.vehicule});
  final VehiculeDto vehicule;
  @override
  Widget build(BuildContext context) => Container(
    height: 205,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF003D5B), Color(0xFF00746E)],
      ),
      borderRadius: BorderRadius.circular(27),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  vehicule.isPrimary ? '●  Principal' : 'Secondaire',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                vehicule.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Véhicule électrique',
                style: TextStyle(color: Color(0xFFB8DDE4), fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 135,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.electric_car_rounded,
            size: 82,
            color: Color(0xFF0B546F),
          ),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.value,
  }) : assert(icon != null || iconWidget != null);
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: CharginiColors.border),
      borderRadius: BorderRadius.circular(19),
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F7F9),
            borderRadius: BorderRadius.circular(15),
          ),
          child:
              iconWidget ??
              Icon(icon, color: const Color(0xFF0B546F), size: 27),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: CharginiColors.bodyText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: CharginiColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
