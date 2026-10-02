import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/validation_helper.dart';
import '../add_shared/bento_input_wrapper.dart';

class BillAmountDateRow extends StatelessWidget {
  final TextEditingController amountController;
  final DateTime? dueDate;
  final String currencyCode;
  final VoidCallback onDateTap;
  final ValueChanged<String>? onAmountChanged;
  final ValueChanged<DateTime>? onQuickDateSelected;

  const BillAmountDateRow({
    super.key,
    required this.amountController,
    required this.dueDate,
    required this.currencyCode,
    required this.onDateTap,
    this.onAmountChanged,
    this.onQuickDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final in3Days = today.add(const Duration(days: 3));
    final nextWeek = today.add(const Duration(days: 7));
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Amount
            Expanded(
              child: BentoInputWrapper(
                label: 'AMOUNT ($currencyCode)',
                child: SizedBox(
                  height: 38,
                  child: TextFormField(
                    controller: amountController,
                    onChanged: onAmountChanged,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                    validator: (value) =>
                        ValidationHelper.validateAmount(value, isRequired: true),
                    inputFormatters: [
                      AmountInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 10,
                        bottom: 8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Due Date
            Expanded(
              child: BentoInputWrapper(
                label: 'DUE DATE',
                child: InkWell(
                  onTap: onDateTap,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dueDate != null
                              ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                              : 'Select',
                          style: TextStyle(
                            color: dueDate != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryAction,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick Date Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDateChip(context, label: 'Today', targetDate: today),
              const SizedBox(width: 6),
              _buildDateChip(context, label: 'In 3 days', targetDate: in3Days),
              const SizedBox(width: 6),
              _buildDateChip(context, label: 'Next week', targetDate: nextWeek),
              const SizedBox(width: 6),
              _buildDateChip(context, label: 'End of month', targetDate: endOfMonth),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(
    BuildContext context, {
    required String label,
    required DateTime targetDate,
  }) {
    final isSelected = dueDate != null &&
        dueDate!.year == targetDate.year &&
        dueDate!.month == targetDate.month &&
        dueDate!.day == targetDate.day;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        if (onQuickDateSelected != null) {
          onQuickDateSelected!(targetDate);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryAction.withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF1B202A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAction
                : (isDark ? const Color(0xFF2D333D) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppTheme.primaryAction
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
