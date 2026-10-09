import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
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

    final hour = DateTime.now().hour;
    final String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    // Google Account Name:
    // Only display name if signed in with Google (not in guest mode) and has a valid display name.
    // Otherwise, show only the greeting (e.g. "Good Evening") without any name.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: App Icon & Dynamic Greeting
          Expanded(
            child: Row(
              children: [
                const DueVaultLogo(
                  size: 34,
                  showGlow: false,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    greetingText,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Right Controls: Sync Status & Refresh Button & Profile
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SyncStatusIndicator(),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(vaultProvider.notifier).refreshVault();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.sync_rounded,
                    size: 22,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: user != null && !isGuest
                          ? AppTheme.primaryAction
                          : (isDark
                              ? const Color(0xFF222F48)
                              : const Color(0xFFE2E8F0)),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: isDark
                        ? const Color(0xFF1E2638)
                        : const Color(0xFFF1F5F9),
                    backgroundImage: user?.photoURL != null && !isGuest
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: (user?.photoURL == null || isGuest)
                        ? Icon(
                            Icons.person_outline_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          )
                        : null,
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
