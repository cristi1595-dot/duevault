import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import '../services/auto_sync_service.dart';
import '../providers/database_provider.dart';
import '../models/app_config.dart';
import '../providers/vault_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_sync_service.dart';
import 'paywall_screen.dart';
import '../providers/premium_provider.dart';
import '../utils/logger.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _completeOnboarding(
    WidgetRef ref, {
    bool isGuest = false,
  }) async {
    final isar = ref.read(isarProvider);

    // 1. Update Database first
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.hasSeenOnboarding = true;
      config.isGuest = isGuest;
      await isar.appConfigs.put(config);
    });

    // 2. Update States - CRITICAL: Set isGuest FIRST so main.dart logic
    // (user != null || isGuest) is already true when hasSeenOnboarding triggers a rebuild.
    if (isGuest) {
      ref.read(isGuestProvider.notifier).state = true;
    }

    ref.read(hasSeenOnboardingProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Full Logo (Replaced with Custom Vector Logo)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DueVaultLogo(size: 110),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Due',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        'Vault',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: AppTheme.safeGreen,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                'Securely manage your bills\nand documents in one place.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const Spacer(),
              // Google Sign In Button
              _buildGoogleSignInButton(context, ref),
              const SizedBox(height: 16),
              // Continue as Guest Button
              SecondaryButton(
                label: 'Continue as Guest',
                icon: Icons.person_outline,
                onPressed: () async {
                  await _completeOnboarding(ref, isGuest: true);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final isGuest = ref.read(isGuestProvider);
        final isPremium = ref.read(isPremiumProvider);
        if (isGuest && !isPremium) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
          return;
        }

        final messenger = ScaffoldMessenger.of(context);

        // Show loading indicator
        unawaited(
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAction),
            ),
          ),
        );

        // 0. Mark as processing sync to hold LoginScreen mounted
        ref.read(isProcessingAuthSyncProvider.notifier).state = true;

        UserCredential? userCredential;
        try {
          userCredential = await ref
              .read(authServiceProvider)
              .signInWithGoogle();
        } catch (e) {
          logger.e('Google Sign-In failed with exception', error: e);
          if (context.mounted) {
            Navigator.pop(context); // Pop loading indicator
          }
          ref.read(isProcessingAuthSyncProvider.notifier).state = false;
          messenger.showSnackBar(
            SnackBar(
              content: Text('Sign in error: ${e.toString().split('\n').first}'),
              backgroundColor: AppTheme.urgentRed,
            ),
          );
          return;
        }

        if (userCredential != null) {
          final uid = userCredential.user!.uid;

          // Switch off Guest mode immediately
          ref.read(isGuestProvider.notifier).state = false;

          // 1. Intelligent Migration Check
          final hasGuestData = await ref
              .read(vaultRepositoryProvider)
              .hasRealGuestData();

          if (hasGuestData && context.mounted) {
            // Dismiss loading indicator temporarily so user can see migration dialog
            Navigator.pop(context);

            await Future.delayed(const Duration(milliseconds: 500));
            if (!context.mounted) return;

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
                    child: const Text('No, delete'),
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

            // Re-show loading indicator after dialog decision
            if (context.mounted) {
              unawaited(
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryAction),
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
                  const SnackBar(content: Text('✓ Local guest data deleted.')),
                );
              }
            }
          }

          // 2. Refresh UI immediately
          await ref.read(vaultProvider.notifier).refreshVault();

          // Get the display name — handle null AND empty string
          final firebaseUser = FirebaseAuth.instance.currentUser;
          final rawName =
              userCredential.user?.displayName ?? firebaseUser?.displayName;
          final displayName = (rawName != null && rawName.isNotEmpty)
              ? rawName
              : (firebaseUser?.email?.split('@').first ?? 'User');
          messenger.showSnackBar(
            SnackBar(
              content: Text('Welcome, $displayName! Syncing your data...'),
            ),
          );

          // Run synchronization synchronously
          try {
            // Intelligent sync after login
            final syncResult = await ref
                .read(autoSyncServiceProvider)
                .syncAfterLogin();

            // Also trigger Firebase Firestore sync immediately after login to pull user items
            await ref.read(firebaseSyncServiceProvider).sync(force: true);

            // Refresh UI state to load the newly downloaded items from Isar
            await ref.read(vaultProvider.notifier).refreshVault();

            if (context.mounted) {
              final items = ref.read(vaultProvider);
              messenger.clearSnackBars();
              String message;
              Color? bgColor;

              if (syncResult == 'restored') {
                message = '✓ Your vault data has been restored from Cloud!';
                bgColor = AppTheme.safeGreen;
              } else if (syncResult == 'uploaded') {
                message =
                    '✓ Your local data has been synchronized with your account!';
                bgColor = AppTheme.primaryAction;
              } else if (syncResult == 'empty' && items.isEmpty) {
                message = 'Welcome! Starting fresh with your new vault.';
                bgColor = null;
              } else {
                message = 'Welcome back! Your vault is ready.';
                bgColor = AppTheme.primaryAction;
              }

              messenger.showSnackBar(
                SnackBar(content: Text(message), backgroundColor: bgColor),
              );
            }
          } catch (e) {
            logger.e('Error during background login sync', error: e);
          }

          // Remove loading indicator
          if (context.mounted) {
            Navigator.pop(context);
          }

          // 3. FINISHED - Release the screen navigation immediately
          ref.read(isProcessingAuthSyncProvider.notifier).state = false;

          // Complete onboarding to trigger immediate navigation to MainNavigation
          await _completeOnboarding(ref);
        } else {
          // Remove loading indicator
          if (context.mounted) {
            Navigator.pop(context);
          }
          // Sign in failed/canceled -> Reset busy state
          ref.read(isProcessingAuthSyncProvider.notifier).state = false;
          messenger.showSnackBar(
            const SnackBar(content: Text('Sign in failed or was canceled')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).cardTheme.color,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
            height: 24,
            cacheHeight: 48,
            errorBuilder: (ctx, err, st) =>
                const Icon(Icons.account_circle, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sign in with Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (!ref.watch(isPremiumProvider)) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.safeGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.safeGreen.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 11,
                    color: AppTheme.safeGreen,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.safeGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
