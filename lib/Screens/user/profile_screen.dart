import 'dart:async';

import 'package:flutter/material.dart';

import '../../DTOs/user_profile_dto.dart';
import '../../Services/auth_session_service.dart';
import '../../Services/user_service.dart';
import '../../UI_Components/chargini_auth_components.dart';
import '../auth/auth_routes.dart';
import 'user_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.initialSession});

  final AuthSession? initialSession;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserProfileDto? _user;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final argument = ModalRoute.of(context)?.settings.arguments;
    final session =
        widget.initialSession ?? (argument is AuthSession ? argument : null);
    _user =
        session?.user ??
        (argument is UserProfileDto ? argument : null) ??
        const UserProfileDto(
          id: '',
          firstName: 'Utilisateur',
          lastName: 'Chargini',
          email: '',
          phone: '',
          birthDate: null,
          role: 'user',
        );
  }

  Future<void> _logout() async {
    final refreshToken = AuthSessionService.current?.refreshToken;
    await AuthSessionService.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AuthRoutes.login,
      (route) => false,
    );

    if (refreshToken != null) {
      unawaited(_revokeRefreshToken(refreshToken));
    }
  }

  Future<void> _revokeRefreshToken(String refreshToken) async {
    try {
      await _userService.logout(refreshToken);
    } catch (_) {
      // The local session is already cleared, including while offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user!;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFE),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              children: [
                const _ProfileHeader(),
                const SizedBox(height: 22),
                _IdentityCard(user: user),
                const SizedBox(height: 24),
                const _SectionTitle('INFORMATIONS PERSONNELLES'),
                const SizedBox(height: 12),
                _ProfileCard(
                  children: [
                    _InformationRow(
                      icon: Icons.person_outline_rounded,
                      title: 'Prénom',
                      value: user.firstName,
                    ),
                    _InformationRow(
                      icon: Icons.person_outline_rounded,
                      title: 'Nom',
                      value: user.lastName,
                    ),
                    _InformationRow(
                      icon: Icons.calendar_month_outlined,
                      title: 'Date de naissance',
                      value: _formatFrenchDate(user.birthDate),
                    ),
                    _InformationRow(
                      icon: Icons.shield_outlined,
                      title: 'Rôle',
                      value: user.role == 'station_owner'
                          ? 'Propriétaire de station'
                          : 'Conducteur',
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle('GESTION DU COMPTE'),
                const SizedBox(height: 12),
                _AccountCard(user: user, onLogout: _logout),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _BottomNavigation(),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Mon compte',
            style: TextStyle(
              color: CharginiColors.navy,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          Positioned(left: 0, child: _CharginiMiniLogo()),
        ],
      ),
    );
  }
}

class _CharginiMiniLogo extends StatelessWidget {
  const _CharginiMiniLogo();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF07516D), CharginiColors.navy],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -3,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: CharginiColors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final UserProfileDto user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003D5B), Color(0xFF006B89)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F003A57),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF8),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  user.initials.isEmpty ? 'C' : user.initials,
                  style: const TextStyle(
                    color: CharginiColors.navy,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Positioned(
                right: -6,
                bottom: -5,
                child: Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: CharginiColors.green,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF006681),
                      width: 3,
                    ),
                  ),
                  child: const Icon(Icons.circle, color: Colors.white, size: 7),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB9DCE8),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTunisianPhone(user.phone),
                  style: const TextStyle(
                    color: Color(0xFFB9DCE8),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: CharginiColors.bodyText,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.2,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CharginiColors.border, width: 1.2),
      ),
      child: Column(children: children),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.title,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              _SquareIcon(icon: icon),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: CharginiColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
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
        if (showDivider) const Divider(height: 1, color: CharginiColors.border),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.onLogout});

  final UserProfileDto user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final vehicles = user.vehicleCount == 1
        ? '1 véhicule enregistré'
        : '${user.vehicleCount} véhicules enregistrés';
    return _ProfileCard(
      children: [
        _ActionRow(
          icon: Icons.directions_car_outlined,
          title: 'Mes véhicules',
          subtitle: vehicles,
          onTap: () => _comingSoon(context, 'Mes véhicules'),
        ),
        _ActionRow(
          icon: Icons.edit_outlined,
          title: 'Modifier le profil',
          onTap: () => Navigator.pushNamed(
            context,
            UserRoutes.editProfile,
            arguments: user,
          ),
        ),
        _ActionRow(
          icon: Icons.lock_outline_rounded,
          title: 'Changer le mot de passe',
          onTap: () => Navigator.pushNamed(
            context,
            UserRoutes.changePassword,
            arguments: user,
          ),
        ),
        _ActionRow(
          icon: Icons.delete_outline_rounded,
          title: 'Supprimer le compte',
          destructive: true,
          onTap: () => Navigator.pushNamed(
            context,
            UserRoutes.deleteAccount,
            arguments: user,
          ),
        ),
        _ActionRow(
          icon: Icons.logout_rounded,
          title: 'Se déconnecter',
          destructive: true,
          showDivider: false,
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool destructive;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE91D43) : CharginiColors.navy;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _SquareIcon(icon: icon, destructive: destructive),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: CharginiColors.bodyText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CharginiColors.bodyText,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: CharginiColors.border),
      ],
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon, this.destructive = false});

  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: destructive ? const Color(0xFFFFF0F3) : const Color(0xFFF2F7F9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        color: destructive ? const Color(0xFFE91D43) : const Color(0xFF00506D),
        size: 27,
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

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
        child: const Row(
          children: [
            _NavigationItem(icon: Icons.home_outlined, label: 'Accueil'),
            _NavigationItem(icon: Icons.map_outlined, label: 'Carte'),
            _NavigationItem(
              icon: Icons.calendar_month_outlined,
              label: 'Réservations',
            ),
            _NavigationItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Messages',
              showNotification: true,
            ),
            _NavigationItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              selected: true,
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showNotification;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
    );
  }
}

String _formatFrenchDate(DateTime? date) {
  if (date == null) return 'Non renseignée';
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatTunisianPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('216')) {
    final local = digits.substring(3);
    return '+216 ${local.substring(0, 2)} ${local.substring(2, 5)} '
        '${local.substring(5)}';
  }
  return phone;
}

void _comingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature sera ajouté à la prochaine étape.')),
  );
}
