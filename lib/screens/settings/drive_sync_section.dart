import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/app_config.dart';
import '../../widgets/global_components.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/drive_service.dart';
import 'settings_dialogs.dart';

class DriveSyncSection extends ConsumerWidget {
  const DriveSyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final autoSync = ref.watch(autoSyncProvider);
    final wifiOnly = ref.watch(wifiOnlyProvider);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'your account';

    final syncTimestamp = ref.watch(lastSyncTimestampProvider);
    final syncState = ref.watch(syncProvider);

    String lastSyncText = 'Never';
    if (syncTimestamp.valueOrNull != null) {
      lastSyncText = DateFormat('MMM dd, HH:mm').format(syncTimestamp.valueOrNull!.toLocal());
    }

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // --- 1. Auto Sync Toggle ---
          _buildSettingItem(
            context: context,
            icon: Icons.sync,
            title: 'Automated Vault Backup',
            subtitle: autoSync ? 'Last sync: $lastSyncText' : 'Backup after changes',
            trailing: SizedBox(
              height: 24,
              child: (syncState.status == SyncStatus.syncing)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: autoSync,
                      onChanged: (v) => ref.read(autoSyncProvider.notifier).toggleAutoSync(v),
                      activeThumbColor: AppTheme.primaryAction,
                      activeTrackColor: AppTheme.primaryAction.withValues(
                        alpha: 0.3,
                      ),
                    ),
            ),
          ),

          // --- 2. WiFi Only (Conditional) ---
          if (autoSync)
            _buildSettingItem(
              context: context,
              icon: Icons.wifi_outlined,
              title: 'Optimize Mobile Data',
              subtitle: 'Save mobile data',
              trailing: SizedBox(
                height: 24,
                child: Switch(
                  value: wifiOnly,
                  onChanged: (v) => ref.read(wifiOnlyProvider.notifier).toggleWifiOnly(v),
                  activeThumbColor: AppTheme.primaryAction,
                  activeTrackColor: AppTheme.primaryAction.withValues(alpha: 0.3),
                ),
              ),
            ),

          // --- 3. Manual Backup Trigger (if auto is off or forced) ---
          if (!autoSync)
            _buildSettingItem(
              context: context,
              icon: Icons.cloud_upload_outlined,
              title: 'Backup Now',
              subtitle: 'Manual push to cloud',
              onTap: () async {
                final confirm = await SettingsDialogs.showBackupNowDialog(context, userEmail);

                if (confirm != true) return;

                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Backing up to Google Drive...')),
                );

                final authService = ref.read(authServiceProvider);
                final token = await authService.getFreshAccessToken();

                if (token != null) {
                  final authHeaders = {'Authorization': 'Bearer $token'};
                  final driveService = DriveService(
                    GoogleAuthClient(authHeaders),
                  );
                  try {
                    final success = await driveService.backupDatabase();

                    // Update local config timestamp manually for manual backup
                    if (success) {
                      final isar = ref.read(isarProvider);
                      await isar.writeTxn(() async {
                        final config = await isar.collection<AppConfig>().get(0) ?? AppConfig();
                        config.lastCloudSync = DateTime.now();
                        await isar.collection<AppConfig>().put(config);
                      });
                    }

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? '✓ Backup saved to Google Drive!' : 'Backup failed. Please try again.',
                        ),
                        backgroundColor: success ? AppTheme.safeGreen : AppTheme.urgentRed,
                      ),
                    );
                  } finally {
                    driveService.dispose();
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryAction, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).textTheme.bodySmall?.color,
            size: 14,
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
