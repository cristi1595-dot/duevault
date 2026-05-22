import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings/compact_profile_card.dart';
import 'settings/developer_options_section.dart';
import 'settings/drive_sync_section.dart';
import 'settings/google_sign_in_section.dart';
import 'settings/interface_customization_section.dart';
import 'settings/security_lock_section.dart';
import 'settings/settings_permission_helper.dart';
import 'settings/settings_version_footer.dart';
import 'settings/smart_alerts_section.dart';
import 'settings/storage_integrity_section.dart';

import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool? _isBatteryOptimizationDisabled;
  bool _isNotificationPermissionGranted = true;
  bool _isExactAlarmGranted = true;
  bool _isDevModeEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
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
    await _checkStatus();
    if (!mounted) return;

    await SettingsPermissionHelper.checkStatusAndAutoEnable(ref);
    await _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await SettingsPermissionHelper.checkStatus();
    if (mounted) {
      setState(() {
        _isBatteryOptimizationDisabled = status['batteryDisabled'];
        _isNotificationPermissionGranted = status['notificationsGranted']!;
        _isExactAlarmGranted = status['exactAlarmGranted']!;
      });
    }
  }

  Future<void> _attemptActivation({required bool targetState}) async {
    await SettingsPermissionHelper.attemptActivation(
      targetState: targetState,
      ref: ref,
      context: context,
      onStatusUpdated: (status) {
        if (mounted) {
          setState(() {
            _isBatteryOptimizationDisabled = status['batteryDisabled'];
            _isNotificationPermissionGranted = status['notificationsGranted']!;
            _isExactAlarmGranted = status['exactAlarmGranted']!;
          });
        }
      },
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Header
            const CompactProfileCard(),
            const SizedBox(height: 6),

            // 1.1 Sign In Option (Only for Guests) - Directly under Guest User
            Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateProvider);
                final user = authState.valueOrNull;
                final isProcessing = ref.watch(isProcessingAuthSyncProvider);
                if (user == null || isProcessing) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: GoogleSignInSection(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // 1.5 Biometric Lock (Security)
            const SecurityLockSection(),
            const SizedBox(height: 4),

            // 2. Sync Options (Only for Authenticated Users)
            const DriveSyncSection(),
            const SizedBox(height: 4),

            // 3. Preferences Section
            const InterfaceCustomizationSection(),
            const SizedBox(height: 4),

            // 4. Alerts & Notifications Section
            SmartAlertsSection(
              isBatteryOptimizationDisabled: _isBatteryOptimizationDisabled,
              isNotificationPermissionGranted: _isNotificationPermissionGranted,
              isExactAlarmGranted: _isExactAlarmGranted,
              onAttemptActivation: _attemptActivation,
            ),
            const SizedBox(height: 4),

            const StorageIntegritySection(),
            if (_isDevModeEnabled) ...[
              const SizedBox(height: 4),
              const DeveloperOptionsSection(),
            ],
            const SizedBox(height: 16),
            SettingsVersionFooter(
              onDevModeEnabled: () {
                setState(() {
                  _isDevModeEnabled = true;
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
