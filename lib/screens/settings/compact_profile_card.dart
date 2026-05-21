import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../models/app_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/database_provider.dart';
import '../../main.dart';
import '../../services/analytics_service.dart';
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

        return BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2), // Gradient ring gap
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryAction.withValues(alpha: 0.8),
                      AppTheme.primaryAction.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
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
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withValues(alpha: 0.7),
                          size: 22,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (user?.displayName?.isNotEmpty == true)
                          ? user!.displayName!
                          : (user?.email?.split('@').first ?? 'Guest User'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGuest ? 'Local mode active' : (user.email ?? ''),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
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
                        config.isGuest =
                            true; // Switch back to guest mode automatically
                        await isar.appConfigs.put(config);
                      });

                      // 3. Perform logout
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.urgentRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.urgentRed.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: AppTheme.urgentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.logout_rounded,
                          color: AppTheme.urgentRed,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading profile'),
    );
  }
}
