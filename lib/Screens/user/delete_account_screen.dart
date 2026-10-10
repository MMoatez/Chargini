import 'package:flutter/material.dart';

import '../../DTOs/user_profile_dto.dart';
import '../../UI_Components/chargini_auth_components.dart';
import 'user_routes.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    final user = argument is UserProfileDto
        ? argument
        : const UserProfileDto(
            id: '',
            firstName: 'Utilisateur',
            lastName: 'Chargini',
            email: '',
            phone: '',
            birthDate: null,
            role: 'user',
          );

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFE),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 46,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const _DeleteHeader(),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Column(
                              children: [
                                _DeleteIllustration(),
                                SizedBox(height: 24),
                                Text(
                                  'Cette action est définitive.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: CharginiColors.navy,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Toutes vos informations, véhicules et\nréservations seront supprimés.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: CharginiColors.bodyText,
                                    fontSize: 17,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: CharginiColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FFF8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user.initials.isEmpty ? 'C' : user.initials,
                                    style: const TextStyle(
                                      color: CharginiColors.navy,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
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
                                          color: CharginiColors.navy,
                                          fontSize: 21,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        user.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3F4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFFFCCD2)),
                            ),
                            child: const Row(
                              children: [
                                CircleAvatar(
                                  radius: 19,
                                  backgroundColor: Color(0xFFE92E45),
                                  child: Text(
                                    '!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Vous ne pourrez pas récupérer votre compte.',
                                    style: TextStyle(
                                      color: Color(0xFFE92E45),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: FilledButton(
                              onPressed: () => _showNotConnected(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFE72C42),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              child: const Text('Supprimer définitivement'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CharginiColors.navy,
                                side: const BorderSide(
                                  color: CharginiColors.border,
                                  width: 1.4,
                                ),
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showNotConnected(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Suppression désactivée pour le moment. Nous connecterons cette action au backend en toute sécurité.',
        ),
      ),
    );
  }
}

class _DeleteHeader extends StatelessWidget {
  const _DeleteHeader();

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
                'Supprimer le compte',
                style: TextStyle(
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

class _DeleteIllustration extends StatelessWidget {
  const _DeleteIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD9DC),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFE52E45),
            size: 62,
          ),
        ),
        const Positioned(
          right: -6,
          bottom: 7,
          child: CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFFE52E45),
            child: Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
