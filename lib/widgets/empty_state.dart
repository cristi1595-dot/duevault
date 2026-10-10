import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

/// DueVault EmptyState Component
/// Visual feedback when lists or vaults have zero items, with optional CTA button.
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.title = 'Your vault is empty',
    this.subtitle = 'Tap + to add your first document or bill.',
    this.icon = Icons.inventory_2_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing neon icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: isDark ? 0.05 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: isDark ? 0.2 : 0.35),
                  width: 1.5,
                ),
                boxShadow: isDark
                    ? AppShadows.darkEmeraldGlow(opacity: 0.15)
                    : null,
              ),
              child: Icon(
                icon,
                size: 52,
                color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Headline
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: -0.2,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Subtitle
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                    fontSize: 14,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 200,
                child: PrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  height: 46,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
