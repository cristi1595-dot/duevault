import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/vault_item.dart';
import '../screens/item_detail_screen.dart';
import '../providers/currency_provider.dart';
import '../providers/sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
  }) {
    scaffoldMessengerKey.currentState?.clearSnackBars();
    scaffoldMessengerKey.currentState?.showSnackBar(
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
        duration: const Duration(seconds: 2),
        backgroundColor: backgroundColor ?? const Color(0xFF2D2D2D), 
        behavior: SnackBarBehavior.fixed, // Attached to bottom as requested
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white, // White text on colored background
                backgroundColor: Colors.black.withValues(alpha: 0.2), // Darker overlay for button
              )
            : null,
      ),
    );
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
        iconColor = Theme.of(context).textTheme.bodySmall!.color!.withValues(alpha: 0.5);
    }

    return Tooltip(
      message: syncState.status == SyncStatus.syncing 
        ? 'Syncing with Google Drive...' 
        : (syncState.lastSync != null ? 'Last sync: ${syncState.lastSync!.hour}:${syncState.lastSync!.minute.toString().padLeft(2, '0')}' : 'Not synced'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: syncState.status == SyncStatus.syncing
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
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
          color: borderColor ?? Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
      textColor = AppTheme.safeGreen;
    } else if (isDocument) {
      if (label == 'EXPIRED') {
        textColor = AppTheme.urgentRed;
      } else if (label == 'ARCHIVED') {
        textColor = AppTheme.primaryAction;
      } else {
        textColor = AppTheme.safeGreen;
      }
    } else if (daysLeft != null) {
      if (daysLeft! <= 3) {
        textColor = AppTheme.urgentRed;
      } else if (daysLeft! <= 7) {
        textColor = AppTheme.warningYellow;
      } else if (daysLeft! <= 30) {
        textColor = AppTheme.safeGreen;
      } else {
        textColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
      }
    } else {
      textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    }

    // "low-opacity version of the semantic color"
    final Color bgColor = textColor.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
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
    final bool isInHistory = item.isArchived || (item.isPaid && daysLeft < 0);
    final itemColor = item.itemType == 'Bill' ? AppTheme.primaryAction : AppTheme.safeGreen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Slidable(
          key: ValueKey(item.id),
          startActionPane: ActionPane(
            motion: const BehindMotion(),
            dismissible: DismissiblePane(onDismissed: () {
              final notifier = ref.read(vaultProvider.notifier);
              if (isInHistory) {
                notifier.toggleArchiveStatus(item.id, false);
                VaultSnackBar.show(
                  message: 'Restored to Vault',
                  actionLabel: 'UNDO',
                  backgroundColor: AppTheme.primaryAction,
                  onAction: () => notifier.toggleArchiveStatus(item.id, true),
                );
              } else {
                notifier.toggleArchiveStatus(item.id, true);
                VaultSnackBar.show(
                  message: 'Moved to History',
                  actionLabel: 'UNDO',
                  backgroundColor: AppTheme.safeGreen,
                  onAction: () => notifier.toggleArchiveStatus(item.id, false),
                );
              }
            }),
            children: [
              if (isInHistory)
                SlidableAction(
                  onPressed: (context) {
                    ref.read(vaultProvider.notifier).toggleArchiveStatus(item.id, false);
                    VaultSnackBar.show(
                      message: 'Restored to Vault',
                      actionLabel: 'UNDO',
                      backgroundColor: AppTheme.primaryAction,
                      onAction: () => ref.read(vaultProvider.notifier).toggleArchiveStatus(item.id, true),
                    );
                  },
                  backgroundColor: AppTheme.primaryAction,
                  foregroundColor: Colors.white,
                  icon: Icons.unarchive_rounded,
                  label: 'Vault',
                )
              else
                SlidableAction(
                  onPressed: (context) {
                    ref.read(vaultProvider.notifier).toggleArchiveStatus(item.id, true);
                    VaultSnackBar.show(
                      message: 'Moved to History',
                      actionLabel: 'UNDO',
                      backgroundColor: AppTheme.safeGreen,
                      onAction: () => ref.read(vaultProvider.notifier).toggleArchiveStatus(item.id, false),
                    );
                  },
                  backgroundColor: AppTheme.safeGreen,
                  foregroundColor: Colors.white,
                  icon: Icons.archive_rounded,
                  label: 'Archive',
                ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {
                // This triggers on full swipe
                ref.read(vaultProvider.notifier).deleteItem(item.id);
              },
              confirmDismiss: () async {
                // This allows us to show the dialog before the full swipe completes
                final confirmed = await _showDeleteConfirmation(context, ref);
                return confirmed == true;
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) async {
                  final confirmed = await _showDeleteConfirmation(context, ref);
                  if (confirmed != true && context.mounted) {
                    Slidable.of(context)?.close();
                  }
                },
                backgroundColor: AppTheme.urgentRed,
                foregroundColor: Colors.white,
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap ?? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isOverdue ? AppTheme.urgentRed.withValues(alpha: 0.3) : Theme.of(context).dividerColor,
                  width: isOverdue ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      CategoryUtils.getIcon(item.category),
                      color: itemColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.isEmpty ? item.category : item.title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: item.isPaid ? TextDecoration.lineThrough : null,
                            color: item.isPaid ? Theme.of(context).textTheme.bodyMedium?.color : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.dueDate != null 
                            ? 'Due ${item.dueDate!.day} ${_getMonthName(item.dueDate!.month)}'
                            : 'No due date',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.formatAmount(item.amount ?? 0.0),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? AppTheme.urgentRed : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (item.isPaid)
                        StatusBadge(
                          label: item.itemType == 'Bill' ? 'PAID' : 'RENEWED',
                          isPaid: true,
                        )
                      else ...[
                        Row(
                          children: [
                            StatusBadge(
                              label: isOverdue 
                                  ? (item.itemType == 'Bill' ? 'OVERDUE' : 'EXPIRED') 
                                  : (daysLeft == 0 ? 'TODAY' : '$daysLeft DAYS'),
                              daysLeft: daysLeft,
                            ),
                            if (onCheckPressed != null) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: onCheckPressed,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAction.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.primaryAction.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.check_rounded, color: AppTheme.primaryAction, size: 18),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to permanently delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              ref.read(vaultProvider.notifier).deleteItem(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.urgentRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
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
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
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
    final inactiveColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_filled, 'Home', inactiveColor),
          _buildAddButton(),
          _buildNavItem(1, Icons.folder_copy, 'Vault', inactiveColor),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color inactiveColor) {
    final isSelected = currentIndex == index;
    final activeColor = AppTheme.primaryAction;
    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primaryAction,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryAction.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
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
        Text(
          label.toUpperCase(),
          style: AppTheme.labelCapsStyle(context),
        ),
        const SizedBox(height: 8),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              prefix: prefix,
              suffixIcon: suffix,
              hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
