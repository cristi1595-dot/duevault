import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/validation_helper.dart';

class BillHeroAmountInput extends StatelessWidget {
  final TextEditingController amountController;
  final String currencyCode;
  final String currencySymbol;
  final ValueChanged<String>? onAmountChanged;

  const BillHeroAmountInput({
    super.key,
    required this.amountController,
    required this.currencyCode,
    required this.currencySymbol,
    this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF222F48),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header pill: BILL AMOUNT + Currency Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2838),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF222F48)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.payments_rounded,
                  size: 13,
                  color: AppTheme.primaryAction,
                ),
                const SizedBox(width: 6),
                Text(
                  'AMOUNT • $currencyCode',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Centered Revolut-style Hero input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                currencySymbol,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 70, maxWidth: 260),
                  child: TextFormField(
                    key: const Key('bill_amount_field'),
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    cursorColor: AppTheme.primaryAction,
                    inputFormatters: [AmountInputFormatter()],
                    validator: (value) =>
                        ValidationHelper.validateAmount(value, isRequired: true),
                    onChanged: onAmountChanged,
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                        letterSpacing: -0.5,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
