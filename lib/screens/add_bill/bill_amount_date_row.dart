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

  const BillAmountDateRow({
    super.key,
    required this.amountController,
    required this.dueDate,
    required this.currencyCode,
    required this.onDateTap,
    this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
                ),
                validator: (value) => ValidationHelper.validateAmount(value, isRequired: true),
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
        Expanded(
          child: BentoInputWrapper(
            label: 'DUE DATE',
            child: InkWell(
              onTap: onDateTap,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
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
    );
  }
}
