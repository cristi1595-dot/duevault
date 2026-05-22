import 'package:flutter/material.dart';

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
      textColor = const Color(0xFF34D399); // Elegant Mint Sage
    } else if (label == 'EXPIRED' || (daysLeft != null && daysLeft! <= 3)) {
      textColor = const Color(0xFFE11D48); // Crimson Coral
    } else if (daysLeft != null && daysLeft! <= 7) {
      textColor = const Color(0xFFF59E0B); // Warm Amber
    } else if (label == 'PERMANENT' || label == 'RENEWED') {
      textColor = const Color(0xFF34D399); // Valid Green
    } else {
      textColor = const Color(0xFF10B981); // Green (safe zone > 7 days)
    }

    final Color bgColor = textColor.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: isDocument ? 10.5 : 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
