import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// DueVault CustomInputField Component
/// Accessible, form-integrated input with WCAG visible focus indicators,
/// error styling, and label hierarchy.
class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? hintText;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final AutovalidateMode? autovalidateMode;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const CustomInputField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.hintText,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.autovalidateMode,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.slate800.withValues(alpha: 0.6)
        : AppColors.slate100.withValues(alpha: 0.7);

    final borderNormal = isDark
        ? Theme.of(context).dividerColor.withValues(alpha: 0.7)
        : AppColors.slate200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.labelCapsStyle(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.sentences,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          autovalidateMode: autovalidateMode,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: surfaceColor,
            hintText: hintText,
            prefixIcon: prefix,
            suffixIcon: suffix,
            hintStyle: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.55),
              fontSize: 15,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: borderNormal, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(
                color: AppColors.emerald500,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(
                color: AppColors.urgentRose600,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(
                color: AppColors.urgentRose600,
                width: 2,
              ),
            ),
            errorStyle: const TextStyle(
              color: AppColors.urgentRose500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
