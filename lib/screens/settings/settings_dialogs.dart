import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:app_settings/app_settings.dart';
import '../../theme/app_theme.dart';
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
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Notifications Disabled'),
        content: const Text(
          'To enable global reminders, please allow notifications for DueVault in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final isAndroid = Theme.of(context).platform == TargetPlatform.android;
              Navigator.pop(ctx);
              await AppSettings.openAppSettings(type: AppSettingsType.notification);
              
              if (isAndroid) {
                final isBatteryOptimizationDisabled = 
                    await DisableBatteryOptimization.isAllBatteryOptimizationDisabled ?? false;
                if (!isBatteryOptimizationDisabled) {
                  await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAction,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your encrypted data will remain safe on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.urgentRed,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Security Required'),
        content: const Text(
          'To enable App Lock, your device must have a PIN, Pattern, or Biometric lock enabled. Would you like to set one up now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(securityProvider.notifier).openSecuritySettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAction,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              color: AppTheme.primaryAction,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Backup Now',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will upload a copy of your vault to:',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: AppTheme.primaryAction,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Drive › App Data',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
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
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.cloud_upload, size: 16),
            label: const Text('Backup Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAction,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Simulate Crash?'),
        content: const Text(
          'This will trigger an immediate hard crash of the application using FirebaseCrashlytics.instance.crash() to verify your integration online. Make sure you saved your changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.urgentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('CRASH NOW'),
          ),
        ],
      ),
    );
  }
}
