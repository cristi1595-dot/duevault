import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Group Section Header with icon, uppercase title, and count badge pill.
class VaultSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final bool isDark;
  final IconData icon;
  final String singularSuffix;
  final String pluralSuffix;

  const VaultSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.isDark,
    required this.icon,
    this.singularSuffix = 'item',
    this.pluralSuffix = 'items',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.base,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title.toUpperCase(),
                style: AppTypography.labelCaps(AppColors.textSecondary(isDark)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 0.75,
              ),
            ),
            child: Text(
              '$count ${count == 1 ? singularSuffix : pluralSuffix}',
              style: AppTypography.caption(color).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
