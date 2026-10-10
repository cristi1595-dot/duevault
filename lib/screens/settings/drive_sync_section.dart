import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import 'settings_list_tile.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.emerald400 : AppColors.emerald500;

    return Column(
      children: [
        SettingsListTile(
          icon: Icons.wifi_outlined,
          title: 'Optimize Mobile Data',
          subtitle: 'Sync only via Wi-Fi network',
          trailing: SizedBox(
            height: 24,
            child: Switch(
              value: wifiOnly,
              onChanged: (v) async {
                await ref.read(wifiOnlyProvider.notifier).toggleWifiOnly(v);
              },
              activeThumbColor: activeColor,
              activeTrackColor: activeColor.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}
