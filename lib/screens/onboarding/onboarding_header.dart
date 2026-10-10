import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/duevault_logo.dart';

class OnboardingHeader extends StatelessWidget {
  final String? subtitle;
  final double logoSize;

  const OnboardingHeader({
    super.key,
    this.subtitle,
    this.logoSize = 88,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DueVaultLogo(
          size: logoSize,
          showGlow: true,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Due',
              style: AppTypography.displayLarge(AppColors.textPrimary(isDark)).copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            Text(
              'Vault',
              style: AppTypography.displayLarge(AppColors.emerald500).copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)),
          ),
        ],
      ],
    );
  }
}
