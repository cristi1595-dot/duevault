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
    builder: (sheetContext) {
      final isGuest = FirebaseAuth.instance.currentUser == null;
      
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).cardTheme.color ?? AppTheme.darkSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(
            color: Theme.of(sheetContext).dividerColor.withValues(alpha: 0.5),
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
                color: Theme.of(sheetContext).textTheme.bodySmall?.color?.withValues(alpha: 0.3) ?? Colors.white24,
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
                        style: Theme.of(sheetContext).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your database and cloud space',
                        style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
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
            GestureDetector(
              onTap: () async {
                Navigator.pop(sheetContext); // Close bottom sheet
                
                final confirm = await showDialog<bool>(
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

                if (confirm == true) {
                  if (!context.mounted) return;
                  unawaited(
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) =>
                          const Center(child: CircularProgressIndicator()),
                    ),
                  );

                  try {
                    await ref
                        .read(vaultProvider.notifier)
                        .clearLocalCache();
                    if (context.mounted) {
                      Navigator.pop(context); // Close progress dialog
                      ScaffoldMessenger.of(context).showSnackBar(
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
                    if (context.mounted) {
                      Navigator.pop(context); // Close progress dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          backgroundColor: AppTheme.urgentRed,
                        ),
                      );
                    }
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(sheetContext).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAction.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.phonelink_erase_rounded,
                        color: AppTheme.primaryAction,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clear Local Cache',
                            style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Deletes local temporary items only. Cloud backup stays safe.',
                            style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(sheetContext).textTheme.bodySmall?.color,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Option 2: Erase All Data
            GestureDetector(
              onTap: () async {
                Navigator.pop(sheetContext); // Close bottom sheet
                
                final confirm = await showDialog<bool>(
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

                if (confirm == true) {
                  if (!context.mounted) return;
                  unawaited(
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) =>
                          const Center(child: CircularProgressIndicator()),
                    ),
                  );

                  try {
                    await ref
                        .read(vaultProvider.notifier)
                        .clearAllData(alsoDeleteCloud: true);

                    if (context.mounted) {
                      Navigator.pop(context); // Close progress dialog
                      final isUserLoggedIn =
                          FirebaseAuth.instance.currentUser != null;
                      ScaffoldMessenger.of(context).showSnackBar(
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
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigation(),
                          ),
                          (route) => false,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close progress dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Wipe failed: $e'),
                          backgroundColor: AppTheme.urgentRed,
                        ),
                      );
                    }
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.urgentRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.urgentRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.urgentRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: AppTheme.urgentRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Erase All Data',
                            style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.urgentRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'WIPE EVERYTHING. Cloud and local data will be permanently deleted.',
                            style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: Theme.of(sheetContext).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.urgentRed,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (!isGuest) ...[
              const SizedBox(height: 16),
              
              // Option 3: Delete Account & Cloud Data
              GestureDetector(
                onTap: () async {
                  Navigator.pop(sheetContext); // Close bottom sheet
                  
                  final confirm = await showDialog<bool>(
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

                  if (confirm == true) {
                    if (!context.mounted) return;
                    unawaited(
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    );

                    try {
                      // 1. Reauthenticate first to refresh credentials and prevent stale-session errors
                      await ref.read(authServiceProvider).reauthenticate();

                      // 2. Wipe local and cloud database items (Firestore & Drive AppData folder)
                      await ref
                          .read(vaultProvider.notifier)
                          .clearAllData(alsoDeleteCloud: true);

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

                      if (context.mounted) {
                        Navigator.pop(context); // Close progress dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account and all data deleted successfully.'),
                            backgroundColor: AppTheme.urgentRed,
                          ),
                        );
                        // Force reset app navigation state
                        unawaited(
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigation(),
                            ),
                            (route) => false,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close progress dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Account deletion failed: $e'),
                            backgroundColor: AppTheme.urgentRed,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.urgentRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.urgentRed.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.urgentRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.no_accounts_rounded,
                          color: AppTheme.urgentRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Account & Data',
                              style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.urgentRed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Wipes all local & cloud data and permanently deletes your account registration.',
                              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: Theme.of(sheetContext).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.urgentRed,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
