import 'package:flutter/material.dart';
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

  const VaultItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onCheckPressed,
    required this.currency,
    this.isHomeScreen = false,
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
      dotColor = AppTheme.primaryAction;
    } else if (item.dueDate == null) {
      dotColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    } else if (isOverdue) {
      dotColor = AppTheme.urgentRed;
    } else if (daysLeft <= 3) {
      dotColor = AppTheme.warningYellow;
    } else {
      dotColor = AppTheme.primaryAction;
    }

    final Color pillBg = isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9);
    final Color textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF27354A), width: 0.8) : null,
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
              fontSize: 11.5,
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

    final cardBg = isDark ? const Color(0xFF161F30) : Colors.white;
    final borderColor = isDark ? const Color(0xFF222F48) : const Color(0xFFE2E8F0);

    final rawTitle = item.title.isEmpty ? (isBill ? item.category : 'Document') : item.title;
    final displayTitle = rawTitle.length > 40 ? '${rawTitle.substring(0, 37)}...' : rawTitle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              return showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Item?'),
                  content: Text(
                    'Are you sure you want to permanently delete "${item.title}"? This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.urgentRed,
                      ),
                      child: const Text('DELETE'),
                    ),
                  ],
                ),
              );
            }
            return true;
          },
          onDismissed: (direction) {
            final notifier = ref.read(vaultProvider.notifier);
            if (direction == DismissDirection.startToEnd) {
              if (isInHistory) {
                notifier.toggleArchiveStatus(item.id, false);
                VaultSnackBar.show(
                  message: 'Restored to Vault',
                  actionLabel: 'UNDO',
                  backgroundColor: const Color(0xFF6366F1),
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
                notifier.toggleArchiveStatus(item.id, true);
                VaultSnackBar.show(
                  message: 'Moved to History',
                  actionLabel: 'UNDO',
                  backgroundColor: AppTheme.primaryAction,
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
              notifier.deleteItem(item.id);
              VaultSnackBar.show(
                message: 'Item deleted',
                actionLabel: 'UNDO',
                backgroundColor: AppTheme.urgentRed,
                onAction: () => notifier.addItem(deletedItem),
              );
            }
          },
          background: Container(
            color: isInHistory ? const Color(0xFF6366F1) : AppTheme.primaryAction,
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
            color: AppTheme.urgentRed,
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
          child: InkWell(
            onTap: onTap ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(item: item),
                    ),
                  );
                },
            borderRadius: BorderRadius.circular(16),
            child: Opacity(
              opacity: item.isPaid ? 0.65 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              fontSize: isBill ? 14 : 18,
                              fontWeight: isBill ? FontWeight.w500 : FontWeight.w600,
                              letterSpacing: -0.2,
                              decoration: item.isPaid ? TextDecoration.lineThrough : null,
                              color: item.isPaid
                                  ? (isDark ? Colors.grey.shade500 : Colors.grey.shade400)
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: item.isPaid
                                        ? (isDark ? Colors.grey.shade500 : Colors.grey.shade400)
                                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                ),
                                if (item.recurrence.isNotEmpty && item.recurrence != 'None') ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '• ${item.recurrence}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
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
                        onTap: onCheckPressed,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isPaid
                                  ? AppTheme.primaryAction
                                  : (isDark
                                      ? const Color(0xFF1E2638)
                                      : const Color(0xFFF1F5F9)),
                              border: Border.all(
                                color: item.isPaid
                                    ? AppTheme.primaryAction
                                    : (isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1)),
                                width: 1.4,
                              ),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: item.isPaid
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ),
                    ],
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
            ? AppTheme.primaryAction.withValues(alpha: 0.15)
            : const Color(0xFF6366F1).withValues(alpha: 0.15))
        : (isDark ? const Color(0xFF1E2838) : const Color(0xFFF1F5F9));

    final Color iconColor;
    if (item.isPaid) {
      iconColor = isBill ? AppTheme.primaryAction : const Color(0xFF6366F1);
    } else {
      if (isDark) {
        // Verdele de la next 30 days bills (#10B981) si indigo-ul de la docs (#6366F1), ceva mai sters
        iconColor = isBill
            ? const Color(0xFF10B981).withValues(alpha: 0.72)
            : const Color(0xFF6366F1).withValues(alpha: 0.72);
      } else {
        iconColor = isBill
            ? const Color(0xFF059669).withValues(alpha: 0.80)
            : const Color(0xFF4F46E5).withValues(alpha: 0.80);
      }
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        border: isDark && !item.isPaid
            ? Border.all(color: const Color(0xFF27354A), width: 1.0)
            : null,
      ),
      child: Center(
        child: Icon(
          iconData,
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }
}
