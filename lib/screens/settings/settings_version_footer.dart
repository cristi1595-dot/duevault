import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class SettingsVersionFooter extends StatefulWidget {
  final VoidCallback? onDevModeEnabled;

  const SettingsVersionFooter({super.key, this.onDevModeEnabled});

  @override
  State<SettingsVersionFooter> createState() => _SettingsVersionFooterState();
}

class _SettingsVersionFooterState extends State<SettingsVersionFooter> {
  int _devModeTaps = 0;
  bool _isDevModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _devModeTaps++;
            if (_devModeTaps >= 7) {
              if (!_isDevModeEnabled) {
                _isDevModeEnabled = true;
                HapticFeedback.mediumImpact();
                widget.onDevModeEnabled?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Developer Options enabled! 🛠️'),
                    backgroundColor: isDark ? AppColors.emerald500 : AppColors.emerald600,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } else if (_devModeTaps > 2) {
              final remaining = 7 - _devModeTaps;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'You are now $remaining steps away from being a developer!',
                  ),
                  duration: const Duration(milliseconds: 500),
                ),
              );
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          child: Text(
            'Version 1.0.1',
            style: AppTypography.labelSmall(AppColors.textMuted(isDark)).copyWith(
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
