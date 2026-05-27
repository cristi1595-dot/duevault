import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 1.6, top: 1.6),
      child: Text(
        title,
        style: AppTheme.labelCapsStyle(context).copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 14.4,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
