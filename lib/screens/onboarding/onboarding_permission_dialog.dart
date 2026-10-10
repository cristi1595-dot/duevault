import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

/// Shows system app settings dialog when notification permissions are permanently denied.
class OnboardingPermissionDialog {
  OnboardingPermissionDialog._();

  static Future<bool> show(BuildContext context, bool isDark) async {
    bool didOpenSettings = false;

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
          'To enable notifications, please allow them for DueVault in your device settings.',
          style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              unawaited(HapticFeedback.mediumImpact());
              didOpenSettings = true;
              Navigator.pop(ctx);
              await AppSettings.openAppSettings(type: AppSettingsType.notification);
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

    return didOpenSettings;
  }
}
