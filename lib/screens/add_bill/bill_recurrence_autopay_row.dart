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
    return Row(
      children: [
        // Recurrence (50%)
        Expanded(
          child: BentoInputWrapper(
            label: 'RECURRENCE',
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
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
                  fontSize: 19,
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
        ),
        const SizedBox(width: 12),
        // Direct Debit (50%)
        Expanded(
          child: BentoInputWrapper(
            label: 'AUTO-PAY',
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          color: directDebit
                              ? AppTheme.primaryAction
                              : Theme.of(context).textTheme.bodySmall?.color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Direct Debit',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
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
          ),
        ),
      ],
    );
  }
}
