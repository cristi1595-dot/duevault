import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// DueVault PrimaryButton Component
/// High-contrast, accessibility-first primary action button with loading states.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double? width;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isDestructive;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52.0,
    this.width,
    this.borderRadius = AppRadius.lg,
    this.backgroundColor,
    this.foregroundColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color defaultBg;
    if (isDestructive) {
      defaultBg = isDark ? AppColors.urgentRose600 : AppColors.urgentRose700;
    } else {
      defaultBg = isDark ? AppColors.emerald500 : AppColors.emerald600;
    }

    final effectiveBg = backgroundColor ?? defaultBg;
    final effectiveFg = foregroundColor ?? Colors.white;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveFg,
          disabledBackgroundColor: effectiveBg.withValues(alpha: 0.35),
          disabledForegroundColor: effectiveFg.withValues(alpha: 0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: effectiveFg,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: effectiveFg),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: effectiveFg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
