import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class BillDateRecurrenceCard extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onDateTap;
  final ValueChanged<DateTime>? onQuickDateSelected;
  final String recurrence;
  final ValueChanged<String?> onRecurrenceChanged;
  final bool directDebit;
  final ValueChanged<bool> onDirectDebitChanged;

  const BillDateRecurrenceCard({
    super.key,
    required this.dueDate,
    required this.onDateTap,
    this.onQuickDateSelected,
    required this.recurrence,
    required this.onRecurrenceChanged,
    required this.directDebit,
    required this.onDirectDebitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final in3Days = today.add(const Duration(days: 3));
    final nextWeek = today.add(const Duration(days: 7));
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    const recurrenceOptions = ['None', 'Weekly', 'Monthly', 'Yearly'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border(isDark),
          width: 1.0,
        ),
        boxShadow: !isDark ? AppShadows.sm : null,
      ),
      padding: AppSpacing.cardPaddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DUE DATE SECTION
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                'DUE DATE',
                style: AppTypography.labelCaps(AppColors.textSecondary(isDark)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),

          // Date Selector Button
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onDateTap();
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated(isDark),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border(isDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 18,
                        color: dueDate != null
                            ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
                            : AppColors.textSecondary(isDark),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Text(
                        dueDate != null
                            ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                            : 'Select Date',
                        style: TextStyle(
                          color: dueDate != null
                              ? AppColors.textPrimary(isDark)
                              : AppColors.textMuted(isDark),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textSecondary(isDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),

          // Quick Date Pills
          Row(
            children: [
              _QuickDatePill(
                label: 'In 3 days',
                date: in3Days,
                isSelected: dueDate != null &&
                    dueDate!.year == in3Days.year &&
                    dueDate!.month == in3Days.month &&
                    dueDate!.day == in3Days.day,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onQuickDateSelected?.call(in3Days);
                },
              ),
              const SizedBox(width: 6),
              _QuickDatePill(
                label: 'Next week',
                date: nextWeek,
                isSelected: dueDate != null &&
                    dueDate!.year == nextWeek.year &&
                    dueDate!.month == nextWeek.month &&
                    dueDate!.day == nextWeek.day,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onQuickDateSelected?.call(nextWeek);
                },
              ),
              const SizedBox(width: 6),
              _QuickDatePill(
                label: 'End of month',
                date: endOfMonth,
                isSelected: dueDate != null &&
                    dueDate!.year == endOfMonth.year &&
                    dueDate!.month == endOfMonth.month &&
                    dueDate!.day == endOfMonth.day,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onQuickDateSelected?.call(endOfMonth);
                },
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(
              color: AppColors.border(isDark),
              height: 1,
              thickness: 1,
            ),
          ),

          // 2. RECURRENCE SECTION
          Row(
            children: [
              Icon(
                Icons.repeat_rounded,
                size: 14,
                color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                'RECURRENCE',
                style: AppTypography.labelCaps(AppColors.textSecondary(isDark)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),

          // Recurrence Chips
          Row(
            children: recurrenceOptions.map((opt) {
              final isSelected = recurrence == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onRecurrenceChanged(opt);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.emerald500.withValues(alpha: isDark ? 0.18 : 0.12)
                            : AppColors.surfaceElevated(isDark),
                        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
                              : AppColors.border(isDark),
                          width: isSelected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? AppColors.emerald400 : AppColors.emerald700)
                              : AppColors.textSecondary(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(
              color: AppColors.border(isDark),
              height: 1,
              thickness: 1,
            ),
          ),

          // 3. AUTO-PAY ROW
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: directDebit
                      ? AppColors.emerald500.withValues(alpha: isDark ? 0.18 : 0.12)
                      : AppColors.surfaceElevated(isDark),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: directDebit
                        ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
                        : AppColors.border(isDark),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: directDebit
                      ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
                      : AppColors.textSecondary(isDark),
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Pay (Funds Reserved)',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Money is set aside in your bank account',
                      style: AppTypography.caption(AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: directDebit,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  onDirectDebitChanged(val);
                },
                activeThumbColor: isDark ? AppColors.emerald400 : AppColors.emerald600,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickDatePill extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDatePill({
    required this.label,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.emerald500.withValues(alpha: isDark ? 0.18 : 0.12)
                : AppColors.surfaceElevated(isDark),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
                  : AppColors.border(isDark),
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppColors.emerald400 : AppColors.emerald700)
                  : AppColors.textSecondary(isDark),
            ),
          ),
        ),
      ),
    );
  }
}
