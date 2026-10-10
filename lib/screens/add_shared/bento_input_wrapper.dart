import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BentoInputWrapper extends StatelessWidget {
  final String label;
  final Widget child;
  final IconData? icon;

  const BentoInputWrapper({
    super.key,
    required this.label,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Text(
                label.toUpperCase(),
                style: AppTypography.labelCaps(AppColors.textSecondary(isDark)),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface(isDark),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.border(isDark),
              width: 1.0,
            ),
            boxShadow: !isDark ? AppShadows.sm : null,
          ),
          child: child,
        ),
      ],
    );
  }
}
