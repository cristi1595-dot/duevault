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

  const VaultItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onCheckPressed,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = _calculateDaysLeft(item.dueDate);
    final isOverdue = item.isOverdue;
    final bool isExpired = item.isExpired;
    final bool isBill = item.itemType == 'Bill';

    final bool isInHistory = item.isArchived || (item.isPaid && isExpired);
    final itemColor = isBill ? const Color(0xFF6366F1) : const Color(0xFF34D399);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF161A22) // Solid premium elevation
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Theme.of(context).brightness == Brightness.light
                    ? Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                        width: 1,
                      )
                    : null,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Icon Box: occupies full height
                    Container(
                      width: 52,
                      decoration: BoxDecoration(
                        color: itemColor.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              CategoryUtils.getIcon(item.category),
                              color: itemColor,
                              size: 28,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: itemColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(5),
                                  bottomLeft: Radius.circular(5),
                                ),
                              ),
                              child: Center(
                                  child: Text(
                                    isBill ? 'B' : 'D',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          4,
                          (!item.isPaid && onCheckPressed != null) ? 6 : 12,
                          4,
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
                                            return rawTitle.length > 20 ? 13.0 : 16.0;
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
                                  const SizedBox(height: 1),
                                  Text(
                                    item.dueDate != null
                                        ? '${isBill ? "Due" : "Expires"} ${item.dueDate!.day} ${_getMonthName(item.dueDate!.month)}'
                                        : (isBill ? 'No due date' : 'Permanent'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
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
                        child: Container(
                          width: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border(
                              left: BorderSide(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Color(0xFF6366F1),
                              size: 20,
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
