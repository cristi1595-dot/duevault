import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../providers/currency_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import 'add_bill_screen.dart';
import 'add_document_screen.dart';
import 'item_detail/item_detail_dialogs.dart';
import 'item_detail/item_detail_attachments.dart';
import 'item_detail/item_detail_hero_card.dart';
import 'item_detail/item_detail_timeline_card.dart';
import 'item_detail/item_detail_notes_card.dart';
import 'item_detail/item_detail_action_bar.dart';

/// DueVault ItemDetailScreen
/// Pixel-perfect detail view adhering to the Design System:
/// - Sticky Bottom Action Bar in thumb zone (WCAG AA compliant)
/// - Bento card architecture with contrast containers
/// - Unified typography, spacing, and semantic status indicators
/// - Stratified haptic feedback & safe undo notifications
class ItemDetailScreen extends ConsumerStatefulWidget {
  final VaultItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isBusy = false;

  int _calculateDaysLeft(DateTime? dueDate) {
    if (dueDate == null) return 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final currentItem = ref
        .watch(vaultProvider)
        .firstWhere((i) => i.id == item.id, orElse: () => item);
    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBill = currentItem.itemType == 'Bill';
    final daysLeft = _calculateDaysLeft(currentItem.dueDate);

    final Color dueDateColor;
    if (currentItem.isPaid) {
      dueDateColor = AppColors.statusSafeText(isDark);
    } else if (currentItem.dueDate == null) {
      dueDateColor = AppColors.textSecondary(isDark);
    } else if (daysLeft <= 3) {
      dueDateColor = AppColors.statusUrgentText(isDark);
    } else if (daysLeft <= 7) {
      dueDateColor = AppColors.statusWarningText(isDark);
    } else {
      dueDateColor = AppColors.statusSafeText(isDark);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isBill ? 'Bill Details' : 'Document Details',
          style: AppTypography.titleMedium(AppColors.textPrimary(isDark)).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isBill
                      ? AddBillScreen(item: currentItem)
                      : AddDocumentScreen(item: currentItem),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.statusUrgentText(isDark)),
            tooltip: 'Delete',
            onPressed: () {
              HapticFeedback.lightImpact();
              _confirmDelete(context, ref, currentItem);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO BENTO CARD
            ItemDetailHeroCard(
              item: currentItem,
              currency: currency,
              isDark: isDark,
              daysLeft: daysLeft,
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. TIMELINE & SCHEDULE CARD
            ItemDetailTimelineCard(
              item: currentItem,
              isDark: isDark,
              daysLeft: daysLeft,
              dueDateColor: dueDateColor,
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. NOTES & REMARKS CARD
            if (currentItem.notes != null && currentItem.notes!.isNotEmpty) ...[
              ItemDetailNotesCard(
                notes: currentItem.notes!,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 4. ATTACHMENTS CARD
            if (currentItem.attachedFiles.isNotEmpty) ...[
              BentoCard(
                padding: AppSpacing.cardPaddingLg,
                borderRadius: AppRadius.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'ATTACHMENTS (${currentItem.attachedFiles.length})',
                          style: AppTypography.labelCaps(AppColors.textSecondary(isDark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ItemDetailAttachments(item: currentItem),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.base),
          ],
        ),
      ),
      bottomNavigationBar: ItemDetailActionBar(
        item: currentItem,
        isDark: isDark,
        isBusy: _isBusy,
        onToggleArchive: () => _toggleArchive(currentItem),
        onTogglePaid: () => _toggleStatus(currentItem, isBill),
      ),
    );
  }

  Future<void> _toggleStatus(VaultItem currentItem, bool isBill) async {
    setState(() => _isBusy = true);
    try {
      final notifier = ref.read(vaultProvider.notifier);
      final nextStatus = !currentItem.isPaid;
      await notifier.updatePaidStatus(currentItem.id, nextStatus);

      if (mounted) {
        final actionText = nextStatus
            ? (isBill ? 'paid' : 'renewed')
            : (isBill ? 'unpaid' : 'not renewed');
        VaultSnackBar.show(
          message: '${currentItem.title} marked as $actionText',
          actionLabel: 'UNDO',
          backgroundColor: AppColors.emerald500,
          onAction: () {
            HapticFeedback.lightImpact();
            notifier.updatePaidStatus(currentItem.id, !nextStatus);
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _toggleArchive(VaultItem currentItem) {
    final notifier = ref.read(vaultProvider.notifier);
    final willArchive = !currentItem.isArchived;
    unawaited(notifier.toggleArchiveStatus(currentItem.id, willArchive));

    VaultSnackBar.show(
      message: willArchive ? 'Moved to Archive' : 'Restored to Active',
      actionLabel: 'UNDO',
      backgroundColor: AppColors.violet500,
      onAction: () {
        HapticFeedback.lightImpact();
        notifier.toggleArchiveStatus(currentItem.id, !willArchive);
      },
    );

    Navigator.pop(context);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VaultItem currentItem,
  ) async {
    final title = currentItem.title.isEmpty
        ? currentItem.category
        : currentItem.title;
    final confirm = await ItemDetailDialogs.showDeleteItemDialog(
      context,
      title,
    );

    if (confirm == true) {
      unawaited(ref.read(vaultProvider.notifier).deleteItem(currentItem.id));
      if (context.mounted) Navigator.pop(context);
    }
  }
}
