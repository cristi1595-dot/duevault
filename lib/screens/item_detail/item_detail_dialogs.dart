import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ItemDetailDialogs {
  static Future<bool?> showDeleteAttachmentDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Attachment',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to remove this file?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.urgentRed),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showDeleteItemDialog(BuildContext context, String itemTitle) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Item',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to delete "$itemTitle"? This action cannot be undone.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
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
}
