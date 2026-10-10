import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../models/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/auto_sync_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../utils/logger.dart';
import '../../main.dart';
import '../../providers/premium_provider.dart';

class GoogleSignInSection extends ConsumerWidget {
  const GoogleSignInSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(isProcessingAuthSyncProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () async {
          if (isProcessing) return;
          await HapticFeedback.mediumImpact();
          if (!context.mounted) return;

          final messenger = ScaffoldMessenger.of(context);
          try {
            ref.read(isProcessingAuthSyncProvider.notifier).state = true;

            // Show loading indicator
            unawaited(
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                  ),
                ),
              ),
            );

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
                // Pop loading indicator temporarily so user can see migration dialog
                Navigator.pop(context);

                final shouldMigrate = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface(isDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      side: BorderSide(color: AppColors.border(isDark)),
                    ),
                    title: const Text('Link Local Data?'),
                    content: const Text(
                      'You have bills or documents saved in Guest mode. Would you like to migrate and securely sync them to your Google Account?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context, false);
                        },
                        child: const Text(
                          'Discard',
                          style: TextStyle(color: AppColors.urgentRose600),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.emerald500 : AppColors.emerald600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('Migrate & Sync'),
                      ),
                    ],
                  ),
                );

                // Re-show loading indicator after dialog decision
                if (context.mounted) {
                  unawaited(
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: CircularProgressIndicator(
                          color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                        ),
                      ),
                    ),
                  );
                }

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

              // Run synchronization synchronously
              try {
                // Intelligent sync
                final syncResult = await ref
                    .read(autoSyncServiceProvider)
                    .syncAfterLogin();

                // Also trigger Firebase Firestore sync immediately after settings login to pull user items
                await ref.read(firebaseSyncServiceProvider).sync(force: true);

                // Refresh UI state to load the newly downloaded items from Isar
                await ref.read(vaultProvider.notifier).refreshVault();

                if (context.mounted) {
                  final items = ref.read(vaultProvider);
                  messenger.clearSnackBars();
                  String message;
                  Color? bgColor;

                  if (syncResult == 'restored') {
                    message = '✓ Your vault data has been restored!';
                    bgColor = isDark ? AppColors.emerald500 : AppColors.emerald600;
                  } else if (syncResult == 'uploaded') {
                    message = '✓ Cloud data synced with your account!';
                    bgColor = isDark ? AppColors.emerald500 : AppColors.emerald600;
                  } else if (syncResult == 'empty' && items.isEmpty) {
                    message = 'No backup found. Starting fresh.';
                    bgColor = null;
                  } else {
                    message = '✓ Cloud data synced with your account!';
                    bgColor = isDark ? AppColors.emerald500 : AppColors.emerald600;
                  }

                  messenger.showSnackBar(
                    SnackBar(content: Text(message), backgroundColor: bgColor),
                  );
                }
              } catch (e, stack) {
                logger.e('Error during background settings login sync', error: e, stackTrace: stack);
              }

              // Turn off processing state BEFORE navigating so MainNavigation shows immediately
              ref.read(isProcessingAuthSyncProvider.notifier).state = false;

              // Pop loading indicator
              if (context.mounted) {
                Navigator.pop(context);
                unawaited(
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                    (route) => false,
                  ),
                );
              }
            } else {
              // Pop loading indicator
              if (context.mounted) {
                Navigator.pop(context);
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('Sign in canceled.')),
              );
            }
          } catch (e, stack) {
            // Pop loading indicator
            if (context.mounted) {
              Navigator.pop(context);
            }
            logger.e('Sign in error', error: e, stackTrace: stack);
            if (context.mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Sign in error: ${e.toString().split('\n').first}'),
                  backgroundColor: AppColors.urgentRose600,
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface(isDark),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.border(isDark),
              width: 1,
            ),
            boxShadow: !isDark ? AppShadows.sm : null,
          ),
          child: isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Signing in & Syncing...',
                      style: TextStyle(
                        color: isDark ? AppColors.emerald400 : AppColors.emerald600,
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
                      cacheHeight: 36,
                      errorBuilder: (ctx, err, st) => Icon(
                        Icons.account_circle_outlined,
                        color: AppColors.textPrimary(isDark),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sign in with Google',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (!ref.watch(isPremiumProvider)) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          border: Border.all(
                            color: AppColors.emerald500.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 10,
                              color: AppColors.emerald500,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emerald500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
