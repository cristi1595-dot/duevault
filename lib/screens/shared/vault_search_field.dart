import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Reusable tokenized search field for vault screens.
class VaultSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String query;
  final bool isDark;
  final Color focusColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const VaultSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.query,
    required this.isDark,
    required this.focusColor,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        color: AppColors.textPrimary(isDark),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.textSecondary(isDark).withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 20,
          color: AppColors.textSecondary(isDark),
        ),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onClear();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceElevated(isDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: AppColors.border(isDark),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: AppColors.border(isDark),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: focusColor,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
