import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsVersionFooter extends StatefulWidget {
  final VoidCallback onDevModeEnabled;

  const SettingsVersionFooter({super.key, required this.onDevModeEnabled});

  @override
  State<SettingsVersionFooter> createState() => _SettingsVersionFooterState();
}

class _SettingsVersionFooterState extends State<SettingsVersionFooter> {
  int _devModeTaps = 0;
  bool _isDevModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _devModeTaps++;
            if (_devModeTaps >= 7) {
              if (!_isDevModeEnabled) {
                _isDevModeEnabled = true;
                widget.onDevModeEnabled();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Developer Options enabled! 🛠️'),
                    backgroundColor: AppTheme.safeGreen,
                    duration: Duration(seconds: 2),
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
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            'Version 1.0.0 (Pre-Beta)',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.5),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
