import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/database_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/security_provider.dart';
import '../../models/app_config.dart';
import '../../main.dart';
import 'storage_reset_dialogs.dart';
import '../../providers/premium_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/logger.dart';

/// Shows the Storage & Reset bottom sheet allowing cache clearing, data wiping,
/// and complete account deletion.
void showStorageResetBottomSheet(BuildContext context, WidgetRef ref) {
  HapticFeedback.lightImpact();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final isGuest = authState.valueOrNull == null;
    final isPremium = ref.watch(isPremiumProvider);
    final isPro = !isGuest && isPremium;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(
          color: AppColors.border(isDark),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.base,
        right: AppSpacing.base,
        bottom: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Pull Indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate500.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2838) : AppColors.slate100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.border(isDark).withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.storage_rounded,
                  color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage & Reset',
                      style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your database and cloud space',
                      style: AppTypography.bodySmall(AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Option 1: Erase All Data
          _StorageOptionTile(
            title: isPro ? 'Erase All Data (Cloud & Local)' : 'Erase All Data (Local)',
            subtitle: isPro
                ? 'WIPE EVERYTHING. Cloud and local data will be permanently deleted.'
                : 'WIPE EVERYTHING. Local data will be permanently deleted.',
            icon: Icons.delete_forever_rounded,
            iconColor: AppColors.urgentRose600,
            iconBgColor: AppColors.urgentRose500.withValues(alpha: isDark ? 0.35 : 0.15),
            backgroundColor: AppColors.urgentRose500.withValues(alpha: isDark ? 0.15 : 0.08),
            borderColor: AppColors.urgentRose500.withValues(alpha: isDark ? 0.35 : 0.25),
            textColor: AppColors.statusUrgentText(isDark),
            onTap: () => _handleEraseAllData(context, ref, isPro),
          ),

          if (!isGuest) ...[
            const SizedBox(height: AppSpacing.md),

            // Option 2: Delete Account & Cloud Data
            _StorageOptionTile(
              title: 'Delete Account & Data',
              subtitle: 'Wipes all local & cloud data and permanently deletes your account registration.',
              icon: Icons.no_accounts_rounded,
              iconColor: AppColors.urgentRose600,
              iconBgColor: AppColors.urgentRose500.withValues(alpha: isDark ? 0.4 : 0.2),
              backgroundColor: AppColors.urgentRose500.withValues(alpha: isDark ? 0.2 : 0.1),
              borderColor: AppColors.urgentRose500.withValues(alpha: isDark ? 0.4 : 0.3),
              textColor: AppColors.statusUrgentText(isDark),
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

    final isDark = Theme.of(parentContext).brightness == Brightness.dark;

    // 3. Show progress indicator dialog
    unawaited(
      showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.emerald400 : AppColors.emerald600,
            ),
          ),
        ),
      ),
    );

    try {
      // 4. Run database/cloud tasks
      await onExecute();

      if (!parentContext.mounted) return;
      Navigator.pop(parentContext); // Close progress dialog

      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: successMessage.contains('wiped') || successMessage.contains('deleted')
              ? AppColors.urgentRose600
              : null,
        ),
      );
      onSuccess?.call();
    } catch (e, stackTrace) {
      logger.e(errorMessagePrefix, error: e, stackTrace: stackTrace);

      if (!parentContext.mounted) return;
      Navigator.pop(parentContext); // Close progress dialog

      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('$errorMessagePrefix: $e'),
          backgroundColor: AppColors.urgentRose600,
        ),
      );
    }
  }

  Future<void> _handleEraseAllData(
    BuildContext context,
    WidgetRef ref,
    bool isPro,
  ) async {
    final vaultNotifier = ref.read(vaultProvider.notifier);
    await _runAction(
      context: context,
      onConfirm: () => showWipeEverythingConfirmDialog(parentContext, isPro),
      onExecute: () => vaultNotifier.clearAllData(alsoDeleteCloud: isPro),
      successMessage: isPro
          ? 'All data has been wiped from device and cloud.'
          : 'All local data has been wiped.',
      errorMessagePrefix: 'Wipe failed',
      onSuccess: () {
        if (!parentContext.mounted) return;
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
    final authService = ref.read(authServiceProvider);
    final vaultNotifier = ref.read(vaultProvider.notifier);
    final securityNotifier = ref.read(securityProvider.notifier);
    final guestProviderNotifier = ref.read(isGuestProvider.notifier);
    final isar = ref.read(isarProvider);

    await _runAction(
      context: context,
      onConfirm: () => showDeleteAccountConfirmDialog(parentContext),
      onExecute: () async {
        // 1. Reauthenticate first
        await authService.reauthenticate();

        // 2. Wipe database & cloud
        await vaultNotifier.clearAllData(alsoDeleteCloud: true);

        // 3. Reset local PIN state
        await securityNotifier.reset();

        // 4. Delete registration
        await authService.deleteAccount();

        // 5. Cancel all notifications
        await NotificationService.cancelAllNotifications();

        // 6. Sign out
        await authService.signOut();

        // 7. Set guest state
        guestProviderNotifier.state = true;

        // 8. Reset Isar config
        await isar.writeTxn(() async {
          final config = AppConfig()..isGuest = true;
          await isar.appConfigs.put(config);
        });
      },
      successMessage: 'Account and all data deleted successfully.',
      errorMessagePrefix: 'Account deletion failed',
      onSuccess: () {
        if (!parentContext.mounted) return;
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
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _StorageOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDark),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: textColor.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
