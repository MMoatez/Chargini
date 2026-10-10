import 'package:flutter/material.dart';

import '../../DTOs/vehicule_dto.dart';
import '../../UI_Components/chargini_auth_components.dart';

class VehiculePageHeader extends StatelessWidget {
  const VehiculePageHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          const SizedBox(
            width: 54,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CharginiBackButton(fallbackRoute: '/profile'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CharginiColors.navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: trailing == null ? 54 : 68,
            child: trailing == null
                ? null
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
          ),
        ],
      ),
    );
  }
}

class VehiculeInfoBanner extends StatelessWidget {
  const VehiculeInfoBanner({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7F3E0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: CharginiColors.green,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF49637B),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String vehiculeNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

class VehiculeConnectorIcon extends StatelessWidget {
  const VehiculeConnectorIcon({
    super.key,
    required this.connector,
    this.size = 30,
    this.color = const Color(0xFF0B546F),
  });

  final String connector;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _VehiculeConnectorPainter(
        isCcsCombo:
            VehiculeConnectors.normalize(connector) ==
            VehiculeConnectors.ccsCombo,
        color: color,
      ),
    ),
  );
}

class _VehiculeConnectorPainter extends CustomPainter {
  const _VehiculeConnectorPainter({
    required this.isCcsCombo,
    required this.color,
  });

  final bool isCcsCombo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final stroke = side * 0.065;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pins = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (isCcsCombo) {
      final upperCenter = Offset(side * 0.5, side * 0.32);
      canvas.drawCircle(upperCenter, side * 0.275, outline);
      for (final point in const [
        Offset(0.39, 0.22),
        Offset(0.61, 0.22),
        Offset(0.36, 0.38),
        Offset(0.64, 0.38),
        Offset(0.50, 0.32),
      ]) {
        canvas.drawCircle(
          Offset(side * point.dx, side * point.dy),
          side * 0.035,
          pins,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(side * 0.20, side * 0.54, side * 0.80, side * 0.94),
          Radius.circular(side * 0.12),
        ),
        outline,
      );
      canvas.drawCircle(
        Offset(side * 0.37, side * 0.74),
        side * 0.075,
        outline,
      );
      canvas.drawCircle(
        Offset(side * 0.63, side * 0.74),
        side * 0.075,
        outline,
      );
      return;
    }

    final center = Offset(side * 0.5, side * 0.5);
    canvas.drawCircle(center, side * 0.42, outline);
    for (final point in const [
      Offset(0.37, 0.28),
      Offset(0.63, 0.28),
      Offset(0.29, 0.50),
      Offset(0.71, 0.50),
      Offset(0.39, 0.70),
      Offset(0.61, 0.70),
      Offset(0.50, 0.48),
    ]) {
      canvas.drawCircle(
        Offset(side * point.dx, side * point.dy),
        side * 0.045,
        pins,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VehiculeConnectorPainter oldDelegate) =>
      oldDelegate.isCcsCombo != isCcsCombo || oldDelegate.color != color;
}
