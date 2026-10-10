import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import '../../models/app_config.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/database_provider.dart';
import '../../main.dart';
import '../../services/analytics_service.dart';
import '../../services/notification_service.dart';
import 'settings_dialogs.dart';

class CompactProfileCard extends ConsumerWidget {
  const CompactProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        final isGuest = user == null;

        // Log user type dynamically to Firebase Analytics
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(analyticsServiceProvider).logUserType(isGuest);
        });

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accentColor = isDark ? AppColors.emerald400 : AppColors.emerald600;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.base,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: AppColors.surface(isDark),
            border: Border.all(
              color: AppColors.border(isDark),
              width: 1.0,
            ),
            boxShadow: !isDark ? AppShadows.sm : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2), // Gradient ring gap
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.8),
                      accentColor.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2838) : AppColors.slate100,
                    shape: BoxShape.circle,
                    image: user?.photoURL != null
                        ? DecorationImage(
                            image: NetworkImage(user!.photoURL!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user?.photoURL == null
                      ? Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.textSecondary(isDark),
                          size: 22,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (user?.displayName?.isNotEmpty == true)
                          ? user!.displayName!
                          : (user?.email?.split('@').first ?? 'Guest User'),
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGuest ? 'Local mode active' : (user.email ?? ''),
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGuest)
                GestureDetector(
                  onTap: () async {
                    await HapticFeedback.lightImpact();
                    if (!context.mounted) return;
                    final confirm = await SettingsDialogs.showSignOutDialog(context);

                    if (confirm == true) {
                      debugPrint(
                        'CompactProfileCard: Sign Out confirmed. Clearing session flags.',
                      );

                      // 1. Reset Security (FaceID/PIN) - as requested
                      await ref.read(securityProvider.notifier).reset();

                      // 2. Reset Isar config (Persistence fix)
                      final isar = ref.read(isarProvider);
                      await isar.writeTxn(() async {
                        final config =
                            await isar.collection<AppConfig>().get(0) ?? AppConfig();
                        config.isGuest = true; // Switch back to guest mode automatically
                        config.lastCloudSync = null;
                        config.lastLocalChange = null;
                        config.lastSyncCheck = null;
                        config.localDatabaseChecksum = null;
                        config.needsBackup = false;
                        config.guestDataMigrated = false;
                        await isar.appConfigs.put(config);
                      });

                      // 3. Cancel all notifications from the current account
                      await NotificationService.cancelAllNotifications();

                      // 4. Perform logout
                      await ref.read(authServiceProvider).signOut();
                      ref.read(isGuestProvider.notifier).state = true;

                      if (context.mounted) {
                        unawaited(
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigation(),
                            ),
                            (route) => false,
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Signed out. You are now in Guest mode.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.urgentRose500.withValues(alpha: isDark ? 0.18 : 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.urgentRose500.withValues(alpha: isDark ? 0.35 : 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: AppColors.statusUrgentText(isDark),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.logout_rounded,
                          color: AppColors.statusUrgentText(isDark),
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: AppColors.surface(isDark),
            border: Border.all(
              color: AppColors.border(isDark),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2838) : AppColors.slate100,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2838) : AppColors.slate100,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2838) : AppColors.slate100,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
