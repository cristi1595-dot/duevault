import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

/// Prompts confirmation for clearing local cached attachments.
Future<bool?> showClearCacheConfirmDialog(BuildContext context, bool isPro) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: AppColors.border(isDark)),
      ),
      title: Text(
        'Clear Local Cache',
        style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
      ),
      content: Text(
        isPro
            ? 'This will delete local downloaded attached files/images from this phone to free up space. You can download them again from Google Drive when viewing them. Your bills and documents list will remain.'
            : 'This will permanently delete all local attached files/images from this phone. Your bills and documents list will remain.',
        style: TextStyle(color: AppColors.textSecondary(isDark)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(ctx, false);
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary(isDark)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(ctx, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.urgentRose600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: const Text(
            'CLEAR CACHE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

/// Prompts confirmation for wiping all phone and cloud data.
Future<bool?> showWipeEverythingConfirmDialog(BuildContext context, bool isPro) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: AppColors.border(isDark)),
      ),
      title: Text(
        'WIPE EVERYTHING',
        style: AppTypography.headlineMedium(AppColors.urgentRose600),
      ),
      content: Text(
        isPro
            ? 'WARNING: This will permanently delete ALL local data AND your Google Drive backup. This cannot be undone.'
            : 'WARNING: This will permanently delete ALL local data from this device. This cannot be undone.',
        style: TextStyle(color: AppColors.textSecondary(isDark)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(ctx, false);
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary(isDark)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(ctx, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.urgentRose600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(
            isPro ? 'ERASE CLOUD & PHONE' : 'ERASE ALL LOCAL DATA',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

/// Prompts confirmation for deleting the account and cloud backups permanently.
Future<bool?> showDeleteAccountConfirmDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: AppColors.border(isDark)),
      ),
      title: Text(
        'DELETE ACCOUNT',
        style: AppTypography.headlineMedium(AppColors.urgentRose600),
      ),
      content: Text(
        'WARNING: This is permanent and irreversible. This will delete all your local data, your Google Drive backup, your Firestore database records, and permanently close your account registration. You will be logged out completely.',
        style: TextStyle(color: AppColors.textSecondary(isDark)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(ctx, false);
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary(isDark)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(ctx, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.urgentRose600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: const Text(
            'DELETE ACCOUNT & DATA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
