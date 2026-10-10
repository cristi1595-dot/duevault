import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vault_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';

/// Timeline and Schedule Bento Card for ItemDetailScreen:
/// Shows payment or expiration timeline, recurrence badge, and prominent countdown pill.
class ItemDetailTimelineCard extends StatelessWidget {
  final VaultItem item;
  final bool isDark;
  final int daysLeft;
  final Color dueDateColor;

  const ItemDetailTimelineCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.daysLeft,
    required this.dueDateColor,
  });

  @override
  Widget build(BuildContext context) {
    final isBill = item.itemType == 'Bill';

    return BentoCard(
      padding: AppSpacing.cardPaddingLg,
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBill ? 'PAYMENT TIMELINE' : 'EXPIRATION TIMELINE',
                style: AppTypography.labelCaps(AppColors.textSecondary(isDark)),
              ),
              if (item.recurrence != 'None' && item.recurrence.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated(isDark),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.border(isDark),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 12,
                        color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        item.recurrence,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.emerald400 : AppColors.emerald700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Date block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dueDate != null
                          ? DateFormat('EEEE, d MMMM yyyy').format(item.dueDate!)
                          : (isBill ? 'No due date set' : 'Permanent document'),
                      style: AppTypography.titleMedium(dueDateColor).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBill ? 'Due Date' : 'Expiry Date',
                      style: AppTypography.caption(AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),

              // Prominent Countdown Pill
              if (item.dueDate != null)
                _buildCountdownPill(item, daysLeft, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownPill(VaultItem item, int daysLeft, bool isDark) {
    Color color;
    Color bg;
    String text;

    if (item.isPaid) {
      color = AppColors.statusSafeText(isDark);
      bg = AppColors.safeEmerald500.withValues(alpha: isDark ? 0.15 : 0.1);
      text = 'Settled';
    } else if (daysLeft < 0) {
      color = AppColors.statusUrgentText(isDark);
      bg = AppColors.urgentRose500.withValues(alpha: isDark ? 0.15 : 0.1);
      final count = daysLeft.abs();
      text = count == 1 ? '1 day late' : '$count days late';
    } else if (daysLeft == 0) {
      color = AppColors.statusUrgentText(isDark);
      bg = AppColors.urgentRose500.withValues(alpha: isDark ? 0.15 : 0.1);
      text = 'Due Today';
    } else if (daysLeft == 1) {
      color = AppColors.statusUrgentText(isDark);
      bg = AppColors.urgentRose500.withValues(alpha: isDark ? 0.15 : 0.1);
      text = 'Tomorrow';
    } else if (daysLeft <= 3) {
      color = AppColors.statusUrgentText(isDark);
      bg = AppColors.urgentRose500.withValues(alpha: isDark ? 0.15 : 0.1);
      text = 'In $daysLeft days';
    } else if (daysLeft <= 7) {
      color = AppColors.statusWarningText(isDark);
      bg = AppColors.warningAmber500.withValues(alpha: isDark ? 0.15 : 0.1);
      text = 'In $daysLeft days';
    } else {
      color = AppColors.statusSafeText(isDark);
      bg = AppColors.safeEmerald500.withValues(alpha: isDark ? 0.15 : 0.1);
      text = 'In $daysLeft days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
