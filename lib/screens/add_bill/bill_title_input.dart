import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/validation_helper.dart';
import '../add_shared/bento_input_wrapper.dart';

/// Bill Title Input component for AddBillScreen.
class BillTitleInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const BillTitleInput({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BentoInputWrapper(
      label: 'BILL TITLE',
      icon: Icons.edit_note_rounded,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: 4,
        ),
        child: TextFormField(
          key: const Key('bill_title_field'),
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Electricity, Rent, Internet',
            hintStyle: TextStyle(
              color: AppColors.textMuted(isDark),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            isDense: true,
          ),
          onChanged: onChanged,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          validator: (value) => ValidationHelper.validateTitle(value),
        ),
      ),
    );
  }
}
