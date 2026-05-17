import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import '../widgets/duevault_logo.dart';
import '../services/auto_sync_service.dart';
import '../providers/database_provider.dart';
import '../models/app_config.dart';
import '../providers/vault_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/auth_provider.dart';

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
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        'Vault',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
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

        final userCredential = await ref
            .read(authServiceProvider)
            .signInWithGoogle();

        // Remove loading indicator
        if (context.mounted) {
          Navigator.pop(context);
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

          // Intelligent sync after login
          final syncResult = await ref
              .read(autoSyncServiceProvider)
              .syncAfterLogin();

          // 3. FINISHED - Release the screen navigation
          ref.read(isProcessingAuthSyncProvider.notifier).state = false;

          // ONLY mark onboarding complete AFTER sync is done
          // This ensures main.dart doesn't switch to MainNavigation prematurely
          await _completeOnboarding(ref);

          if (context.mounted) {
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
            } else {
              message = 'Welcome! Starting fresh with your new vault.';
              bgColor = null;
            }

            messenger.showSnackBar(
              SnackBar(content: Text(message), backgroundColor: bgColor),
            );
          }
        } else {
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
            errorBuilder: (ctx, err, st) =>
                const Icon(Icons.account_circle, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sign in with Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
