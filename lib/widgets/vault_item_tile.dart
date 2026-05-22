import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_item.dart';
import '../screens/item_detail_screen.dart';
import '../providers/currency_provider.dart';
import '../providers/vault_provider.dart';
import '../constants/app_categories.dart';
import 'status_badge.dart';
import 'vault_snackbar.dart';

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
    final daysLeft = _calculateDaysLeft(item.dueDate);
    final isOverdue = item.isOverdue;
    final bool isExpired = item.isExpired;
    final bool isBill = item.itemType == 'Bill';

    final bool isInHistory = item.isArchived || (item.isPaid && isExpired);
    final itemColor = isBill ? const Color(0xFF6366F1) : const Color(0xFF34D399);

    final Color statusColor;
    if (item.isPaid) {
      statusColor = const Color(0xFF34D399); // Mint Sage
    } else if (isOverdue || (daysLeft <= 3)) {
      statusColor = const Color(0xFFE11D48); // Red
    } else if (daysLeft <= 7) {
      statusColor = const Color(0xFFF59E0B); // Amber
    } else {
      statusColor = const Color(0xFF10B981); // Green (safe zone > 7 days)
    }

    Color cardBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF161A22)
        : (Theme.of(context).cardTheme.color ?? Colors.white);

    if (isHomeScreen && !isInHistory) {
      cardBg = Color.alphaBlend(
        statusColor.withValues(alpha: 0.04),
        cardBg,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
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
                if (item.isArchived) {
                  notifier.toggleArchiveStatus(item.id, false);
                }
                if (item.isPaid) {
                  notifier.updatePaidStatus(item.id, false);
                }
                VaultSnackBar.show(
                  message: 'Restored to Vault',
                  actionLabel: 'UNDO',
                  backgroundColor: const Color(0xFF6366F1),
                  onAction: () {
                    if (item.isArchived) {
                      notifier.toggleArchiveStatus(item.id, true);
                    }
                    if (item.isPaid) {
                      notifier.updatePaidStatus(item.id, true);
                    }
                  },
                );
              } else {
                // Normal Archive
                notifier.toggleArchiveStatus(item.id, true);
                VaultSnackBar.show(
                  message: 'Moved to History',
                  actionLabel: 'UNDO',
                  backgroundColor: const Color(0xFF34D399),
                  onAction: () => notifier.toggleArchiveStatus(item.id, false),
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
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: isHomeScreen && !isInHistory
                    ? Border.all(
                        color: statusColor.withValues(alpha: 0.15),
                        width: 1.2,
                      )
                    : (Theme.of(context).brightness == Brightness.light
                        ? Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                            width: 1,
                          )
                        : null),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Icon Box: occupies full height
                    Container(
                      width: 57,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: 0.08),
                            shape: isBill ? BoxShape.circle : BoxShape.rectangle,
                            borderRadius: isBill
                                ? null
                                : BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              CategoryUtils.getIcon(item.category),
                              color: itemColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          13,
                          5,
                          (!item.isPaid && onCheckPressed != null) ? 3 : 13,
                          5,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    () {
                                      final rawTitle = item.title.isEmpty
                                          ? item.category
                                          : item.title;
                                      return rawTitle.length > 40
                                          ? '${rawTitle.substring(0, 37)}...'
                                          : rawTitle;
                                    }(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          fontSize: () {
                                            final rawTitle = item.title.isEmpty
                                                ? item.category
                                                : item.title;
                                            return rawTitle.length > 20 ? 14.5 : 17.5;
                                          }(),
                                          height: 1.1,
                                          decoration: item.isPaid
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: item.isPaid
                                              ? Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.color
                                              : Theme.of(context).textTheme.bodyLarge?.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.dueDate != null
                                        ? '${isBill ? "Bill • Due" : "Doc • Exp"} ${item.dueDate!.day} ${_getMonthName(item.dueDate!.month)}'
                                        : (isBill ? 'Bill • No due date' : 'Doc • Permanent'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.45)
                                          : Colors.black.withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 9),
                            SizedBox(
                              width: 110,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isBill) ...[
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        currency.formatAmount(item.amount ?? 0.0),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                          letterSpacing: -0.2,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right Checkmark Button: occupies full height, flush to edge
                    if (!item.isPaid && onCheckPressed != null)
                      GestureDetector(
                        onTap: onCheckPressed,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 48,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 33,
                              height: 33,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF6366F1).withValues(alpha: 0.06),
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                                  width: 1.3,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF6366F1),
                                  size: 23,
                                ),
                              ),
                            ),
                          ),
                        ),
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
