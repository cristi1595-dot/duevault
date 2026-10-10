import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// DueVault SecondaryButton Component
/// Tonal/outlined secondary action button with matching touch target and curvature.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double? width;
  final double borderRadius;
  final Color? borderColor;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52.0,
    this.width,
    this.borderRadius = AppRadius.lg,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardTheme.color ??
        (isDark ? AppColors.slate850 : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? AppColors.slate50 : AppColors.slate900);
    final border = borderColor ??
        (isDark ? Theme.of(context).dividerColor : AppColors.slate300);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: surfaceColor,
          foregroundColor: textColor,
          side: BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
