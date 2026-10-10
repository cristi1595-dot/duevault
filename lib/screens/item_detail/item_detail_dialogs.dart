import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ItemDetailDialogs {
  static Future<bool?> showDeleteAttachmentDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border(isDark), width: 1.0),
        ),
        title: Text(
          'Delete Attachment',
          style: AppTypography.titleMedium(AppColors.textPrimary(isDark)).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this file?',
          style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.statusUrgentText(isDark),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showDeleteItemDialog(BuildContext context, String itemTitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border(isDark), width: 1.0),
        ),
        title: Text(
          'Delete Item',
          style: AppTypography.titleMedium(AppColors.textPrimary(isDark)).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$itemTitle"? This action cannot be undone.',
          style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.statusUrgentText(isDark),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
