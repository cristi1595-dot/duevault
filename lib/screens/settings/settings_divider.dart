import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// A standardized inset divider for multi-row Bento cards in Settings.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: AppSpacing.base + 38 + AppSpacing.md, // 66px: aligns with title start
      endIndent: AppSpacing.base,
      color: AppColors.border(isDark).withValues(alpha: 0.5),
    );
  }
}
