import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_typography.dart';

/// Styled Google Sign In Button.
class GoogleSignInButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const GoogleSignInButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border(isDark),
          width: 1.0,
        ),
        boxShadow: !isDark ? AppShadows.sm : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                height: 20,
                cacheHeight: 40,
                errorBuilder: (ctx, err, st) => Icon(
                  Icons.account_circle,
                  size: 20,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign in with Google',
                style: AppTypography.titleMedium(AppColors.textPrimary(isDark)).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
