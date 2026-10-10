import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// DueVault StatusBadge Component
/// WCAG AA compliant badge for bill & document deadlines, payment states, and tags.
class StatusBadge extends StatelessWidget {
  final String label;
  final int? daysLeft;
  final bool isPaid;
  final bool isDocument;
  final bool? showDot;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.daysLeft,
    this.isPaid = false,
    this.isDocument = false,
    this.showDot,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color textColor;
    final normalized = label.trim().toUpperCase();

    if (isPaid) {
      textColor = AppColors.statusSafeText(isDark);
    } else if (normalized == 'EXPIRED' ||
        normalized == 'OVERDUE' ||
        (daysLeft != null && daysLeft! <= 3)) {
      textColor = AppColors.statusUrgentText(isDark);
    } else if (daysLeft != null && daysLeft! <= 7) {
      textColor = AppColors.statusWarningText(isDark);
    } else if (normalized == 'PERMANENT' || normalized == 'RENEWED') {
      textColor = isDark ? AppColors.infoBlue400 : AppColors.infoBlue700;
    } else {
      textColor = AppColors.statusSafeText(isDark);
    }

    final Color bgColor = textColor.withValues(alpha: isDark ? 0.12 : 0.09);
    final bool shouldShowDot = showDot ??
        (normalized == 'EXPIRED' || normalized == 'OVERDUE' || (daysLeft != null && daysLeft! <= 3));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: textColor.withValues(alpha: isDark ? 0.25 : 0.2),
          width: 0.75,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ] else if (shouldShowDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4.5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: isDocument ? 10.5 : 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
