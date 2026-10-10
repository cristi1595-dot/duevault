import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/global_components.dart';

import 'settings/compact_profile_card.dart';
import 'settings/developer_options_section.dart';
import 'settings/drive_sync_section.dart';
import 'settings/google_sign_in_section.dart';
import 'settings/interface_customization_section.dart';
import 'settings/security_lock_section.dart';
import 'settings/settings_permission_helper.dart';
import 'settings/settings_section_header.dart';
import 'settings/settings_version_footer.dart';
import 'settings/smart_alerts_section.dart';
import 'settings/storage_integrity_section.dart';
import 'settings/settings_list_tile.dart';
import 'settings/settings_divider.dart';
import '../services/app_review_service.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/navigation_provider.dart';
import '../main.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isDevModeEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatusAndAutoEnable();
    }
  }

  Future<void> _checkStatusAndAutoEnable() async {
    if (!mounted) return;
    await SettingsPermissionHelper.checkStatusAndAutoEnable(ref);
  }

  Future<void> _attemptActivation({required bool targetState}) async {
    await SettingsPermissionHelper.attemptActivation(
      targetState: targetState,
      ref: ref,
      context: context,
      onStatusUpdated: (_) {},
    );
  }

  Widget _buildCategoryCard(BuildContext context, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: BentoCard(
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.lg,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)).copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary(isDark),
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              )
            : null,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            final delta = notification.scrollDelta ?? 0;
            if (delta.abs() > 2) {
              ref.read(navBarVisibleProvider.notifier).state = false;
            }
          }
          if (notification is ScrollEndNotification) {
            ref.read(navBarVisibleProvider.notifier).state = true;
          }
          return false;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Account Section: Google Account or Guest Status
              const CompactProfileCard(),
              const SizedBox(height: AppSpacing.md),

              // Sign In with Google Option (visible only when in Guest mode)
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authStateProvider);
                  final user = authState.valueOrNull;
                  final isProcessing = ref.watch(isProcessingAuthSyncProvider);
                  if (user == null || isProcessing) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: GoogleSignInSection(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // 2. Biometric Security & App Lock
              const SettingsSectionHeader(title: 'SECURITY'),
              const SizedBox(height: AppSpacing.xs),
              _buildCategoryCard(
                context,
                child: const SecurityLockSection(),
              ),

              // 3. Interface (Theme & Currency)
              const SettingsSectionHeader(title: 'INTERFACE'),
              const SizedBox(height: AppSpacing.xs),
              _buildCategoryCard(
                context,
                child: const InterfaceCustomizationSection(),
              ),

              // 4. Alerts & Notifications
              const SettingsSectionHeader(title: 'ALERTS & NOTIFICATIONS'),
              const SizedBox(height: AppSpacing.xs),
              _buildCategoryCard(
                context,
                child: SmartAlertsSection(
                  onAttemptActivation: _attemptActivation,
                ),
              ),

              // 5. Storage & Cloud Backup
              const SettingsSectionHeader(title: 'STORAGE & CLOUD'),
              const SizedBox(height: AppSpacing.xs),
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authStateProvider);
                  final user = authState.valueOrNull;
                  final isGuest = user == null;
                  return _buildCategoryCard(
                    context,
                    child: Column(
                      children: [
                        if (!isGuest) ...[
                          const DriveSyncSection(),
                          const SettingsDivider(),
                        ],
                        const StorageIntegritySection(),
                      ],
                    ),
                  );
                },
              ),

              // 6. Support & Feedback
              const SettingsSectionHeader(title: 'SUPPORT & FEEDBACK'),
              const SizedBox(height: AppSpacing.xs),
              _buildCategoryCard(
                context,
                child: Column(
                  children: [
                    SettingsListTile(
                      icon: Icons.star_rate_rounded,
                      iconColor: AppColors.warningAmber500,
                      title: 'Rate DueVault',
                      subtitle: 'Love the app? Leave a review or suggest an idea',
                      onTap: () {
                        ref.read(appReviewServiceProvider).showRatingDialog(context);
                      },
                    ),
                    const SettingsDivider(),
                    SettingsListTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: isDark ? AppColors.emerald400 : AppColors.emerald600,
                      title: 'Replay Tutorial',
                      subtitle: 'Take a quick guided tour of key features',
                      onTap: () async {
                        ref.read(bottomNavIndexProvider.notifier).state = 0;
                        ref.read(showWalkthroughProvider.notifier).state = true;

                        final repository = ref.read(vaultRepositoryProvider);
                        final config = await repository.getConfig();
                        config.hasSeenWalkthrough = false;
                        await repository.updateConfig(config);

                        if (context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // 7. Developer Options (Unlocked on 7 taps on footer)
              if (_isDevModeEnabled) ...[
                const SettingsSectionHeader(title: 'DEVELOPER'),
                const SizedBox(height: AppSpacing.xs),
                _buildCategoryCard(
                  context,
                  child: const DeveloperOptionsSection(),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              SettingsVersionFooter(
                onDevModeEnabled: () {
                  setState(() {
                    _isDevModeEnabled = true;
                  });
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
