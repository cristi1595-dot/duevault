import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Quick Validity Chips for AddDocumentScreen:
/// Offers presets: 6 Months, 1 Year, 5 Years, 10 Years.
class DocumentValidityChips extends StatelessWidget {
  final DateTime? selectedDate;
  final bool isDark;
  final ValueChanged<DateTime> onValiditySelected;

  const DocumentValidityChips({
    super.key,
    required this.selectedDate,
    required this.isDark,
    required this.onValiditySelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final presets = [
      (
        label: '6 Months',
        targetDate: DateTime(now.year, now.month + 6, now.day),
      ),
      (
        label: '1 Year',
        targetDate: DateTime(now.year + 1, now.month, now.day),
      ),
      (
        label: '5 Years',
        targetDate: DateTime(now.year + 5, now.month, now.day),
      ),
      (
        label: '10 Years',
        targetDate: DateTime(now.year + 10, now.month, now.day),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < presets.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs + 2),
            _buildChip(
              context,
              label: presets[i].label,
              targetDate: presets[i].targetDate,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required DateTime targetDate,
  }) {
    final isSelected = selectedDate != null &&
        selectedDate!.year == targetDate.year &&
        selectedDate!.month == targetDate.month &&
        selectedDate!.day == targetDate.day;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onValiditySelected(targetDate);
      },
      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.violet500.withValues(alpha: isDark ? 0.2 : 0.12)
              : AppColors.surfaceElevated(isDark),
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.violet400 : AppColors.violet600)
                : AppColors.border(isDark),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.violet400 : AppColors.violet600)
                : AppColors.textSecondary(isDark),
          ),
        ),
      ),
    );
  }
}
