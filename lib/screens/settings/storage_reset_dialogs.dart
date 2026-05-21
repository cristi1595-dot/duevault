import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Prompts confirmation for clearing local cached attachments.
Future<bool?> showClearCacheConfirmDialog(BuildContext context, bool isGuest) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('Clear Local Cache'),
      content: Text(
        isGuest
            ? 'This will permanently delete all local attached files/images from this phone. Your bills and documents list will remain.'
            : 'This will delete local downloaded attached files/images from this phone to free up space. You can download them again from Google Drive when viewing them. Your bills and documents list will remain.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(ctx).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.urgentRed,
          ),
          child: const Text(
            'CLEAR CACHE',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

/// Prompts confirmation for wiping all phone and cloud data.
Future<bool?> showWipeEverythingConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('WIPE EVERYTHING'),
      content: const Text(
        'WARNING: This will permanently delete ALL local data AND your Google Drive backup. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(ctx).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.urgentRed,
          ),
          child: const Text(
            'ERASE CLOUD & PHONE',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

/// Prompts confirmation for deleting the account and cloud backups permanently.
Future<bool?> showDeleteAccountConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('DELETE ACCOUNT'),
      content: const Text(
        'WARNING: This is permanent and irreversible. This will delete all your local data, your Google Drive backup, your Firestore database records, and permanently close your account registration. You will be logged out completely.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(ctx).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.urgentRed,
          ),
          child: const Text(
            'DELETE CONT & DATE',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
