import 'package:flutter/material.dart';
import '../../services/encryption_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';

/// Notes and Remarks Bento Card for ItemDetailScreen:
/// Decrypts encrypted notes asynchronously with fallback shimmer.
class ItemDetailNotesCard extends StatelessWidget {
  final String notes;
  final bool isDark;

  const ItemDetailNotesCard({
    super.key,
    required this.notes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: AppSpacing.cardPaddingLg,
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 16,
                color: isDark ? AppColors.emerald400 : AppColors.emerald600,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'NOTES & REMARKS',
                style: AppTypography.labelCaps(AppColors.textSecondary(isDark)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<String?>(
            future: EncryptionService.decryptText(notes),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Text(
                  snapshot.data ?? '',
                  style: AppTypography.bodyMedium(AppColors.textPrimary(isDark)).copyWith(
                    height: 1.5,
                  ),
                );
              }
              return const AppShimmer.box(width: double.infinity, height: 38);
            },
          ),
        ],
      ),
    );
  }
}
