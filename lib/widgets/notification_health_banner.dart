import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../screens/settings/settings_permission_helper.dart';
import '../theme/app_theme.dart';

/// A modern, non-intrusive warning banner displayed on the Home screen
/// when system notification or exact alarm permissions have been revoked by Android OS updates.
class NotificationHealthBanner extends ConsumerWidget {
  const NotificationHealthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthStatus = ref.watch(notificationHealthProvider);

    if (healthStatus != NotificationHealthStatus.permissionRevoked) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const warningColor = AppTheme.warningYellow;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warningColor.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              color: warningColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Notificări dezactivate de sistem',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Apasă mai jos pentru a reactiva alarmele.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: warningColor,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              await SettingsPermissionHelper.attemptActivation(
                targetState: true,
                ref: ref,
                context: context,
                onStatusUpdated: (_) {
                  ref.read(notificationHealthProvider.notifier).checkHealth();
                },
              );
              await ref.read(notificationHealthProvider.notifier).checkHealth();
            },
            child: const Text('Reactivează'),
          ),
        ],
      ),
    );
  }
}
