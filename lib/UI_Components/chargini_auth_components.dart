import 'package:flutter/material.dart';

abstract final class CharginiColors {
  static const green = Color(0xFF00BF4F);
  static const navy = Color(0xFF002C4D);
  static const bodyText = Color(0xFF7D89AA);
  static const border = Color(0xFFD9E2EA);
  static const paleGreen = Color(0xFFF3FFF7);
}

class CharginiLogo extends StatelessWidget {
  const CharginiLogo({super.key, this.width = 150, this.height = 105});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class CharginiBackButton extends StatelessWidget {
  const CharginiBackButton({super.key, this.fallbackRoute = '/welcome'});

  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: const Color(0x22002C4D),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () async {
          final navigator = Navigator.of(context);
          final didPop = await navigator.maybePop();
          if (!didPop && context.mounted) {
            await navigator.pushReplacementNamed(fallbackRoute);
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox.square(
          dimension: 54,
          child: Icon(
            Icons.arrow_back_rounded,
            color: CharginiColors.navy,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class CharginiPrimaryButton extends StatelessWidget {
  const CharginiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B846), Color(0xFF00CD58)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3300BF4F),
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 14),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CharginiOutlinedButton extends StatelessWidget {
  const CharginiOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CharginiColors.green,
          side: const BorderSide(color: CharginiColors.green, width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

InputDecoration charginiInputDecoration({
  required String hintText,
  required IconData prefixIcon,
  Widget? suffixIcon,
  Widget? prefix,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: CharginiColors.bodyText,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: prefix ?? Icon(prefixIcon, color: CharginiColors.bodyText),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: CharginiColors.border, width: 1.4),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: CharginiColors.green, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
    ),
  );
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: CharginiColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(color: CharginiColors.bodyText, fontSize: 16),
          ),
        ),
        Expanded(child: Divider(color: CharginiColors.border)),
      ],
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  final String prefix;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prefix,
          style: const TextStyle(color: CharginiColors.bodyText, fontSize: 15),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: CharginiColors.green,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
