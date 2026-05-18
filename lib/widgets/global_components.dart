import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/vault_item.dart';
import '../screens/item_detail_screen.dart';
import '../providers/currency_provider.dart';
import '../providers/sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vault_provider.dart';
import '../main.dart';

import '../constants/app_categories.dart';

class CategoryUtils {
  static IconData getIcon(String category) {
    return AppCategories.getIcon(category);
  }
}

class VaultSnackBar {
  static void show({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Color? backgroundColor,
    Duration? duration,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    messenger?.removeCurrentSnackBar();

    final snckDuration = duration ?? const Duration(milliseconds: 3000);

    final controller = messenger?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: snckDuration,
        backgroundColor: backgroundColor ?? const Color(0xFF2D2D2D),
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
                backgroundColor: Colors.black.withValues(alpha: 0.2),
              )
            : null,
      ),
    );

    // Manual safety trigger: forcefully close the snackbar after the duration
    // in case the OS accessibility or kernel blocks the automatic dismissal.
    Future.delayed(snckDuration + const Duration(milliseconds: 100), () {
      try {
        controller?.close();
      } catch (_) {
        // Already closed, ignore
      }
    });
  }
}

/// SyncStatusIndicator: A cloud icon that reflects Drive sync status
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    IconData iconData;
    Color iconColor;

    switch (syncState.status) {
      case SyncStatus.syncing:
        iconData = Icons.sync;
        iconColor = AppTheme.primaryAction;
        break;
      case SyncStatus.success:
        iconData = Icons.cloud_done_outlined;
        iconColor = AppTheme.safeGreen;
        break;
      case SyncStatus.error:
        iconData = Icons.cloud_off_outlined;
        iconColor = AppTheme.urgentRed;
        break;
      case SyncStatus.idle:
        iconData = Icons.cloud_queue;
        iconColor = Theme.of(
          context,
        ).textTheme.bodySmall!.color!.withValues(alpha: 0.5);
        break;
    }

    return Tooltip(
      message: syncState.status == SyncStatus.syncing
          ? 'Syncing with Google Drive...'
          : (syncState.lastSync != null
                ? 'Last sync: ${syncState.lastSync!.hour}:${syncState.lastSync!.minute.toString().padLeft(2, '0')}'
                : 'Not synced'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: syncState.status == SyncStatus.syncing
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(iconData, color: iconColor, size: 20),
      ),
    );
  }
}

/// 1. BentoCard: The general surface container based on Stitch specs.
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;

  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12.0),
    this.borderRadius = 16.0,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color:
              borderColor ??
              Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// 4. StatusBadge: Dynamic pill indicator
class StatusBadge extends StatelessWidget {
  final String label;
  final int? daysLeft;
  final bool isPaid;
  final bool isDocument;

  const StatusBadge({
    super.key,
    required this.label,
    this.daysLeft,
    this.isPaid = false,
    this.isDocument = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;

    if (isPaid) {
      textColor = const Color(0xFF34D399); // Elegant Mint Sage
    } else if (isDocument) {
      if (label == 'EXPIRED') {
        textColor = const Color(0xFFE11D48); // Muted Crimson Coral
      } else if (label == 'ARCHIVED') {
        textColor = const Color(0xFF6366F1); // Sleek Royal Indigo
      } else {
        textColor = const Color(0xFF34D399);
      }
    } else if (daysLeft != null) {
      if (daysLeft! <= 3) {
        textColor = const Color(0xFFE11D48); // Crimson Coral
      } else if (daysLeft! <= 7) {
        textColor = const Color(0xFFF59E0B); // Warm Amber
      } else {
        textColor = const Color(0xFF94A3B8); // Muted Slate
      }
    } else {
      textColor = const Color(0xFF94A3B8);
    }

    final Color bgColor = textColor.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161A22), // Solid premium elevation
                borderRadius: BorderRadius.circular(16),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 48,
                      decoration: BoxDecoration(
                        color: itemColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          CategoryUtils.getIcon(item.category),
                          color: itemColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 42, // Optimized height for 2 lines
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  () {
                                    final rawTitle = item.title.isEmpty
                                        ? item.category
                                        : item.title;
                                    return rawTitle.length > 40
                                        ? '${rawTitle.substring(0, 37)}...'
                                        : rawTitle;
                                  }(),
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        height: 1.0, // Tighter line height
                                        decoration: item.isPaid
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: item.isPaid
                                            ? Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.color
                                            : Colors.white,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.dueDate != null
                                ? 'Due ${item.dueDate!.day} ${_getMonthName(item.dueDate!.month)}'
                                : 'No due date',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
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
                          if (item.itemType != 'Document') ...[
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currency.formatAmount(item.amount ?? 0.0),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                          StatusBadge(
                            label: item.isPaid
                                ? (item.itemType == 'Bill' ? 'PAID' : 'RENEWED')
                                : (isOverdue
                                      ? (item.itemType == 'Bill'
                                            ? 'OVERDUE'
                                            : 'EXPIRED')
                                      : (daysLeft == 0
                                            ? 'TODAY'
                                            : '$daysLeft DAYS')),
                            isPaid: item.isPaid,
                            daysLeft: item.isPaid ? null : daysLeft,
                          ),
                        ],
                      ),
                    ),
                    if (!item.isPaid && onCheckPressed != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onCheckPressed,
                        child: Container(
                          width: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
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

/// 7. CriticalAlertCard: For overdue warnings.
class CriticalAlertCard extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const CriticalAlertCard({super.key, required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.urgentRedAlert,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 8. IntegratedBottomNavBar: Matches Stitch image_0.png
class IntegratedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onAddPressed;

  const IntegratedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildNavItem(0, Icons.home_filled, 'Home', inactiveColor),
          ),
          _buildAddButton(),
          Expanded(
            child: _buildNavItem(1, Icons.folder_copy, 'Vault', inactiveColor),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color inactiveColor,
  ) {
    final isSelected = currentIndex == index;
    const activeColor = AppTheme.primaryAction;
    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAddPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryAction,
          borderRadius: BorderRadius.circular(20), // Matches Bento style radius
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 40),
      ),
    );
  }
}

/// 3. CustomInputField: Standard text input based on Stitch specs.
class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? hintText;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.hintText,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTheme.labelCapsStyle(context)),
        const SizedBox(height: 8),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textCapitalization: TextCapitalization.sentences,
            maxLines: maxLines,
            validator: validator,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              prefix: prefix,
              suffixIcon: suffix,
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 5. PrimaryButton: The high-priority action button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryAction,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 6. SecondaryButton: Card-surface style button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Theme.of(context).cardTheme.color,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
