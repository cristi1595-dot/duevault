import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class PermissionHelper {
  /// Checks and requests camera permission.
  /// Returns true if granted, false otherwise.
  static Future<bool> requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;
    
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context, 'Camera');
      return false;
    }
    
    status = await Permission.camera.request();
    
    if (status.isDenied) {
      // User refused once, but not permanently
      return false;
    }
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context, 'Camera');
      return false;
    }
    
    return status.isGranted;
  }

  /// Checks and requests photo/gallery permission.
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    // For Android 13+, we use photos, for older we use storage
    Permission permission = Permission.photos;
    
    var status = await permission.status;
    if (status.isRestricted || status.isDenied) {
      status = await permission.request();
    }
    
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context, 'Gallery');
      return false;
    }
    
    return status.isGranted;
  }

  static void _showSettingsDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$feature Access Required', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          'DueVault needs $feature access to scan your documents. Please enable it in the app settings.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: AppTheme.primaryAction, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
