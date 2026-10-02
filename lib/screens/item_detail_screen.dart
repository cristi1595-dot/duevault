import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../providers/currency_provider.dart';
import '../theme/app_theme.dart';
import 'add_bill_screen.dart';
import 'add_document_screen.dart';
import '../services/encryption_service.dart';
import 'item_detail/item_detail_dialogs.dart';
import 'item_detail/item_detail_attachments.dart';
import '../widgets/vault_snackbar.dart';

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

    final cardBg = isDark ? const Color(0xFF161A22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF222734) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isBill ? 'Bill Details' : 'Document Details',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
            icon: const Icon(Icons.delete_outline, color: AppTheme.urgentRed),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref, currentItem),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO HEADER CARD: Type, Title, Amount & Auto-Pay
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Item Type Tag & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Type Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAction.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBill ? Icons.receipt_long_rounded : Icons.description_rounded,
                              size: 14,
                              color: AppTheme.primaryAction,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isBill ? 'BILL' : 'DOCUMENT',
                              style: const TextStyle(
                                color: AppTheme.primaryAction,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      _buildStatusBadge(currentItem, daysLeft, isBill),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Item Title
                  Text(
                    currentItem.title.isEmpty ? (isBill ? 'Bill' : 'Document') : currentItem.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                  ),

                  // Amount (If Bill)
                  if (isBill && currentItem.amount != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currency.formatAmount(currentItem.amount!),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -1.0,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentItem.isPaid ? 'paid' : 'amount due',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Auto-Pay banner if active
                  if (isBill && currentItem.directDebit) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.safeGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.safeGreen.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_rounded,
                            size: 18,
                            color: AppTheme.safeGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Auto-Pay (Funds Reserved)',
                                  style: TextStyle(
                                    color: AppTheme.safeGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Money is set aside; debited automatically on due date.',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    fontSize: 11.5,
                                  ),
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
            ),
            const SizedBox(height: 14),

            // 2. SCHEDULE & REMAINING DAYS CARD (Balanced, Clear, Intuitive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBill ? 'PAYMENT TIMELINE' : 'EXPIRATION TIMELINE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      if (currentItem.recurrence != 'None' && currentItem.recurrence.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF222734) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.repeat, size: 12, color: AppTheme.primaryAction),
                              const SizedBox(width: 4),
                              Text(
                                currentItem.recurrence,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryAction,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Date block
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentItem.dueDate != null
                                  ? DateFormat('EEEE, d MMMM yyyy').format(currentItem.dueDate!)
                                  : 'No date specified',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isBill ? 'Due Date' : 'Expiry Date',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Prominent Countdown Pill
                      if (currentItem.dueDate != null)
                        _buildDaysLeftPill(currentItem, daysLeft),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. NOTES CARD (Balanced Memo Typography)
            if (currentItem.notes != null && currentItem.notes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sticky_note_2_outlined,
                          size: 16,
                          color: AppTheme.primaryAction,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'NOTES & REMARKS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<String?>(
                      future: EncryptionService.decryptText(currentItem.notes!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return Text(
                            snapshot.data ?? '',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  height: 1.4,
                                  color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                                ),
                          );
                        }
                        return const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 4. ATTACHMENTS CARD
            if (currentItem.attachedFiles.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: AppTheme.primaryAction,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ATTACHMENTS (${currentItem.attachedFiles.length})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ItemDetailAttachments(item: currentItem),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 5. PRIMARY ACTION BUTTON: Mark as Paid / Mark as Unpaid
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: _isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        currentItem.isPaid
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 20,
                      ),
                label: Text(
                  _isBusy
                      ? 'Updating...'
                      : (currentItem.isPaid
                          ? (isBill ? 'Mark as Unpaid' : 'Mark as Not Renewed')
                          : (isBill ? 'Mark as Paid' : 'Mark as Renewed')),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentItem.isPaid
                      ? (isDark ? const Color(0xFF222734) : const Color(0xFFE2E8F0))
                      : AppTheme.primaryAction,
                  foregroundColor: currentItem.isPaid
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isBusy ? null : () => _toggleStatus(currentItem, isBill),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary Action: Archive / Restore
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(
                  currentItem.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  size: 18,
                ),
                label: Text(
                  currentItem.isArchived ? 'Restore to Active' : 'Move to Archive',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _toggleArchive(currentItem),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(VaultItem item, int daysLeft, bool isBill) {
    if (item.isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.safeGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.safeGreen),
            const SizedBox(width: 5),
            Text(
              isBill ? 'PAID' : 'RENEWED',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.safeGreen,
              ),
            ),
          ],
        ),
      );
    }

    if (item.dueDate == null) {
      return const SizedBox.shrink();
    }

    if (daysLeft < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.urgentRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.urgentRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 14, color: AppTheme.urgentRed),
            const SizedBox(width: 5),
            Text(
              isBill ? 'OVERDUE' : 'EXPIRED',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.urgentRed,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryAction.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryAction.withValues(alpha: 0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 14, color: AppTheme.primaryAction),
          SizedBox(width: 5),
          Text(
            'ACTIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryAction,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysLeftPill(VaultItem item, int daysLeft) {
    Color color;
    Color bg;
    String text;

    if (item.isPaid) {
      color = AppTheme.safeGreen;
      bg = AppTheme.safeGreen.withValues(alpha: 0.12);
      text = 'Settled';
    } else if (daysLeft < 0) {
      color = AppTheme.urgentRed;
      bg = AppTheme.urgentRed.withValues(alpha: 0.12);
      final count = daysLeft.abs();
      text = count == 1 ? '1 day late' : '$count days late';
    } else if (daysLeft == 0) {
      color = const Color(0xFFF59E0B);
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      text = 'Due Today';
    } else if (daysLeft == 1) {
      color = const Color(0xFFF59E0B);
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      text = 'Tomorrow';
    } else if (daysLeft <= 3) {
      color = const Color(0xFFF59E0B);
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      text = 'In $daysLeft days';
    } else {
      color = AppTheme.primaryAction;
      bg = AppTheme.primaryAction.withValues(alpha: 0.12);
      text = 'In $daysLeft days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
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
          backgroundColor: AppTheme.safeGreen,
          onAction: () => notifier.updatePaidStatus(currentItem.id, !nextStatus),
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
      backgroundColor: AppTheme.primaryAction,
      onAction: () => notifier.toggleArchiveStatus(currentItem.id, !willArchive),
    );

    Navigator.pop(context);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VaultItem currentItem,
  ) async {
    final title = currentItem.title.isEmpty ? currentItem.category : currentItem.title;
    final confirm = await ItemDetailDialogs.showDeleteItemDialog(context, title);

    if (confirm == true) {
      unawaited(ref.read(vaultProvider.notifier).deleteItem(currentItem.id));
      if (context.mounted) Navigator.pop(context);
    }
  }
}
