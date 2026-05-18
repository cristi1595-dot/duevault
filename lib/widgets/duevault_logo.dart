import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DueVaultLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const DueVaultLogo({
    super.key,
    this.size = 100,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final double borderRadius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  blurRadius: size * 0.25,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withValues(alpha: 0.6),
                const Color(0xFF34D399).withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161A22), // Matches AppTheme dark surface
            ),
            child: Center(
              child: CustomPaint(
                size: Size(size * 0.55, size * 0.55),
                painter: _DueVaultLogoPainter(
                  showGlow: showGlow,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DueVaultLogoPainter extends CustomPainter {
  final bool showGlow;

  _DueVaultLogoPainter({
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Design: A minimalist intersecting geometry that combines "D" and "V".
    // A clean diagonal line intersects with a sophisticated vault safe curve.
    final Paint linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF3B82F6)], // Electric Royal Indigo
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round;

    final Paint curvePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF3B82F6)], // Mint Green to Blue
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.16
      ..strokeCap = StrokeCap.round;

    // Optional subtle drop shadow for the logo stroke itself
    if (showGlow) {
      final Paint glowPaint = Paint()
        ..color = const Color(0xFF6366F1).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.22
        ..strokeCap = StrokeCap.round
        ..imageFilter = ui.ImageFilter.blur(sigmaX: w * 0.08, sigmaY: w * 0.08);
      
      final Path glowPath = Path();
      glowPath.moveTo(w * 0.15, h * 0.15);
      glowPath.lineTo(w * 0.45, h * 0.85);
      glowPath.lineTo(w * 0.45, h * 0.15);
      canvas.drawPath(glowPath, glowPaint);
    }

    // 1. Draw "V" Left Diagonal & Center spine
    final Path vPath = Path();
    vPath.moveTo(w * 0.15, h * 0.15);
    vPath.lineTo(w * 0.45, h * 0.85);
    vPath.lineTo(w * 0.45, h * 0.15); // Monogram vertical spine of "D"
    canvas.drawPath(vPath, linePaint);

    // 2. Draw "D" Outer vault arch
    final Path dPath = Path();
    dPath.moveTo(w * 0.45, h * 0.15);
    // Sophisticated safe door arch curve
    dPath.cubicTo(
      w * 0.95, h * 0.15,
      w * 0.95, h * 0.85,
      w * 0.45, h * 0.85,
    );
    canvas.drawPath(dPath, curvePaint);
  }

  @override
  bool shouldRepaint(covariant _DueVaultLogoPainter oldDelegate) {
    return oldDelegate.showGlow != showGlow;
  }
}
