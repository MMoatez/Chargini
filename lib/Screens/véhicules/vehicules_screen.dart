import 'package:flutter/material.dart';

import '../../DTOs/vehicule_dto.dart';
import '../../Services/auth_session_service.dart';
import '../../Services/vehicule_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import '../../UI_Components/chargini_bottom_navigation.dart';
import 'vehicule_components.dart';
import 'vehicule_detail_screen.dart';
import 'vehicule_form_screen.dart';

class VehiculesScreen extends StatefulWidget {
  const VehiculesScreen({super.key});

  @override
  State<VehiculesScreen> createState() => _VehiculesScreenState();
}

class _VehiculesScreenState extends State<VehiculesScreen> {
  final VehiculeService _service = VehiculeService();
  List<VehiculeDto> _vehicules = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final session = AuthSessionService.current;
    if (session == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Session expirée.';
        });
      }
      return;
    }
    try {
      final vehicules = await _service.getVehicules(session.accessToken);
      if (!mounted) return;
      setState(() {
        _vehicules = vehicules;
        _loading = false;
      });
      if (session.user.vehiculeCount != vehicules.length) {
        await AuthSessionService.activate(
          session.withUser(
            session.user.copyWith(vehiculeCount: vehicules.length),
          ),
        );
      }
    } on VehiculeServiceException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Connexion au serveur impossible.';
        });
      }
    }
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VehiculeFormScreen()),
    );
    if (created == true) await _load();
  }

  Future<void> _openDetail(VehiculeDto vehicule) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VehiculeDetailScreen(vehicule: vehicule),
      ),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFE),
      bottomNavigationBar: const CharginiBottomNavigation(),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                children: [
                  VehiculePageHeader(
                    title: 'Mes véhicules',
                    trailing: _vehicules.isEmpty
                        ? null
                        : TextButton(
                            onPressed: _openAdd,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Ajouter',
                              style: TextStyle(
                                color: CharginiColors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(child: _content()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: CharginiColors.bodyText,
            ),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_vehicules.isEmpty) return _EmptyVehicules(onAdd: _openAdd);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final vehicule in _vehicules) ...[
            _VehiculeCard(
              vehicule: vehicule,
              onTap: () => _openDetail(vehicule),
            ),
            const SizedBox(height: 18),
          ],
          const VehiculeInfoBanner(
            text:
                'Ces véhicules sont utilisés pour adapter les bornes compatibles.',
          ),
        ],
      ),
    );
  }
}

class _EmptyVehicules extends StatelessWidget {
  const _EmptyVehicules({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Image.asset(
              'assets/images/3.png',
              height: 260,
              fit: BoxFit.contain,
            ),
            Positioned(
              right: 30,
              top: 38,
              child: Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: CharginiColors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x3300BF4F), blurRadius: 20),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ],
        ),
        const Text(
          'Aucun véhicule enregistré',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CharginiColors.navy,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ajoutez votre premier véhicule électrique\npour profiter pleinement de l’application.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CharginiColors.bodyText,
            fontSize: 17,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 30),
        CharginiPrimaryButton(label: 'Ajouter un véhicule', onPressed: onAdd),
        const SizedBox(height: 24),
        const VehiculeInfoBanner(
          text:
              'Vos véhicules sont utilisés pour adapter les bornes compatibles et vous proposer une meilleure expérience de recharge.',
        ),
      ],
    );
  }
}

class _VehiculeCard extends StatelessWidget {
  const _VehiculeCard({required this.vehicule, required this.onTap});
  final VehiculeDto vehicule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: CharginiColors.border),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D002C4D),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: vehicule.isPrimary
                          ? const Color(0xFFEAFBF0)
                          : const Color(0xFFF2F7F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.electric_car_rounded,
                      color: vehicule.isPrimary
                          ? CharginiColors.green
                          : const Color(0xFF37647A),
                      size: 39,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleCase(vehicule.displayName),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CharginiColors.navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PrimaryBadge(isPrimary: vehicule.isPrimary),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: CharginiColors.bodyText,
                    size: 30,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: CharginiColors.border),
              ),
              Row(
                children: [
                  _Metric(
                    icon: Icons.battery_5_bar_outlined,
                    label: 'Batterie',
                    value: '${vehiculeNumber(vehicule.batteryCapacity)} kWh',
                  ),
                  const _MetricDivider(),
                  _Metric(
                    icon: Icons.route_outlined,
                    label: 'Autonomie',
                    value: '${vehiculeNumber(vehicule.rangeKm)} km',
                  ),
                  const _MetricDivider(),
                  _Metric(
                    iconWidget: VehiculeConnectorIcon(
                      connector: vehicule.connector,
                      size: 29,
                      color: const Color(0xFF49637B),
                    ),
                    label: 'Connecteur',
                    value: vehicule.connector,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge({required this.isPrimary});
  final bool isPrimary;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: isPrimary ? const Color(0xFFE8F9EE) : const Color(0xFFF0F3F6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      isPrimary ? '●  Véhicule principal' : '●  Véhicule secondaire',
      style: TextStyle(
        color: isPrimary ? CharginiColors.green : CharginiColors.bodyText,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
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
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        iconWidget ?? Icon(icon, color: const Color(0xFF49637B), size: 29),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: CharginiColors.bodyText, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CharginiColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 72, color: CharginiColors.border);
}

String _titleCase(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .map(
      (word) => word.isEmpty
          ? word
          : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
