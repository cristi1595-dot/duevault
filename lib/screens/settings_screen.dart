import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings/compact_profile_card.dart';
import 'settings/google_sign_in_section.dart';
import 'settings/interface_customization_section.dart';
import 'settings/settings_permission_helper.dart';
import 'settings/settings_section_header.dart';
import 'settings/settings_version_footer.dart';
import 'settings/smart_alerts_section.dart';
import 'settings/settings_list_tile.dart';
import '../services/app_review_service.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Account Section: Google Account or Guest Status
            const CompactProfileCard(),
            const SizedBox(height: 10),

            // Sign In with Google Option (visible only when in Guest mode)
            Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateProvider);
                final user = authState.valueOrNull;
                final isProcessing = ref.watch(isProcessingAuthSyncProvider);
                if (user == null || isProcessing) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: GoogleSignInSection(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // 2. Interface (Theme & Currency)
            const SettingsSectionHeader(title: 'INTERFACE'),
            const SizedBox(height: 5),
            _buildCategoryCard(
              context,
              child: const InterfaceCustomizationSection(),
            ),

            // 3. Alerts & Reminders
            const SettingsSectionHeader(title: 'ALERTS & NOTIFICATIONS'),
            const SizedBox(height: 5),
            _buildCategoryCard(
              context,
              child: SmartAlertsSection(
                onAttemptActivation: _attemptActivation,
              ),
            ),

            // 4. Rate DueVault
            const SettingsSectionHeader(title: 'SUPPORT'),
            const SizedBox(height: 5),
            _buildCategoryCard(
              context,
              child: SettingsListTile(
                icon: Icons.star_rate_rounded,
                title: 'Rate DueVault',
                subtitle: 'Love the app? Leave a review or suggest an idea',
                onTap: () {
                  ref.read(appReviewServiceProvider).showRatingDialog(context);
                },
              ),
            ),

            const SizedBox(height: 12),
            const SettingsVersionFooter(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
