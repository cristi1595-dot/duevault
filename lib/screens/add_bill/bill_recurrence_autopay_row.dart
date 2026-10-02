import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../add_shared/bento_input_wrapper.dart';

class BillRecurrenceAutoPayRow extends StatelessWidget {
  final String recurrence;
  final bool directDebit;
  final ValueChanged<String?> onRecurrenceChanged;
  final ValueChanged<bool> onDirectDebitChanged;

  const BillRecurrenceAutoPayRow({
    super.key,
    required this.recurrence,
    required this.directDebit,
    required this.onRecurrenceChanged,
    required this.onDirectDebitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Recurrence
        BentoInputWrapper(
          label: 'RECURRENCE',
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: DropdownButton<String>(
              value: recurrence,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              dropdownColor: Theme.of(context).cardTheme.color,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              items: ['None', 'Weekly', 'Monthly', 'Yearly'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onRecurrenceChanged,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Auto-Pay with clear explanation (Funds Reserved)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: directDebit
                ? AppTheme.primaryAction.withValues(alpha: isDark ? 0.08 : 0.05)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: directDebit
                  ? AppTheme.primaryAction.withValues(alpha: 0.35)
                  : Theme.of(context).dividerColor,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: directDebit
                      ? AppTheme.primaryAction.withValues(alpha: 0.15)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: directDebit
                      ? AppTheme.primaryAction
                      : Theme.of(context).textTheme.bodySmall?.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Pay (Funds Reserved)',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Money is set aside in your bank account',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
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
        ),
      ],
    );
  }
}
