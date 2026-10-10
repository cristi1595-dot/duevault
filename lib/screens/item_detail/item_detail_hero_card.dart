import 'package:flutter/material.dart';
import '../../models/vault_item.dart';
import '../../providers/currency_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';

/// Hero Bento Card for ItemDetailScreen:
/// Shows CategorySquircleIcon, status badge, title, bold amount, and auto-pay banner.
class ItemDetailHeroCard extends StatelessWidget {
  final VaultItem item;
  final Currency currency;
  final bool isDark;
  final int daysLeft;

  const ItemDetailHeroCard({
    super.key,
    required this.item,
    required this.currency,
    required this.isDark,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final isBill = item.itemType == 'Bill';
    final displayTitle = item.title.isEmpty
        ? (isBill ? item.category : 'Document')
        : item.title;

    final statusLabel = item.isPaid
        ? (isBill ? 'PAID' : 'RENEWED')
        : (item.dueDate == null
            ? (isBill ? 'NO DUE DATE' : 'PERMANENT')
            : (daysLeft < 0
                ? (isBill ? 'OVERDUE' : 'EXPIRED')
                : (daysLeft <= 3 ? 'URGENT' : 'ACTIVE')));

    return BentoCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Squircle Thumbnail + Category and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CategorySquircleIcon(
                    item: item,
                    isBill: isBill,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.toUpperCase(),
                        style: AppTypography.labelCaps(
                          isBill ? AppColors.emerald500 : AppColors.violet500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBill ? 'Bill Item' : 'Document Vault',
                        style: AppTypography.caption(AppColors.textSecondary(isDark)),
                      ),
                    ],
                  ),
                ],
              ),
              // Unified StatusBadge
              StatusBadge(
                label: statusLabel,
                daysLeft: item.dueDate != null ? daysLeft : null,
                isPaid: item.isPaid,
                isDocument: !isBill,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Item Title
          Text(
            displayTitle,
            style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),

          // Amount (If Bill)
          if (isBill && item.amount != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currency.formatAmount(item.amount!),
                  style: AppTypography.displayLarge(AppColors.textPrimary(isDark)).copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  item.isPaid ? 'paid' : 'amount due',
                  style: AppTypography.bodySmall(AppColors.textSecondary(isDark)).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // Auto-Pay banner if active
          if (isBill && item.directDebit) ...[
            const SizedBox(height: AppSpacing.base),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: isDark ? 0.25 : 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_rounded,
                    size: 18,
                    color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Pay (Funds Reserved)',
                          style: TextStyle(
                            color: isDark ? AppColors.emerald400 : AppColors.emerald700,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Money is set aside; debited automatically on due date.',
                          style: AppTypography.caption(AppColors.textSecondary(isDark)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Contrast Container Squircle Thumbnail for Item Detail
class CategorySquircleIcon extends StatelessWidget {
  final VaultItem item;
  final bool isBill;

  const CategorySquircleIcon({
    super.key,
    required this.item,
    required this.isBill,
  });

  IconData _resolveIcon() {
    if (item.isPaid) return Icons.check_circle_rounded;
    final cat = item.category.trim().toLowerCase();
    final title = item.title.trim().toLowerCase();

    if (cat.contains('housing') || cat.contains('rent') || title.contains('rent') || title.contains('lease')) {
      return Icons.home_outlined;
    }
    if (cat.contains('utilit') || cat.contains('electr') || cat.contains('power') || title.contains('electr') || title.contains('power') || title.contains('energy')) {
      return Icons.bolt_outlined;
    }
    if (cat.contains('telecom') || cat.contains('internet') || cat.contains('wifi') || title.contains('internet') || title.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (cat.contains('auto') || cat.contains('car') || cat.contains('vehic') || title.contains('car') || title.contains('auto')) {
      return Icons.directions_car_outlined;
    }
    if (cat.contains('subscri') || cat.contains('stream') || title.contains('netflix') || title.contains('spotify') || title.contains('subscri')) {
      return Icons.subscriptions_outlined;
    }
    if (cat.contains('loan') || cat.contains('bank') || cat.contains('financ')) {
      return Icons.account_balance_outlined;
    }
    if (cat.contains('health') || cat.contains('medic')) {
      return Icons.health_and_safety_outlined;
    }
    if (!isBill) {
      if (cat.contains('ident') || title.contains('license') || title.contains('passport') || title.contains('id')) {
        return Icons.badge_outlined;
      }
      return Icons.description_outlined;
    }
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = _resolveIcon();

    final Color containerBg = item.isPaid
        ? (isBill
            ? AppColors.emerald500.withValues(alpha: 0.15)
            : AppColors.violet500.withValues(alpha: 0.15))
        : (isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9));

    final Color iconColor = item.isPaid
        ? (isBill ? AppColors.emerald500 : AppColors.violet500)
        : (isDark
            ? (isBill ? AppColors.emerald400 : AppColors.violet400)
            : (isBill ? AppColors.emerald600 : AppColors.violet600));

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isDark && !item.isPaid
            ? Border.all(color: const Color(0xFF27354A), width: 1.0)
            : Border.all(color: AppColors.border(isDark), width: 0.8),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: iconColor,
          size: 22,
        ),
      ),
    );
  }
}
