import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import 'logger.dart';

class PermissionHelper {
  static bool _isRequesting = false;

  /// Checks and requests camera permission.
  /// Returns true if granted, false otherwise.
  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (_isRequesting) {
      try {
        return await Permission.camera.isGranted;
      } catch (_) {
        return false;
      }
    }
    _isRequesting = true;

    try {
      var status = await Permission.camera.status;

      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        if (context.mounted) _showSettingsDialog(context, 'Camera');
        return false;
      }

      try {
        status = await Permission.camera.request();
      } catch (e) {
        logger.w('PermissionHelper: Camera request threw exception: $e');
        status = await Permission.camera.status;
      }

      if (status.isDenied) {
        // User refused once, but not permanently
        return false;
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) _showSettingsDialog(context, 'Camera');
        return false;
      }

      return status.isGranted;
    } finally {
      _isRequesting = false;
    }
  }

  /// Checks and requests photo/gallery permission.
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    const permission = Permission.photos;
    if (_isRequesting) {
      try {
        return await permission.isGranted;
      } catch (_) {
        return false;
      }
    }
    _isRequesting = true;

    try {
      // For Android 13+, we use photos, for older we use storage
      var status = await permission.status;
      if (status.isRestricted || status.isDenied) {
        try {
          status = await permission.request();
        } catch (e) {
          logger.w('PermissionHelper: Gallery request threw exception: $e');
          status = await permission.status;
        }
      }

      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        if (context.mounted) _showSettingsDialog(context, 'Gallery');
        return false;
      }

      return status.isGranted;
    } finally {
      _isRequesting = false;
    }
  }

  static void _showSettingsDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$feature Access Required',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'DueVault needs $feature access to scan your documents. Please enable it in the app settings.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                color: AppTheme.primaryAction,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
