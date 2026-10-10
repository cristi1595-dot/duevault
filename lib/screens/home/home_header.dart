import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/global_components.dart';
import '../../theme/app_theme.dart';
import '../settings_screen.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final isGuest = ref.watch(isGuestProvider);
    final user = authState.valueOrNull;

    final now = DateTime.now();
    final hour = now.hour;
    final String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final bool isGoogleConnected = user != null &&
        !isGuest &&
        (user.providerData.any((p) => p.providerId == 'google.com') ||
            (user.displayName != null && user.displayName!.trim().isNotEmpty));

    final String greetingText;
    if (isGoogleConnected &&
        user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      final firstName = user.displayName!.trim().split(' ').first;
      greetingText = '$greeting, $firstName';
    } else {
      greetingText = greeting;
    }

    final formattedDate = DateFormat('EEEE, d MMMM').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: App Icon & Dynamic Greeting with Date Subtitle
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const DueVaultLogo(
                  size: 44,
                  showGlow: false,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        greetingText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.2,
                          color: AppColors.textPrimary(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right Controls: Sync Status, Profile Avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SyncStatusIndicator(),
              const SizedBox(width: AppSpacing.xs),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  splashColor: AppColors.emerald500.withValues(alpha: 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: user != null && !isGuest
                            ? AppColors.emerald500
                            : AppColors.border(isDark),
                        width: 1.5,
                      ),
                      boxShadow: user != null && !isGuest && isDark
                          ? AppShadows.darkEmeraldGlow(opacity: 0.25)
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.surfaceElevated(isDark),
                      backgroundImage: user?.photoURL != null && !isGuest
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: (user?.photoURL == null || isGuest)
                          ? Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: AppColors.textSecondary(isDark),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
