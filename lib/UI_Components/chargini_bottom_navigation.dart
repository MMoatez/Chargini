import 'package:flutter/material.dart';

import 'chargini_auth_components.dart';

class CharginiBottomNavigation extends StatelessWidget {
  const CharginiBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 88,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x17002C4D),
              blurRadius: 22,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            const _NavigationItem(icon: Icons.home_outlined, label: 'Accueil'),
            const _NavigationItem(icon: Icons.map_outlined, label: 'Carte'),
            const _NavigationItem(
              icon: Icons.calendar_month_outlined,
              label: 'Réservations',
            ),
            const _NavigationItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Messages',
              showNotification: true,
            ),
            _NavigationItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              selected: true,
              onTap: () => Navigator.of(context).popUntil(
                (route) => route.settings.name == '/profile' || route.isFirst,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.showNotification = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showNotification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE9FBEF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? CharginiColors.green
                          : CharginiColors.bodyText,
                      size: 26,
                    ),
                  ),
                  if (showNotification)
                    const Positioned(
                      top: 0,
                      right: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: CharginiColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(dimension: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? CharginiColors.green
                        : CharginiColors.bodyText,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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
