import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Trust Badges shown on LoginScreen.
class LoginTrustBadges extends StatelessWidget {
  final bool isDark;

  const LoginTrustBadges({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadgePill(
              icon: Icons.lock_outline_rounded,
              label: 'End-to-End Encrypted',
            ),
            const SizedBox(width: 8),
            _buildBadgePill(
              icon: Icons.bolt_rounded,
              label: 'Instant Alerts',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildBadgePill(
          icon: Icons.cloud_done_rounded,
          label: 'Private Cloud Sync',
        ),
      ],
    );
  }

  Widget _buildBadgePill({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.border(isDark),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.emerald500,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
