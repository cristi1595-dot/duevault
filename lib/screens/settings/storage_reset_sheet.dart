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
import 'storage_reset_dialogs.dart';
import '../../providers/premium_provider.dart';

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
    final isPremium = ref.watch(isPremiumProvider);
    final isPro = !isGuest && isPremium;

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
            title: isPro ? 'Clear Local Cache (Cloud safe)' : 'Clear Local Cache',
            subtitle: isPro
                ? 'Deletes local temporary items only. Cloud backup stays safe.'
                : 'Deletes local temporary items only.',
            icon: Icons.phonelink_erase_rounded,
            iconColor: AppTheme.primaryAction,
            iconBgColor: AppTheme.primaryAction.withValues(alpha: 0.1),
            onTap: () => _handleClearCache(context, ref, isPro),
          ),

          const SizedBox(height: 16),

          // Option 2: Erase All Data
          _StorageOptionTile(
            title: isPro ? 'Erase All Data (Cloud & Local)' : 'Erase All Data (Local)',
            subtitle: isPro
                ? 'WIPE EVERYTHING. Cloud and local data will be permanently deleted.'
                : 'WIPE EVERYTHING. Local data will be permanently deleted.',
            icon: Icons.delete_forever_rounded,
            iconColor: AppTheme.urgentRed,
            iconBgColor: AppTheme.urgentRed.withValues(alpha: 0.15),
            backgroundColor: AppTheme.urgentRed.withValues(alpha: 0.08),
            borderColor: AppTheme.urgentRed.withValues(alpha: 0.3),
            textColor: AppTheme.urgentRed,
            onTap: () => _handleEraseAllData(context, ref, isPro),
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

  Future<void> _runAction({
    required BuildContext context,
    required Future<bool?> Function() onConfirm,
    required Future<void> Function() onExecute,
    required String successMessage,
    required String errorMessagePrefix,
    VoidCallback? onSuccess,
  }) async {
    // 1. Close bottom sheet
    Navigator.pop(context);

    // 2. Ask for confirmation
    final confirm = await onConfirm();
    if (confirm != true) return;

    if (!parentContext.mounted) return;

    // 3. Show progress indicator dialog
    unawaited(
      showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      // 4. Run database/cloud tasks
      await onExecute();

      if (parentContext.mounted) {
        Navigator.pop(parentContext); // Close progress dialog
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: successMessage.contains('wiped') || successMessage.contains('deleted')
                ? AppTheme.urgentRed
                : null,
          ),
        );
        onSuccess?.call();
      }
    } catch (e) {
      if (parentContext.mounted) {
        Navigator.pop(parentContext); // Close progress dialog
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text('$errorMessagePrefix: $e'),
            backgroundColor: AppTheme.urgentRed,
          ),
        );
      }
    }
  }

  Future<void> _handleClearCache(
    BuildContext context,
    WidgetRef ref,
    bool isPro,
  ) async {
    await _runAction(
      context: context,
      onConfirm: () => showClearCacheConfirmDialog(parentContext, isPro),
      onExecute: () => ref.read(vaultProvider.notifier).clearLocalCache(),
      successMessage: !isPro
          ? 'Local attachments cache cleared.'
          : 'Local attachments cache cleared. Attachments will download on demand.',
      errorMessagePrefix: 'Failed',
    );
  }

  Future<void> _handleEraseAllData(
    BuildContext context,
    WidgetRef ref,
    bool isPro,
  ) async {
    await _runAction(
      context: context,
      onConfirm: () => showWipeEverythingConfirmDialog(parentContext, isPro),
      onExecute: () => ref.read(vaultProvider.notifier).clearAllData(alsoDeleteCloud: isPro),
      successMessage: isPro
          ? 'All data has been wiped from device and cloud.'
          : 'All local data has been wiped.',
      errorMessagePrefix: 'Wipe failed',
      onSuccess: () {
        unawaited(
          Navigator.pushAndRemoveUntil(
            parentContext,
            MaterialPageRoute(
              builder: (_) => const MainNavigation(),
            ),
            (route) => false,
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await _runAction(
      context: context,
      onConfirm: () => showDeleteAccountConfirmDialog(parentContext),
      onExecute: () async {
        // 1. Reauthenticate first
        await ref.read(authServiceProvider).reauthenticate();

        // 2. Wipe database & cloud
        await ref.read(vaultProvider.notifier).clearAllData(alsoDeleteCloud: true);

        // 3. Reset local PIN state
        await ref.read(securityProvider.notifier).reset();

        // 4. Delete registration
        await ref.read(authServiceProvider).deleteAccount();

        // 5. Sign out
        await ref.read(authServiceProvider).signOut();

        // 6. Set guest state
        ref.read(isGuestProvider.notifier).state = true;

        // 7. Reset Isar config
        final isar = ref.read(isarProvider);
        await isar.writeTxn(() async {
          final config = AppConfig()..isGuest = true;
          await isar.appConfigs.put(config);
        });
      },
      successMessage: 'Account and all data deleted successfully.',
      errorMessagePrefix: 'Account deletion failed',
      onSuccess: () {
        unawaited(
          Navigator.pushAndRemoveUntil(
            parentContext,
            MaterialPageRoute(
              builder: (_) => const MainNavigation(),
            ),
            (route) => false,
          ),
        );
      },
    );
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
