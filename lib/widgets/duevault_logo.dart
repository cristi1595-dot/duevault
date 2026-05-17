import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
                  color: AppTheme.safeGreen.withValues(alpha: 0.15),
                  blurRadius: size * 0.25,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1B1F26), // AppTheme.darkSurface
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Futuristic 3D Tilted Document Stack & Glowing Jewel Shield
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DueVaultLogoPainter(
                      gradientStart: const ui.Color(0xFF10B981), // Emerald Mint
                      gradientEnd: const ui.Color(0xFF3B82F6),   // Royal Blue
                      showGlow: showGlow,
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

class _DueVaultLogoPainter extends CustomPainter {
  final ui.Color gradientStart;
  final ui.Color gradientEnd;
  final bool showGlow;

  _DueVaultLogoPainter({
    required this.gradientStart,
    required this.gradientEnd,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Center of canvas
    final Offset center = Offset(w * 0.5, h * 0.5);

    // 1. Draw Time Dial / Orbit (subtle circular track representing time progression)
    final Paint orbitPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015;
    
    canvas.drawCircle(center, w * 0.38, orbitPaint);

    final Paint arcPaint = Paint()
      ..color = gradientEnd.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: w * 0.38),
      -1.57, // Start from the top (~ -90 degrees)
      1.8,   // Sweep arc length
      false,
      arcPaint,
    );

    // Dimensions of cards
    final double cardW = w * 0.36;
    final double cardH = h * 0.44;

    // 2. Draw Back Document Card (Cascading depth layer)
    canvas.save();
    // Shift left and up, rotate by -11 degrees
    canvas.translate(w * 0.41, h * 0.42);
    canvas.rotate(-0.19); // -11 degrees in radians

    final RRect backRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH),
      Radius.circular(w * 0.05),
    );

    // Subtle translucent fill
    final Paint backFillPaint = Paint()
      ..color = const Color(0xFF171A21).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(backRRect, backFillPaint);

    // Subtle border
    final Paint backBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(backRRect, backBorderPaint);

    canvas.restore();

    // 3. Draw Front Document Card (The "D" Shape & Main Invoice Metaphor)
    canvas.save();
    // Shift slightly down and right, rotate by -5 degrees
    canvas.translate(w * 0.46, h * 0.46);
    canvas.rotate(-0.08); // -5 degrees in radians

    final RRect frontRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH),
      Radius.circular(w * 0.05),
    );

    // Glow under the front card
    if (showGlow) {
      final Paint cardGlowPaint = Paint()
        ..color = gradientStart.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: w * 0.06,
          sigmaY: w * 0.06,
        );
      canvas.drawRRect(frontRRect, cardGlowPaint);
    }

    // Card background fill with satin gloss gradient reflection (obsidian metallic feel)
    final Paint cardFillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-cardW * 0.5, -cardH * 0.5),
        Offset(cardW * 0.5, cardH * 0.5),
        const [
          Color(0xFF13161C), // Deep black-blue
          Color(0xFF222731), // Satin light gloss band
          Color(0xFF13161C), // Deep black-blue
        ],
        const [0.0, 0.45, 1.0],
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(frontRRect, cardFillPaint);

    // Card Border (Fine premium gradient border)
    final Paint cardBorderPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-cardW * 0.5, -cardH * 0.5),
        Offset(cardW * 0.5, cardH * 0.5),
        [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.04)],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(frontRRect, cardBorderPaint);

    // 4. Draw Invoice Details inside the Front Card (Rotated perfectly with the card)
    // Glowing Title line
    final Paint titlePaint = Paint()
      ..color = gradientEnd // Royal Blue / Cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-cardW * 0.32, -cardH * 0.30),
      Offset(cardW * 0.02, -cardH * 0.30),
      titlePaint,
    );

    // Tiny Active Alert Badge on the document
    final Paint alertBadgePaint = Paint()
      ..color = gradientStart // Mint Green
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cardW * 0.26, -cardH * 0.30), w * 0.02, alertBadgePaint);

    // Breakdown lines
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015
      ..strokeCap = StrokeCap.round;

    // Line 1
    canvas.drawLine(
      Offset(-cardW * 0.32, -cardH * 0.12),
      Offset(cardW * 0.30, -cardH * 0.12),
      linePaint,
    );
    // Line 2
    canvas.drawLine(
      Offset(-cardW * 0.32, cardH * 0.04),
      Offset(cardW * 0.20, cardH * 0.04),
      linePaint,
    );
    // Line 3
    canvas.drawLine(
      Offset(-cardW * 0.32, cardH * 0.20),
      Offset(-cardW * 0.02, cardH * 0.20),
      linePaint,
    );

    canvas.restore();

    // 5. Draw the Protective Shield (The "V" Shape & Security Metaphor)
    // Drawn in global coords (unrotated) to anchor the entire layout visually
    final double cx = w * 0.67;
    final double cy = h * 0.65;
    final double r = w * 0.18; // Slightly larger for extra prominence

    final Path shieldPath = Path();
    shieldPath.moveTo(cx, cy - r); // Top center
    // Curve to top-right
    shieldPath.quadraticBezierTo(cx + r * 0.85, cy - r * 0.9, cx + r * 0.85, cy - r * 0.2);
    // Curve to bottom point (Creating the beautiful pointed V vertex)
    shieldPath.quadraticBezierTo(cx + r * 0.85, cy + r * 0.5, cx, cy + r);
    // Curve to bottom-left
    shieldPath.quadraticBezierTo(cx - r * 0.85, cy + r * 0.5, cx - r * 0.85, cy - r * 0.2);
    // Curve to top-left
    shieldPath.quadraticBezierTo(cx - r * 0.85, cy - r * 0.9, cx, cy - r);
    shieldPath.close();

    // Shield Halo Glow
    if (showGlow) {
      final Paint shieldGlowPaint = Paint()
        ..color = gradientStart.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: w * 0.04,
          sigmaY: w * 0.04,
        );
      canvas.drawPath(shieldPath, shieldGlowPaint);
    }

    // Shield Fill - Beautiful 3D Gradient (Emerald to Forest green) for jeweled dome effect
    final Paint shieldFillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, cy - r),
        Offset(cx, cy + r),
        const [
          Color(0xFF10B981), // Glowing Emerald
          Color(0xFF047857), // Deep Secure Green
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldFillPaint);

    // Shield Dark inner border for maximum premium contrast
    final Paint shieldBorderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(shieldPath, shieldBorderPaint);

    // 6. Draw the White Checkmark inside the Shield (Completion & Safety)
    final Paint checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18
      ..strokeCap = StrokeCap.round;
    
    final Path checkPath = Path();
    checkPath.moveTo(cx - r * 0.35, cy - r * 0.02);
    checkPath.lineTo(cx - r * 0.05, cy + r * 0.28);
    checkPath.lineTo(cx + r * 0.35, cy - r * 0.25);
    
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _DueVaultLogoPainter oldDelegate) {
    return oldDelegate.gradientStart != gradientStart ||
        oldDelegate.gradientEnd != gradientEnd ||
        oldDelegate.showGlow != showGlow;
  }
}
