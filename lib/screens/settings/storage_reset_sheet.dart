import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../providers/database_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/security_provider.dart';
import '../../models/app_config.dart';
import '../../main.dart';

/// Shows the Storage & Reset bottom sheet allowing cache clearing, data wiping,
/// and complete account deletion.
void showStorageResetBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => StorageResetSheet(parentContext: context),
  );
}

class StorageResetSheet extends ConsumerWidget {
  final BuildContext parentContext;

  const StorageResetSheet({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppTheme.darkSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.only(
        top: 10,
        left: 20,
        right: 20,
        bottom: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Pull Indicator
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3) ?? Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAction.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: AppTheme.primaryAction,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage & Reset',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your database and cloud space',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Option 1: Clear Local Cache
          _StorageOptionTile(
            title: 'Clear Local Cache',
            subtitle: 'Deletes local temporary items only. Cloud backup stays safe.',
            icon: Icons.phonelink_erase_rounded,
            iconColor: AppTheme.primaryAction,
            iconBgColor: AppTheme.primaryAction.withValues(alpha: 0.1),
            onTap: () => _handleClearCache(context, ref, isGuest),
          ),

          const SizedBox(height: 16),

          // Option 2: Erase All Data
          _StorageOptionTile(
            title: 'Erase All Data',
            subtitle: 'WIPE EVERYTHING. Cloud and local data will be permanently deleted.',
            icon: Icons.delete_forever_rounded,
            iconColor: AppTheme.urgentRed,
            iconBgColor: AppTheme.urgentRed.withValues(alpha: 0.15),
            backgroundColor: AppTheme.urgentRed.withValues(alpha: 0.08),
            borderColor: AppTheme.urgentRed.withValues(alpha: 0.3),
            textColor: AppTheme.urgentRed,
            onTap: () => _handleEraseAllData(context, ref, isGuest),
          ),

          if (!isGuest) ...[
            const SizedBox(height: 16),

            // Option 3: Delete Account & Cloud Data
            _StorageOptionTile(
              title: 'Delete Account & Data',
              subtitle: 'Wipes all local & cloud data and permanently deletes your account registration.',
              icon: Icons.no_accounts_rounded,
              iconColor: AppTheme.urgentRed,
              iconBgColor: AppTheme.urgentRed.withValues(alpha: 0.2),
              backgroundColor: AppTheme.urgentRed.withValues(alpha: 0.12),
              borderColor: AppTheme.urgentRed.withValues(alpha: 0.4),
              textColor: AppTheme.urgentRed,
              onTap: () => _handleDeleteAccount(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleClearCache(
    BuildContext context,
    WidgetRef ref,
    bool isGuest,
  ) async {
    Navigator.pop(context); // Close bottom sheet

    final confirm = await showDialog<bool>(
      context: parentContext,
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

    if (confirm == true) {
      if (!parentContext.mounted) return;
      unawaited(
        showDialog(
          context: parentContext,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        ),
      );

      try {
        await ref.read(vaultProvider.notifier).clearLocalCache();
        if (parentContext.mounted) {
          Navigator.pop(parentContext); // Close progress dialog
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text(
                isGuest
                    ? 'Local attachments cache cleared.'
                    : 'Local attachments cache cleared. Attachments will download on demand.',
              ),
            ),
          );
        }
      } catch (e) {
        if (parentContext.mounted) {
          Navigator.pop(parentContext); // Close progress dialog
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppTheme.urgentRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEraseAllData(
    BuildContext context,
    WidgetRef ref,
    bool isGuest,
  ) async {
    Navigator.pop(context); // Close bottom sheet

    final confirm = await showDialog<bool>(
      context: parentContext,
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

    if (confirm == true) {
      if (!parentContext.mounted) return;
      unawaited(
        showDialog(
          context: parentContext,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        ),
      );

      try {
        await ref.read(vaultProvider.notifier).clearAllData(alsoDeleteCloud: true);

        if (parentContext.mounted) {
          Navigator.pop(parentContext); // Close progress dialog
          final isUserLoggedIn = FirebaseAuth.instance.currentUser != null;
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text(
                isUserLoggedIn
                    ? 'All data has been wiped from device and cloud.'
                    : 'All local data has been wiped.',
              ),
              backgroundColor: AppTheme.urgentRed,
            ),
          );
          // Force navigation back to start
          unawaited(
            Navigator.pushAndRemoveUntil(
              parentContext,
              MaterialPageRoute(
                builder: (_) => const MainNavigation(),
              ),
              (route) => false,
            ),
          );
        }
      } catch (e) {
        if (parentContext.mounted) {
          Navigator.pop(parentContext); // Close progress dialog
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text('Wipe failed: $e'),
              backgroundColor: AppTheme.urgentRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    Navigator.pop(context); // Close bottom sheet

    final confirm = await showDialog<bool>(
      context: parentContext,
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

    if (confirm == true) {
      if (!parentContext.mounted) return;
      unawaited(
        showDialog(
          context: parentContext,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        ),
      );

      try {
        // 1. Reauthenticate first to refresh credentials and prevent stale-session errors
        await ref.read(authServiceProvider).reauthenticate();

        // 2. Wipe local and cloud database items (Firestore & Drive AppData folder)
        await ref.read(vaultProvider.notifier).clearAllData(alsoDeleteCloud: true);

        // 3. Reset Local Security/PIN state
        await ref.read(securityProvider.notifier).reset();

        // 4. Delete actual authentication registration
        await ref.read(authServiceProvider).deleteAccount();

        // 5. Complete sign-out cleanly
        await ref.read(authServiceProvider).signOut();

        // 6. Switch the memory guest provider state to true
        ref.read(isGuestProvider.notifier).state = true;

        // 7. Reset Isar config to switch back to guest mode automatically on launch
        final isar = ref.read(isarProvider);
        await isar.writeTxn(() async {
          final config = AppConfig()..isGuest = true;
          await isar.appConfigs.put(config);
        });

        if (parentContext.mounted) {
          Navigator.pop(parentContext); // Close progress dialog
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(
              content: Text('Account and all data deleted successfully.'),
              backgroundColor: AppTheme.urgentRed,
            ),
          );
          // Force reset app navigation state
          unawaited(
            Navigator.pushAndRemoveUntil(
              parentContext,
              MaterialPageRoute(
                builder: (_) => const MainNavigation(),
              ),
              (route) => false,
            ),
          );
        }
      } catch (e) {
        if (parentContext.mounted) {
          Navigator.pop(parentContext); // Close progress dialog
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text('Account deletion failed: $e'),
              backgroundColor: AppTheme.urgentRed,
            ),
          );
        }
      }
    }
  }
}

class _StorageOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _StorageOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = Theme.of(context).dividerColor.withValues(alpha: 0.5);
    final defaultBgColor = Theme.of(context).scaffoldBackgroundColor;
    final defaultTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    final defaultSubtitleColor = Theme.of(context).textTheme.bodySmall?.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor ?? defaultBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? defaultBorderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor ?? defaultTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: defaultSubtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textColor ?? defaultSubtitleColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
