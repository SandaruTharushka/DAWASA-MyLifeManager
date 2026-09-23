import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The DAWASA mark: a sun rising over the horizon ("dawasa" means "day" in
/// Sinhala) on a green rounded square. The same geometry is used for the
/// launcher icon (see `tool/icon/dawasa_icon.svg`).
class DawasaLogo extends StatelessWidget {
  const DawasaLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'DAWASA',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _LogoPainter()),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final background = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.24));
    canvas.drawRRect(
      background,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22C55E), AppPalette.green, AppPalette.darkGreen],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipRRect(background);

    final center = Offset(s * 0.5, s * 0.60);
    final radius = s * 0.20;
    final white = Paint()..color = Colors.white;

    // Rays.
    final rayPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round;
    for (final angle in [-150.0, -120.0, -90.0, -60.0, -30.0]) {
      final rad = angle * math.pi / 180;
      final from =
          center + Offset(math.cos(rad), math.sin(rad)) * (radius + s * 0.07);
      final to =
          center + Offset(math.cos(rad), math.sin(rad)) * (radius + s * 0.15);
      canvas.drawLine(from, to, rayPaint);
    }

    // Sun (upper half visible above the horizon).
    canvas.drawCircle(center, radius, white);

    // Horizon: a soft light-green hill covering the lower half of the sun.
    final horizon = Path()
      ..moveTo(0, center.dy + s * 0.01)
      ..quadraticBezierTo(
        s * 0.5,
        center.dy - s * 0.05,
        s,
        center.dy + s * 0.01,
      )
      ..lineTo(s, s)
      ..lineTo(0, s)
      ..close();
    canvas.drawPath(horizon, Paint()..color = AppPalette.lightGreen);

    // Check mark on the hill: "a day well planned".
    final check = Path()
      ..moveTo(s * 0.36, s * 0.78)
      ..lineTo(s * 0.46, s * 0.87)
      ..lineTo(s * 0.66, s * 0.70);
    canvas.drawPath(
      check,
      Paint()
        ..color = AppPalette.darkGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.06
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
