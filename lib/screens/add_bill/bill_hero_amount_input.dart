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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.border(isDark),
          width: 1.0,
        ),
        boxShadow: !isDark ? AppShadows.sm : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header pill: AMOUNT • Currency Code
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated(isDark),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.border(isDark),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.payments_rounded,
                  size: 13,
                  color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  'AMOUNT • $currencyCode',
                  style: AppTypography.labelCaps(AppColors.textSecondary(isDark)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Centered Revolut-style Hero input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                currencySymbol,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
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
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(isDark),
                      letterSpacing: -0.5,
                    ),
                    cursorColor: isDark ? AppColors.emerald400 : AppColors.emerald600,
                    inputFormatters: [AmountInputFormatter()],
                    validator: (value) =>
                        ValidationHelper.validateAmount(value, isRequired: true),
                    onChanged: onAmountChanged,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted(isDark),
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
