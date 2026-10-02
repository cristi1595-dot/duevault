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
    final options = ['None', 'Weekly', 'Monthly', 'Yearly'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recurrence Chips
        BentoInputWrapper(
          label: 'RECURRENCE',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: options.map((opt) {
                final isSelected = recurrence == opt;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => onRecurrenceChanged(opt),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryAction.withValues(alpha: 0.2)
                              : (isDark
                                  ? const Color(0xFF1B202A)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryAction
                                : (isDark
                                    ? const Color(0xFF2D333D)
                                    : const Color(0xFFE2E8F0)),
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
                                : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
