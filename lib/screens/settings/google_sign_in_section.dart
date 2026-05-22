import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/auto_sync_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../utils/logger.dart';
import '../../main.dart';

class GoogleSignInSection extends ConsumerWidget {
  const GoogleSignInSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(isProcessingAuthSyncProvider);

    return GestureDetector(
      onTap: () async {
        if (isProcessing) return;
        final messenger = ScaffoldMessenger.of(context);
        try {
          ref.read(isProcessingAuthSyncProvider.notifier).state = true;
          final result = await ref.read(authServiceProvider).signInWithGoogle();
          if (!context.mounted) return;

          if (result != null) {
            final uid = result.user!.uid;

            // Reset guest mode since user is now authenticated
            ref.read(isGuestProvider.notifier).state = false;
            final isar = ref.read(isarProvider);
            await isar.writeTxn(() async {
              final config = await isar.appConfigs.get(0) ?? AppConfig();
              config.isGuest = false;
              await isar.appConfigs.put(config);
            });

            // 1. Intelligent Migration Check
            final hasGuestData = await ref
                .read(vaultRepositoryProvider)
                .hasRealGuestData();

            if (hasGuestData && context.mounted) {
              final shouldMigrate = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).cardTheme.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Migrate Local Data?'),
                  content: const Text(
                    'We found bills/documents saved in Guest mode. Would you like to move them to your Google account? If you choose \'No\', they will be permanently deleted.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'No, delete',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAction,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Yes, Migrate'),
                    ),
                  ],
                ),
              );

              if (shouldMigrate == true) {
                await ref.read(vaultProvider.notifier).migrateGuestData(uid);
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('✓ Migration complete!')),
                  );
                }
              } else {
                await ref.read(vaultProvider.notifier).deleteGuestData();
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('✓ Local guest data deleted.'),
                    ),
                  );
                }
              }
            }

            if (context.mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Account secured. Syncing your vault...'),
                ),
              );
            }

            // Intelligent sync
            final syncResult = await ref
                .read(autoSyncServiceProvider)
                .syncAfterLogin();

            // Also trigger Firebase Firestore sync immediately after settings login to pull user items
            await ref.read(firebaseSyncServiceProvider).sync();

            if (!context.mounted) return;

            messenger.clearSnackBars();
            String message;
            Color? bgColor;

            if (syncResult == 'restored') {
              message = '✓ Your vault data has been restored!';
              bgColor = AppTheme.safeGreen;
            } else if (syncResult == 'uploaded') {
              message = '✓ Local data synced with your account!';
              bgColor = AppTheme.primaryAction;
            } else {
              message = 'No backup found. Starting fresh.';
              bgColor = null;
            }

            messenger.showSnackBar(
              SnackBar(content: Text(message), backgroundColor: bgColor),
            );

            // Turn off processing state BEFORE navigating so MainNavigation shows immediately
            ref.read(isProcessingAuthSyncProvider.notifier).state = false;

            unawaited(
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigation()),
                (route) => false,
              ),
            );
          } else {
            messenger.showSnackBar(
              const SnackBar(content: Text('Sign in canceled.')),
            );
          }
        } catch (e) {
          logger.e('Sign in error', error: e);
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Sign in error: ${e.toString().split('\n').first}'),
                backgroundColor: AppTheme.urgentRed,
              ),
            );
          }
        } finally {
          if (context.mounted) {
            ref.read(isProcessingAuthSyncProvider.notifier).state = false;
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryAction,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Signing in & Syncing...',
                    style: TextStyle(
                      color: AppTheme.primaryAction,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                    height: 18,
                    errorBuilder: (ctx, err, st) => Icon(
                      Icons.account_circle_outlined,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
