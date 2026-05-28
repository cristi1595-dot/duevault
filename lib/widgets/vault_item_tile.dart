import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_item.dart';
import '../screens/item_detail_screen.dart';
import '../providers/currency_provider.dart';
import '../providers/vault_provider.dart';
import '../constants/app_categories.dart';
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
    final daysLeft = _calculateDaysLeft(item.dueDate);
    final isOverdue = item.isOverdue;
    final bool isExpired = item.isExpired;
    final bool isBill = item.itemType == 'Bill';

    final bool isInHistory = item.isArchived || (item.isPaid && isExpired);
    final itemColor = isBill ? const Color(0xFF6366F1) : AppTheme.getMintGreen(context);

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

    final screenWidth = MediaQuery.of(context).size.width;
    final double textColumnWidth = screenWidth -
        20 - // List horizontal padding
        57 - // Left Icon Box
        13 - // Left padding of the middle section
        ((onCheckPressed != null) ? 3 : 13) - // Right padding of the middle section
        9 - // Gap between text and right columns
        110 - // Right column width
        ((onCheckPressed != null) ? 56 : 0); // Right checkmark button

    final rawTitle = item.title.isEmpty ? item.category : item.title;
    final displayTitle = rawTitle.length > 40 ? '${rawTitle.substring(0, 37)}...' : rawTitle;
    final fontSize = rawTitle.length > 20 ? 14.5 : 17.5;
    final recurrenceSuffix = (item.recurrence != 'None' && item.recurrence.isNotEmpty)
        ? ' • ${item.recurrence}'
        : '';

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayTitle,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: fontSize,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textColumnWidth > 0 ? textColumnWidth : 150);

    final isTwoLines = textPainter.didExceedMaxLines || textPainter.height > (fontSize * 1.5);
    final gapHeight = isTwoLines ? 2.0 : 10.0;

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
            borderRadius: BorderRadius.circular(18),
            child: Opacity(
              opacity: item.isPaid ? 0.6 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: isDark
                      ? (isHomeScreen && !isInHistory
                          ? Border.all(
                              color: statusColor.withValues(alpha: 0.15),
                              width: 1.2,
                            )
                          : null)
                      : Border.all(
                          color: isHomeScreen && !isInHistory
                              ? statusColor.withValues(alpha: 0.10)
                              : const Color(0xFFE2E8F0),
                          width: 1,
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
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Icon Box: occupies full height
                    Container(
                      width: 57,
                      constraints: const BoxConstraints(minHeight: 60),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                      child: Center(
                        child: _VaultItemThumbnail(
                          item: item,
                          itemColor: itemColor,
                          isBill: isBill,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          13,
                          2,
                          (onCheckPressed != null) ? 3 : 13,
                          2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontSize: fontSize,
                                          height: 1.1,
                                          decoration: item.isPaid
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: item.isPaid
                                              ? Theme.of(context).textTheme.bodyMedium?.color
                                              : Theme.of(context).textTheme.bodyLarge?.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  SizedBox(height: gapHeight),
                                  Text(
                                    item.dueDate != null
                                        ? '${isBill ? "Bill • Due" : "Doc • Exp"} ${item.dueDate!.day} ${_getMonthName(item.dueDate!.month)}$recurrenceSuffix'
                                        : '${isBill ? "Bill • No due date" : "Doc • Permanent"}$recurrenceSuffix',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    if (onCheckPressed != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCheckPressed,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                          child: SizedBox(
                            width: 56,
                            child: Center(
                              child: Container(
                                width: 33,
                                height: 33,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.isPaid
                                      ? AppTheme.getSafeGreen(context)
                                      : const Color(0xFF6366F1).withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: item.isPaid
                                        ? AppTheme.getSafeGreen(context)
                                        : const Color(0xFF6366F1).withValues(alpha: 0.25),
                                    width: 1.3,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: item.isPaid ? Colors.white : const Color(0xFF6366F1),
                                    size: 23,
                                  ),
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
  final Color itemColor;
  final bool isBill;

  const _VaultItemThumbnail({
    required this.item,
    required this.itemColor,
    required this.isBill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: itemColor.withValues(alpha: 0.08),
        shape: isBill ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isBill ? null : BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          CategoryUtils.getIcon(item.category),
          color: itemColor,
          size: 24,
        ),
      ),
    );
  }
}
