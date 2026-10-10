import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/vault_provider.dart';
import '../services/auto_sync_service.dart';
import '../services/firebase_sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/logger.dart';

/// Helper coordinating authentication flows, guest onboarding, and initial cloud synchronization.
class AuthFlowHelper {
  AuthFlowHelper._();

  /// Marks onboarding completed in Isar DB and updates Riverpod state.
  static Future<void> completeOnboarding(
    WidgetRef ref, {
    bool isGuest = false,
  }) async {
    final isar = ref.read(isarProvider);

    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.hasSeenOnboarding = true;
      config.isGuest = isGuest;
      await isar.appConfigs.put(config);
    });

    if (isGuest) {
      ref.read(isGuestProvider.notifier).state = true;
    }
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
  }

  /// Full Google Sign-In sequence including guest migration, initial sync, and onboarding completion.
  static Future<void> handleGoogleSignIn(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) async {
    unawaited(HapticFeedback.lightImpact());
    final messenger = ScaffoldMessenger.of(context);

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

    ref.read(isProcessingAuthSyncProvider.notifier).state = true;

    UserCredential? userCredential;
    try {
      userCredential = await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e, stack) {
      logger.e('Google Sign-In failed with exception', error: e, stackTrace: stack);
      if (context.mounted) {
        Navigator.pop(context);
      }
      ref.read(isProcessingAuthSyncProvider.notifier).state = false;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sign in error: ${e.toString().split('\n').first}'),
          backgroundColor: AppColors.urgentRose600,
        ),
      );
      return;
    }

    if (userCredential != null) {
      final uid = userCredential.user!.uid;

      // Switch off Guest mode immediately
      ref.read(isGuestProvider.notifier).state = false;

      // Intelligent Migration Check
      final hasGuestData = await ref.read(vaultRepositoryProvider).hasRealGuestData();

      if (hasGuestData && context.mounted) {
        Navigator.pop(context);

        await Future.delayed(const Duration(milliseconds: 500));
        if (!context.mounted) return;

        final shouldMigrate = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: BorderSide(color: AppColors.border(isDark)),
            ),
            title: Text(
              'Migrate Local Data?',
              style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
            ),
            content: Text(
              'We found bills/documents saved in Guest mode. Would you like to move them to your Google account? If you choose \'No\', they will be permanently deleted.',
              style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx, false);
                },
                child: Text(
                  'No, delete',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.emerald500 : AppColors.emerald600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Yes, Migrate'),
              ),
            ],
          ),
        );

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
              const SnackBar(content: Text('✓ Local guest data deleted.')),
            );
          }
        }
      }

      await ref.read(vaultProvider.notifier).refreshVault();

      final firebaseUser = FirebaseAuth.instance.currentUser;
      final rawName = userCredential.user?.displayName ?? firebaseUser?.displayName;
      final displayName = (rawName != null && rawName.isNotEmpty)
          ? rawName
          : (firebaseUser?.email?.split('@').first ?? 'User');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Welcome, $displayName! Syncing your data...'),
        ),
      );

      try {
        final syncResult = await ref.read(autoSyncServiceProvider).syncAfterLogin();
        await ref.read(firebaseSyncServiceProvider).sync(force: true);
        await ref.read(vaultProvider.notifier).refreshVault();

        if (context.mounted) {
          final items = ref.read(vaultProvider);
          messenger.clearSnackBars();
          String message;
          Color? bgColor;

          if (syncResult == 'restored') {
            message = '✓ Your vault data has been restored from Cloud!';
            bgColor = isDark ? AppColors.emerald500 : AppColors.emerald600;
          } else if (syncResult == 'uploaded') {
            message = '✓ Your local data has been synchronized with your account!';
            bgColor = isDark ? AppColors.emerald500 : AppColors.emerald600;
          } else if (syncResult == 'empty' && items.isEmpty) {
            message = 'Welcome! Starting fresh with your new vault.';
            bgColor = null;
          } else {
            message = 'Welcome back! Your vault is ready.';
            bgColor = isDark ? AppColors.emerald500 : AppColors.emerald600;
          }

          messenger.showSnackBar(
            SnackBar(content: Text(message), backgroundColor: bgColor),
          );
        }
      } catch (e, stack) {
        logger.e('Error during background login sync', error: e, stackTrace: stack);
      }

      if (context.mounted) {
        Navigator.pop(context);
      }

      ref.read(isProcessingAuthSyncProvider.notifier).state = false;
      await completeOnboarding(ref);
    } else {
      if (context.mounted) {
        Navigator.pop(context);
      }
      ref.read(isProcessingAuthSyncProvider.notifier).state = false;
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in canceled')),
      );
    }
  }
}
