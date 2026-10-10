import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/security_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import 'settings_dialogs.dart';
import 'settings_list_tile.dart';

class SecurityLockSection extends ConsumerWidget {
  const SecurityLockSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.emerald400 : AppColors.emerald500;

    return SettingsListTile(
      icon: Icons.fingerprint_rounded,
      title: 'Biometric Lock',
      subtitle: 'Secure entry with FaceID or Fingerprint',
      trailing: SizedBox(
        height: 24,
        child: Switch(
          value: security.isEnabled,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            if (value) {
              if (!security.canAuthenticate) {
                SettingsDialogs.showNoSecurityDialog(context);
                return;
              }
              ref.read(securityProvider.notifier).toggleSecurity(true);
              ref.read(analyticsServiceProvider).logSettingsChanged(
                    'biometric_lock_enabled',
                    true,
                  );
            } else {
              ref.read(securityProvider.notifier).toggleSecurity(false);
              ref.read(analyticsServiceProvider).logSettingsChanged(
                    'biometric_lock_enabled',
                    false,
                  );
            }
          },
          activeThumbColor: activeColor,
          activeTrackColor: activeColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
