import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../add_shared/bento_input_wrapper.dart';

/// Expiry and Renewal Date picker wrapper for AddDocumentScreen.
class DocumentExpiryPicker extends StatelessWidget {
  final DateTime? expiryDate;
  final bool isDark;
  final VoidCallback onTap;

  const DocumentExpiryPicker({
    super.key,
    required this.expiryDate,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BentoInputWrapper(
      label: 'EXPIRY / RENEWAL DATE',
      icon: Icons.calendar_today_rounded,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                expiryDate != null
                    ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
                    : 'Select Date',
                style: TextStyle(
                  color: expiryDate != null
                      ? AppColors.textPrimary(isDark)
                      : AppColors.textMuted(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.calendar_today,
                color: isDark ? AppColors.violet400 : AppColors.violet600,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
