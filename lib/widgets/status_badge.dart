import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final int? daysLeft;
  final bool isPaid;
  final bool isDocument;

  const StatusBadge({
    super.key,
    required this.label,
    this.daysLeft,
    this.isPaid = false,
    this.isDocument = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;

    if (isPaid) {
      textColor = AppTheme.getMintGreen(context); // Elegant Mint Sage
    } else if (label == 'EXPIRED' || label == 'OVERDUE' || (daysLeft != null && daysLeft! <= 3)) {
      textColor = const Color(0xFFE11D48); // Red: under 3 days or overdue
    } else if (daysLeft != null && daysLeft! <= 7) {
      textColor = const Color(0xFFF59E0B); // Yellow/Amber: 4 to 7 days
    } else if (label == 'PERMANENT' || label == 'RENEWED') {
      textColor = AppTheme.getMintGreen(context); // Valid Green
    } else {
      textColor = AppTheme.getSafeGreen(context); // Green: over 7 days
    }

    final Color bgColor = textColor.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: isDocument ? 10.5 : 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
