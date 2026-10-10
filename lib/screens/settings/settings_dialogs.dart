import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import '../../providers/security_provider.dart';

/// Centralized confirmation dialogs used across the Settings screen.
///
/// All dialogs are extracted here to keep the Settings screen focused on
/// layout orchestration rather than inline dialog construction.
class SettingsDialogs {
  SettingsDialogs._();

  /// Dialog shown when notification permission is denied.
  /// Directs user to system app settings and optionally to battery optimization.
  static Future<void> showAppSettingsDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: AppColors.border(isDark)),
        ),
        title: Text(
          'Notifications Disabled',
          style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
        ),
        content: Text(
          'To enable global reminders, please allow notifications for DueVault in your device settings.',
          style: TextStyle(color: AppColors.textSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await HapticFeedback.lightImpact();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.emerald500 : AppColors.emerald600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Sign-out confirmation dialog.
  /// Returns `true` if the user confirmed sign-out.
  static Future<bool?> showSignOutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: AppColors.border(isDark)),
        ),
        title: Text(
          'Sign Out',
          style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
        ),
        content: Text(
          'Are you sure you want to sign out? Your encrypted data will remain safe on this device.',
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
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.urgentRose600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog shown when the device has no PIN/Pattern/Biometric set up.
  /// Offers to open system security settings.
  static void showNoSecurityDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: AppColors.border(isDark)),
        ),
        title: Text(
          'Security Required',
          style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
        ),
        content: Text(
          'To enable App Lock, your device must have a PIN, Pattern, or Biometric lock enabled. Would you like to set one up now?',
          style: TextStyle(color: AppColors.textSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
            },
            child: Text(
              'Later',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          Consumer(
            builder: (ctx, ref, _) {
              return ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                  ref.read(securityProvider.notifier).openSecuritySettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.emerald500 : AppColors.emerald600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Open Settings'),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Backup-now confirmation dialog showing Google Drive destination.
  /// Returns `true` if the user confirmed the backup.
  static Future<bool?> showBackupNowDialog(BuildContext context, String userEmail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: AppColors.border(isDark)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Backup Now',
              style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will upload a copy of your vault to:',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated(isDark),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.border(isDark),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Drive › App Data',
                          style: TextStyle(
                            color: AppColors.textPrimary(isDark),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.cloud_upload, size: 16),
            label: const Text('Backup Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.emerald500 : AppColors.emerald600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Crash-test confirmation dialog for Crashlytics verification.
  /// Returns `true` if the user confirmed the crash.
  static Future<bool?> showCrashTestDialog(BuildContext context) {
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
          'Simulate Crash?',
          style: AppTypography.headlineMedium(AppColors.urgentRose600),
        ),
        content: Text(
          'This will trigger an immediate hard crash of the application using FirebaseCrashlytics.instance.crash() to verify your integration online. Make sure you saved your changes.',
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('CRASH NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
