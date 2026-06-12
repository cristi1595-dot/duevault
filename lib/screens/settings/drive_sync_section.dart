import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../paywall_screen.dart';
import '../../providers/premium_provider.dart';

class DriveSyncSection extends ConsumerWidget {
  const DriveSyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final wifiOnly = ref.watch(wifiOnlyProvider);

    final syncTimestamp = ref.watch(lastSyncTimestampProvider);
    final syncState = ref.watch(syncProvider);

    String subtitleText = 'Active & Up to date';
    if (syncState.status == SyncStatus.syncing) {
      subtitleText = 'Syncing...';
    } else if (syncTimestamp.valueOrNull != null) {
      final formatted = DateFormat('MMM dd, HH:mm').format(syncTimestamp.valueOrNull!.toLocal());
      subtitleText = 'Last sync: $formatted';
    }

    return Column(
      children: [
        // --- 1. Automated Cloud Sync (Read-only) ---
        _buildSettingItem(
          context: context,
          icon: Icons.cloud_done,
          iconColor: AppTheme.getSettingsAccent(context),
          title: 'Automated Cloud Sync',
          subtitle: subtitleText,
          trailing: (syncState.status == SyncStatus.syncing)
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const SizedBox.shrink(),
        ),

        // --- 2. WiFi Only ---
        _buildSettingItem(
          context: context,
          icon: Icons.wifi_outlined,
          title: 'Optimize Mobile Data',
          subtitle: 'Save mobile data',
          trailing: SizedBox(
            height: 24,
            child: Switch(
              value: wifiOnly,
              onChanged: (v) async {
                final isPremium = ref.read(isPremiumProvider);
                if (!isPremium) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                  return;
                }
                await ref.read(wifiOnlyProvider.notifier).toggleWifiOnly(v);
              },
              activeThumbColor: AppTheme.getSettingsAccent(context),
              activeTrackColor: AppTheme.getSettingsAccent(context).withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
