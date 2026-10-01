import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_item.dart';
import '../screens/item_detail_screen.dart';
import '../providers/currency_provider.dart';
import '../providers/vault_provider.dart';
import '../constants/app_categories.dart';
import '../providers/category_provider.dart';
import 'status_badge.dart';
import 'vault_snackbar.dart';
import '../theme/app_theme.dart';

class CategoryUtils {
  static IconData getIcon(String category) {
    return AppCategories.getIcon(category);
  }
}

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryProvider.notifier).getCategory(item.category);
    final daysLeft = _calculateDaysLeft(item.dueDate);
    final isOverdue = item.isOverdue;
    final bool isExpired = item.isExpired;
    final bool isBill = item.itemType == 'Bill';

    final bool isInHistory = item.isArchived || (item.isPaid && isExpired);

    final Color statusColor;
    if (item.isPaid) {
      statusColor = AppTheme.getMintGreen(context); // Mint Sage
    } else if (isOverdue || (daysLeft <= 3)) {
      statusColor = const Color(0xFFE11D48); // Red
    } else if (daysLeft <= 7) {
      statusColor = const Color(0xFFF59E0B); // Amber
    } else {
      statusColor = AppTheme.getSafeGreen(context); // Green (safe zone > 7 days)
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardBg = isDark ? const Color(0xFF161A22) : Colors.white;

    if (isHomeScreen && !isInHistory) {
      final double tintOpacity = isDark ? 0.04 : 0.03;
      cardBg = Color.alphaBlend(
        statusColor.withValues(alpha: tintOpacity),
        cardBg,
      );
    }

    final displayTitle = item.title.isEmpty ? item.category : item.title;
    final recurrenceSuffix = (item.recurrence != 'None' && item.recurrence.isNotEmpty)
        ? ' • ${item.recurrence}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Show confirmation only for DELETE
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
                        foregroundColor: const Color(0xFFE11D48),
                      ),
                      child: const Text('DELETE'),
                    ),
                  ],
                ),
              );
            }
            // For Archive, we don't need a dialog as it's easily reversible
            return true;
          },
          onDismissed: (direction) {
            final notifier = ref.read(vaultProvider.notifier);
            if (direction == DismissDirection.startToEnd) {
              // ARCHIVE / RESTORE Logic (Swipe Right)
              if (isInHistory) {
                // If it's in history, "Restore to Vault" means unarchive AND unpay (if it was paid/expired)
                // toggleArchiveStatus(item.id, false) now handles both atomically.
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
                // Normal Archive
                final wasPaid = item.isPaid;
                notifier.toggleArchiveStatus(item.id, true);
                VaultSnackBar.show(
                  message: 'Moved to History',
                  actionLabel: 'UNDO',
                  backgroundColor: const Color(0xFF34D399),
                  onAction: () async {
                    await notifier.toggleArchiveStatus(item.id, false);
                    if (wasPaid) {
                      await notifier.updatePaidStatus(item.id, true);
                    }
                  },
                );
              }
            } else {
              // DELETE Logic (Swipe Left)
              final deletedItem = item;
              notifier.deleteItem(item.id);
              VaultSnackBar.show(
                message: 'Item deleted',
                actionLabel: 'UNDO',
                backgroundColor: const Color(0xFFE11D48),
                onAction: () => notifier.addItem(deletedItem),
              );
            }
          },
          background: Container(
            color: isInHistory ? const Color(0xFF6366F1) : const Color(0xFF34D399),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  isInHistory ? Icons.unarchive_rounded : Icons.archive_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  isInHistory ? 'Vault' : 'Archive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            color: const Color(0xFFE11D48),
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
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 16),
                Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
          child: InkWell(
            onTap:
                onTap ??
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
              opacity: item.isPaid ? 0.6 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark
                      ? (isHomeScreen && !isInHistory
                          ? Border.all(
                              color: statusColor.withValues(alpha: 0.20),
                              width: 1.0,
                            )
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1.0,
                            ))
                      : Border.all(
                          color: isHomeScreen && !isInHistory
                              ? statusColor.withValues(alpha: 0.20)
                              : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Icon
                    _VaultItemThumbnail(
                      item: item,
                      categoryColor: category.color,
                      categoryIcon: category.icon,
                      isBill: isBill,
                    ),
                    const SizedBox(width: 12),

                    // Middle: Title & Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  decoration: item.isPaid
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isPaid
                                      ? Theme.of(context).textTheme.bodyMedium?.color
                                      : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: category.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: category.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.dueDate != null
                                      ? '${isBill ? "Due" : "Exp"} ${item.dueDate!.day} ${_getMonthName(item.dueDate!.month)}$recurrenceSuffix'
                                      : '${isBill ? "No due date" : "Permanent"}$recurrenceSuffix',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              if (item.attachedFiles.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 13,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right: Amount & Status Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isBill) ...[
                          Text(
                            currency.formatAmount(item.amount ?? 0.0),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        StatusBadge(
                          isDocument: !isBill,
                          label: item.isPaid
                              ? (isBill ? 'PAID' : 'RENEWED')
                              : (item.dueDate == null
                                  ? 'PERMANENT'
                                  : (isOverdue
                                      ? (isBill ? 'OVERDUE' : 'EXPIRED')
                                      : (daysLeft == 0
                                          ? 'TODAY'
                                          : '$daysLeft DAYS'))),
                          isPaid: item.isPaid,
                          daysLeft: (item.isPaid || item.dueDate == null) ? null : daysLeft,
                        ),
                      ],
                    ),

                    // Checkmark Action
                    if (onCheckPressed != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onCheckPressed!();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.isPaid
                                ? AppTheme.getSafeGreen(context)
                                : (isDark ? const Color(0xFF252A36) : const Color(0xFFEFF2F6)),
                            border: Border.all(
                              color: item.isPaid
                                  ? AppTheme.getSafeGreen(context)
                                  : (isDark ? const Color(0xFF3B4254) : const Color(0xFFCBD5E1)),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: item.isPaid
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              size: 18,
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

  int _calculateDaysLeft(DateTime? dueDate) {
    if (dueDate == null) return 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _VaultItemThumbnail extends StatelessWidget {
  final VaultItem item;
  final Color categoryColor;
  final IconData categoryIcon;
  final bool isBill;

  const _VaultItemThumbnail({
    required this.item,
    required this.categoryColor,
    required this.categoryIcon,
    required this.isBill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.12),
        shape: isBill ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isBill ? null : BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          categoryIcon,
          color: categoryColor,
          size: 22,
        ),
      ),
    );
  }
}
