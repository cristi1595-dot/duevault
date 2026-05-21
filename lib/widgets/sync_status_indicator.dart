import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/sync_provider.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    IconData iconData;
    Color iconColor;

    switch (syncState.status) {
      case SyncStatus.syncing:
        iconData = Icons.sync;
        iconColor = AppTheme.primaryAction;
        break;
      case SyncStatus.success:
        iconData = Icons.cloud_done_outlined;
        iconColor = AppTheme.safeGreen;
        break;
      case SyncStatus.error:
        iconData = Icons.cloud_off_outlined;
        iconColor = AppTheme.urgentRed;
        break;
      case SyncStatus.idle:
        iconData = Icons.cloud_queue;
        iconColor = Theme.of(
          context,
        ).textTheme.bodySmall!.color!.withValues(alpha: 0.5);
        break;
    }

    return Tooltip(
      message: syncState.status == SyncStatus.syncing
          ? 'Syncing with Google Drive...'
          : (syncState.lastSync != null
                ? 'Last sync: ${syncState.lastSync!.hour}:${syncState.lastSync!.minute.toString().padLeft(2, '0')}'
                : 'Not synced'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: syncState.status == SyncStatus.syncing
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(iconData, color: iconColor, size: 20),
      ),
    );
  }
}
