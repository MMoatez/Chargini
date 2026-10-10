import 'package:flutter/material.dart';

import '../../DTOs/vehicule_dto.dart';
import '../../Services/auth_session_service.dart';
import '../../Services/vehicule_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import 'vehicule_components.dart';

class DeleteVehiculeScreen extends StatefulWidget {
  const DeleteVehiculeScreen({super.key, required this.vehicule});
  final VehiculeDto vehicule;

  @override
  State<DeleteVehiculeScreen> createState() => _DeleteVehiculeScreenState();
}

class _DeleteVehiculeScreenState extends State<DeleteVehiculeScreen> {
  final VehiculeService _service = VehiculeService();
  bool _deleting = false;

  Future<void> _delete() async {
    final session = AuthSessionService.current;
    if (session == null || _deleting) return;
    setState(() => _deleting = true);
    try {
      await _service.deleteVehicule(session.accessToken, widget.vehicule.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Véhicule supprimé. Un e-mail de confirmation vous a été envoyé.',
          ),
          backgroundColor: CharginiColors.green,
        ),
      );
      Navigator.pop(context, true);
    } on VehiculeServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion au serveur impossible.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicule = widget.vehicule;
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFE),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                const VehiculePageHeader(title: 'Supprimer le véhicule'),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: CharginiColors.border),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 110,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F7F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.electric_car_rounded,
                              color: Color(0xFF0B546F),
                              size: 67,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicule.displayName,
                                  style: const TextStyle(
                                    color: CharginiColors.navy,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  vehicule.isPrimary
                                      ? '●  Véhicule principal'
                                      : 'Véhicule secondaire',
                                  style: TextStyle(
                                    color: vehicule.isPrimary
                                        ? CharginiColors.green
                                        : CharginiColors.bodyText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Divider(color: CharginiColors.border),
                      ),
                      _Summary(
                        icon: Icons.directions_car_outlined,
                        label: 'Modèle',
                        value: vehicule.model,
                      ),
                      _Summary(
                        icon: Icons.battery_5_bar_outlined,
                        label: 'Batterie',
                        value:
                            '${vehiculeNumber(vehicule.batteryCapacity)} kWh',
                      ),
                      _Summary(
                        icon: Icons.speed_rounded,
                        label: 'Autonomie estimée',
                        value: '${vehiculeNumber(vehicule.rangeKm)} km',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF0),
                    border: Border.all(color: const Color(0xFFFFCDD5)),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE91D43),
                        size: 42,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ce véhicule sera retiré de votre compte.',
                              style: TextStyle(
                                color: CharginiColors.navy,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Cette action est irréversible.',
                              style: TextStyle(
                                color: CharginiColors.bodyText,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
                SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: _deleting ? null : _delete,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE91D43),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _deleting ? 'Suppression…' : 'Supprimer le véhicule',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 58,
                  child: OutlinedButton(
                    onPressed: _deleting
                        ? null
                        : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CharginiColors.navy,
                      side: const BorderSide(color: CharginiColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFCFDFE),
      border: Border.all(color: const Color(0xFFE9EEF2)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF0B546F), size: 30),
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
