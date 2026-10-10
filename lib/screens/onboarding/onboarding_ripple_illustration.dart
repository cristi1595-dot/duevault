import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Reusable concentric ripple illustration used across onboarding pages.
/// Displays an ambient glowing background, two ripple rings, and a central icon cap.
class OnboardingRippleIllustration extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const OnboardingRippleIllustration({
    super.key,
    required this.color,
    required this.icon,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glowSize = size;
    final outerRing = size * 0.75;
    final innerRing = size * 0.58;
    final iconCapSize = size * 0.42;

    return SizedBox(
      width: glowSize,
      height: glowSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Radial Ambient Glow
          Container(
            width: glowSize,
            height: glowSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: isDark ? 0.16 : 0.12),
                  color.withValues(alpha: isDark ? 0.05 : 0.03),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Outer Ripple Ring
          Container(
            width: outerRing,
            height: outerRing,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.15 : 0.2),
                width: 1.0,
              ),
            ),
          ),
          // Inner Ripple Ring
          Container(
            width: innerRing,
            height: innerRing,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.28 : 0.35),
                width: 1.4,
              ),
            ),
          ),
          // Core Icon Cap with Glassmorphic Surface
          Container(
            width: iconCapSize,
            height: iconCapSize,
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.45 : 0.55),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.15),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconCapSize * 0.48,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
