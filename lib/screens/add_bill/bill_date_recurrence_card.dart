import 'package:flutter/material.dart';
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final in3Days = today.add(const Duration(days: 3));
    final nextWeek = today.add(const Duration(days: 7));
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    const recurrenceOptions = ['None', 'Weekly', 'Monthly', 'Yearly'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF222F48),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DUE DATE SECTION
          const Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppTheme.primaryAction,
              ),
              SizedBox(width: 6),
              Text(
                'DUE DATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date Selector Button
          InkWell(
            onTap: onDateTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2838),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222F48)),
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
                            ? AppTheme.primaryAction
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dueDate != null
                            ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                            : 'Select',
                        style: TextStyle(
                          color: dueDate != null
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

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
                onTap: () => onQuickDateSelected?.call(in3Days),
              ),
              const SizedBox(width: 6),
              _QuickDatePill(
                label: 'Next week',
                date: nextWeek,
                isSelected: dueDate != null &&
                    dueDate!.year == nextWeek.year &&
                    dueDate!.month == nextWeek.month &&
                    dueDate!.day == nextWeek.day,
                onTap: () => onQuickDateSelected?.call(nextWeek),
              ),
              const SizedBox(width: 6),
              _QuickDatePill(
                label: 'End of month',
                date: endOfMonth,
                isSelected: dueDate != null &&
                    dueDate!.year == endOfMonth.year &&
                    dueDate!.month == endOfMonth.month &&
                    dueDate!.day == endOfMonth.day,
                onTap: () => onQuickDateSelected?.call(endOfMonth),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              color: Color(0xFF222F48),
              height: 1,
              thickness: 1,
            ),
          ),

          // 2. RECURRENCE SECTION
          const Row(
            children: [
              Icon(
                Icons.repeat_rounded,
                size: 14,
                color: AppTheme.primaryAction,
              ),
              SizedBox(width: 6),
              Text(
                'RECURRENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Recurrence Chips
          Row(
            children: recurrenceOptions.map((opt) {
              final isSelected = recurrence == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => onRecurrenceChanged(opt),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryAction.withValues(alpha: 0.16)
                            : const Color(0xFF1E2838),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryAction
                              : const Color(0xFF222F48),
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
                              ? AppTheme.primaryAction
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              color: Color(0xFF222F48),
              height: 1,
              thickness: 1,
            ),
          ),

          // 3. AUTO-PAY ROW
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: directDebit
                      ? AppTheme.primaryAction.withValues(alpha: 0.15)
                      : const Color(0xFF1E2838),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: directDebit
                      ? AppTheme.primaryAction
                      : const Color(0xFF94A3B8),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Pay (Funds Reserved)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Money is set aside in your bank account',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: directDebit,
                onChanged: onDirectDebitChanged,
                activeThumbColor: AppTheme.primaryAction,
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryAction.withValues(alpha: 0.16)
                : const Color(0xFF1E2838),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryAction
                  : const Color(0xFF222F48),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppTheme.primaryAction
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}
