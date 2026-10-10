import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// DueVault BentoCard Component
/// Modern fintech card container featuring subtle borders, optional interaction,
/// and theme-adaptive elevation.
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;

  const BentoCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius = AppRadius.lg,
    this.color,
    this.borderColor,
    this.onTap,
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = color ?? (isDark ? AppColors.slate850 : Colors.white);
    final cardBorder = borderColor ??
        (isDark
            ? Theme.of(context).dividerColor.withValues(alpha: 0.5)
            : AppColors.slate200);

    final defaultShadows = isDark ? null : AppShadows.sm;

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: cardBorder,
          width: 1,
        ),
        boxShadow: shadows ?? defaultShadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.emerald500.withValues(alpha: 0.08),
          highlightColor: AppColors.emerald500.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return content;
  }
}
