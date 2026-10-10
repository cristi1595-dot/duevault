import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/vault_item.dart';
import '../screens/item_detail_screen.dart';
import '../providers/currency_provider.dart';
import '../providers/vault_provider.dart';
import 'vault_snackbar.dart';
import '../theme/app_theme.dart';

class VaultItemTile extends ConsumerWidget {
  final VaultItem item;
  final VoidCallback? onTap;
  final VoidCallback? onCheckPressed;
  final Currency currency;
  final bool isHomeScreen;
  final bool isFirst;
  final bool isLast;
  final bool showDivider;

  const VaultItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onCheckPressed,
    required this.currency,
    this.isHomeScreen = false,
    this.isFirst = true,
    this.isLast = true,
    this.showDivider = false,
  });

  int _calculateDaysLeft(DateTime? dueDate) {
    if (dueDate == null) return 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  String _formatRemainingTime(DateTime? dueDate, bool isPaid, bool isBill) {
    final now = DateTime.now();
    if (isPaid) {
      if (dueDate == null) return isBill ? 'Paid' : 'Renewed';
      final dateStr = (dueDate.year == now.year)
          ? DateFormat('d MMM').format(dueDate)
          : DateFormat('d MMM yyyy').format(dueDate);
      return isBill ? 'Paid • $dateStr' : 'Exp: $dateStr';
    }
    if (dueDate == null) return isBill ? 'No due date' : 'Permanent';
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days = due.difference(today).inDays;

    if (days < 0) {
      final dateStr = (dueDate.year == now.year)
          ? DateFormat('d MMM').format(dueDate)
          : DateFormat('d MMM yyyy').format(dueDate);
      return isBill ? 'Overdue • $dateStr' : 'Exp: $dateStr';
    }
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    // Până la 3 luni -> '14 days left', '23 days left', etc.
    if (days <= 90) {
      return '$days days left';
    }
    // Peste 3 luni, până la 1 an -> '3 months', '11 months', etc.
    if (days <= 365) {
      final months = (days / 30).round();
      return months <= 1 ? '1 month' : '$months months';
    }
    // Peste 1 an -> '1 year', '5 years', etc.
    final years = (days / 365).round();
    return years <= 1 ? '1 year' : '$years years';
  }

  Widget _buildDuePill(BuildContext context, VaultItem item, bool isBill, bool isDark) {
    final label = _formatRemainingTime(item.dueDate, item.isPaid, isBill);
    final daysLeft = _calculateDaysLeft(item.dueDate);
    final isOverdue = item.isOverdue;

    final Color dotColor;

    if (item.isPaid) {
      dotColor = AppColors.statusSafeText(isDark);
    } else if (item.dueDate == null) {
      dotColor = isDark ? AppColors.slate500 : AppColors.slate400;
    } else if (isOverdue) {
      dotColor = AppColors.statusUrgentText(isDark);
    } else if (daysLeft <= 3) {
      dotColor = AppColors.statusUrgentText(isDark);
    } else if (daysLeft <= 7) {
      dotColor = AppColors.statusWarningText(isDark);
    } else {
      dotColor = AppColors.statusSafeText(isDark);
    }

    final Color pillBg = AppColors.surfaceElevated(isDark);
    final Color textColor = AppColors.textSecondary(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? AppColors.border(isDark) : AppColors.slate200,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBill = item.itemType == 'Bill';
    final isInHistory = item.isArchived || (item.isPaid && item.isExpired);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = AppColors.surface(isDark);
    final borderColor = AppColors.border(isDark);

    final rawTitle = item.title.isEmpty ? (isBill ? item.category : 'Document') : item.title;
    final displayTitle = rawTitle.length > 40 ? '${rawTitle.substring(0, 37)}...' : rawTitle;

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? AppRadius.xl : 0),
      topRight: Radius.circular(isFirst ? AppRadius.xl : 0),
      bottomLeft: Radius.circular(isLast ? AppRadius.xl : 0),
      bottomRight: Radius.circular(isLast ? AppRadius.xl : 0),
    );

    final border = Border(
      top: isFirst ? BorderSide(color: borderColor, width: 1.0) : BorderSide.none,
      bottom: isLast ? BorderSide(color: borderColor, width: 1.0) : BorderSide.none,
      left: BorderSide(color: borderColor, width: 1.0),
      right: BorderSide(color: borderColor, width: 1.0),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Dismissible(
        key: ValueKey(item.id),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              await HapticFeedback.mediumImpact();
              if (!context.mounted) return false;
              return showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface(isDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    side: BorderSide(color: AppColors.border(isDark)),
                  ),
                  title: Text(
                    'Delete Item?',
                    style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
                  ),
                  content: Text(
                    'Are you sure you want to permanently delete "${item.title}"? This cannot be undone.',
                    style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context, false);
                      },
                      child: Text(
                        'CANCEL',
                        style: TextStyle(color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, true);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.urgentRose600,
                      ),
                      child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }
            return true;
          },
          onDismissed: (direction) async {
            await HapticFeedback.mediumImpact();
            final notifier = ref.read(vaultProvider.notifier);
            if (direction == DismissDirection.startToEnd) {
              if (isInHistory) {
                await notifier.toggleArchiveStatus(item.id, false);
                VaultSnackBar.show(
                  message: 'Restored to Vault',
                  actionLabel: 'UNDO',
                  backgroundColor: AppColors.infoBlue500,
                  onAction: () async {
                    if (item.isArchived) {
                      await notifier.toggleArchiveStatus(item.id, true);
                    }
                    if (item.isPaid) {
                      await notifier.updatePaidStatus(item.id, true);
                    }
                  },
                );
              } else {
                final wasPaid = item.isPaid;
                await notifier.toggleArchiveStatus(item.id, true);
                VaultSnackBar.show(
                  message: 'Moved to History',
                  actionLabel: 'UNDO',
                  backgroundColor: AppColors.emerald500,
                  onAction: () async {
                    await notifier.toggleArchiveStatus(item.id, false);
                    if (wasPaid) {
                      await notifier.updatePaidStatus(item.id, true);
                    }
                  },
                );
              }
            } else {
              final deletedItem = item;
              await notifier.deleteItem(item.id);
              VaultSnackBar.show(
                message: 'Item deleted',
                actionLabel: 'UNDO',
                backgroundColor: AppColors.urgentRose600,
                onAction: () => notifier.addItem(deletedItem),
              );
            }
          },
          background: Container(
            color: isInHistory ? AppColors.infoBlue500 : AppColors.emerald500,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  isInHistory ? Icons.unarchive_rounded : Icons.archive_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Text(
                  isInHistory ? 'Vault' : 'Archive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            color: AppColors.urgentRose600,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(width: 14),
                Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ],
            ),
          ),
          child: Material(
            color: cardBg,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                if (onTap != null) {
                  onTap!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(item: item),
                    ),
                  );
                }
              },
              borderRadius: borderRadius,
              child: Opacity(
                opacity: item.isPaid ? 0.65 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: border,
                    boxShadow: (!isDark && isLast) ? AppShadows.sm : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 59.2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                    // 1. Icon Container
                    _VaultItemThumbnail(item: item, isBill: isBill),
                    const SizedBox(width: 12),

                    // 2. Center Column: Row 1 = Name, Row 2 = Amount (Bold & Star) / Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isBill ? 14.5 : 16,
                              fontWeight: isBill ? FontWeight.w500 : FontWeight.w600,
                              letterSpacing: -0.2,
                              height: 1.15,
                              decoration: item.isPaid ? TextDecoration.lineThrough : null,
                              color: item.isPaid
                                  ? AppColors.textMuted(isDark)
                                  : (isBill
                                      ? AppColors.textSecondary(isDark)
                                      : AppColors.textPrimary(isDark)),
                            ),
                          ),
                          if (isBill) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  currency.formatAmount(item.amount ?? 0.0),
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                    color: item.isPaid
                                        ? AppColors.textMuted(isDark)
                                        : AppColors.textPrimary(isDark),
                                  ),
                                ),
                                if (item.recurrence.isNotEmpty && item.recurrence != 'None') ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '• ${item.recurrence}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.15,
                                      color: AppColors.textMuted(isDark),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. Right Block: Due Date / Remaining Time Pill
                    _buildDuePill(context, item, isBill, isDark),

                    // 4. Quick Checkmark Button (if onCheckPressed != null)
                    if (onCheckPressed != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onCheckPressed?.call();
                        },
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isPaid
                                  ? AppColors.emerald500
                                  : (isDark
                                      ? const Color(0xFF1E2638)
                                      : const Color(0xFFF1F5F9)),
                              border: Border.all(
                                color: item.isPaid
                                    ? AppColors.emerald500
                                    : (isDark
                                        ? AppColors.border(isDark)
                                        : AppColors.slate300),
                                width: 1.4,
                              ),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: item.isPaid
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.slate500
                                      : AppColors.slate400),
                            ),
                          ),
                        ),
                      ),
                      ],
                    ],
                  ),
                ),
              ),
              if (showDivider)
                Container(
                  margin: const EdgeInsets.only(left: 64, right: 14),
                  height: 0.8,
                  color: isDark ? const Color(0xFF1E2838) : AppColors.slate200,
                ),
            ],
          ),
        ),
      ),
    ),
  ),
),
);
  }
}

class _VaultItemThumbnail extends StatelessWidget {
  final VaultItem item;
  final bool isBill;

  const _VaultItemThumbnail({
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
            : AppColors.infoBlue500.withValues(alpha: 0.15))
        : (isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9));

    final Color iconColor;
    if (item.isPaid) {
      iconColor = isBill
          ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
          : (isDark ? AppColors.infoBlue400 : AppColors.infoBlue700);
    } else {
      if (isDark) {
        iconColor = isBill
            ? AppColors.emerald400.withValues(alpha: 0.85)
            : AppColors.infoBlue400.withValues(alpha: 0.85);
      } else {
        iconColor = isBill
            ? AppColors.emerald600.withValues(alpha: 0.9)
            : AppColors.infoBlue700.withValues(alpha: 0.9);
      }
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isDark && !item.isPaid
            ? Border.all(color: AppColors.border(isDark), width: 1.0)
            : null,
      ),
      child: Center(
        child: Icon(
          iconData,
          color: iconColor,
          size: 19,
        ),
      ),
    );
  }
}
