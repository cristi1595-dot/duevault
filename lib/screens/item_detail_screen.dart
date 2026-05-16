import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../providers/currency_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import 'add_item_screen.dart';
import 'add_document_screen.dart';

import '../widgets/encrypted_image.dart';
import '../services/encryption_service.dart';

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
    final ref = this.ref;
    final item = widget.item;
    // Watch specifically for this item's changes
    final currentItem = ref
        .watch(vaultProvider)
        .firstWhere((i) => i.id == item.id, orElse: () => item);
    final currency = ref.watch(currencyProvider);
    final daysLeft = _calculateDaysLeft(currentItem.dueDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Details',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => currentItem.itemType == 'Document'
                      ? AddDocumentScreen(item: currentItem)
                      : AddItemScreen(item: currentItem),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Card (Amount & Status)
            BentoCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CategoryUtils.getIcon(currentItem.category),
                                size: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentItem.category.toUpperCase(),
                                style: AppTheme.labelCapsStyle(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentItem.title.isEmpty
                                ? currentItem.category
                                : currentItem.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (currentItem.isPaid) ...[
                            TextButton.icon(
                              onPressed: () => ref
                                  .read(vaultProvider.notifier)
                                  .updatePaidStatus(currentItem.id, false),
                              icon: Icon(
                                Icons.undo,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              label: Text(
                                currentItem.itemType == 'Bill'
                                    ? 'Undo'
                                    : 'Undo Renew',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontSize: 12,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: currentItem.itemType == 'Bill'
                                  ? 'PAID'
                                  : 'RENEWED',
                              isPaid: true,
                            ),
                          ] else if (currentItem.dueDate != null)
                            StatusBadge(
                              label: daysLeft < 0
                                  ? (currentItem.itemType == 'Bill'
                                        ? 'OVERDUE'
                                        : 'EXPIRED')
                                  : '$daysLeft DAYS',
                              daysLeft: daysLeft,
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (currentItem.itemType == 'Bill' &&
                      currentItem.amount != null)
                    Text(
                      currency.formatAmount(currentItem.amount!),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniInfo(
                        context,
                        Icons.calendar_today,
                        'DUE DATE',
                        currentItem.dueDate != null
                            ? '${currentItem.dueDate!.day}/${currentItem.dueDate!.month}/${currentItem.dueDate!.year}'
                            : 'Not set',
                      ),
                      _buildMiniInfo(
                        context,
                        Icons.repeat,
                        'RECURRENCE',
                        currentItem.recurrence,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Extra Details
            BentoCard(
              padding: const EdgeInsets.all(12),
              child: _buildMiniInfo(
                context,
                Icons.description_outlined,
                'TYPE',
                currentItem.itemType ?? 'Unknown',
              ),
            ),
            const SizedBox(height: 12),

            // 3. Notes
            if (currentItem.notes != null && currentItem.notes!.isNotEmpty)
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOTES', style: AppTheme.labelCapsStyle(context)),
                    const SizedBox(height: 8),
                    FutureBuilder<String?>(
                      future: EncryptionService.decryptText(currentItem.notes!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return Text(
                            snapshot.data ?? '',
                            style: Theme.of(context).textTheme.bodyLarge,
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
            if (currentItem.notes != null && currentItem.notes!.isNotEmpty)
              const SizedBox(height: 12),

            // 4. Attachments
            if (currentItem.attachedFiles.isNotEmpty)
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATTACHMENTS (${currentItem.attachedFiles.length})',
                      style: AppTheme.labelCapsStyle(context),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.3,
                          ),
                      itemCount: currentItem.attachedFiles.length,
                      itemBuilder: (context, index) {
                        final path = currentItem.attachedFiles[index];
                        return GestureDetector(
                          onTap: () => _viewAttachment(context, path),
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: _buildAttachmentPreview(path),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _confirmDeleteAttachment(
                                    context,
                                    ref,
                                    currentItem.id,
                                    path,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // 5. Actions
            if (!currentItem.isPaid)
              PrimaryButton(
                label: _isBusy
                    ? 'Processing...'
                    : (currentItem.itemType == 'Bill'
                          ? 'Mark as Paid'
                          : 'Mark as Renewed'),
                icon: _isBusy ? null : Icons.check_circle_outline,
                onPressed: _isBusy
                    ? null
                    : () async {
                        setState(() => _isBusy = true);
                        try {
                          final notifier = ref.read(vaultProvider.notifier);
                          await notifier.updatePaidStatus(currentItem.id, true);

                          if (context.mounted) {
                            final actionText = currentItem.itemType == 'Bill'
                                ? 'paid'
                                : 'renewed';
                            VaultSnackBar.show(
                              message:
                                  '${currentItem.title.isEmpty ? currentItem.category : currentItem.title} marked as $actionText',
                              actionLabel: 'UNDO',
                              backgroundColor: AppTheme.safeGreen,
                              onAction: () => notifier.updatePaidStatus(
                                currentItem.id,
                                false,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isBusy = false);
                        }
                      },
              ),
            if (!currentItem.isPaid) const SizedBox(height: 12),

            if (!currentItem.isArchived)
              SecondaryButton(
                label: 'Move to Archive',
                icon: Icons.archive_outlined,
                onPressed: () async {
                  final notifier = ref.read(vaultProvider.notifier);
                  await notifier.toggleArchiveStatus(currentItem.id, true);

                  VaultSnackBar.show(
                    message: 'Moved to History',
                    actionLabel: 'UNDO',
                    backgroundColor: AppTheme.safeGreen,
                    onAction: () =>
                        notifier.toggleArchiveStatus(currentItem.id, false),
                  );

                  if (context.mounted) Navigator.pop(context);
                },
              )
            else
              SecondaryButton(
                label: 'Restore to Active',
                icon: Icons.unarchive_outlined,
                onPressed: () async {
                  final notifier = ref.read(vaultProvider.notifier);
                  await notifier.toggleArchiveStatus(currentItem.id, false);

                  VaultSnackBar.show(
                    message: 'Restored to Vault',
                    actionLabel: 'UNDO',
                    backgroundColor: AppTheme.primaryAction,
                    onAction: () => ref
                        .read(vaultProvider.notifier)
                        .toggleArchiveStatus(currentItem.id, true),
                  );

                  if (context.mounted) Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),

            SecondaryButton(
              label: _isBusy ? 'Please wait...' : 'Delete Item',
              icon: _isBusy ? null : Icons.delete_outline,
              onPressed: _isBusy
                  ? null
                  : () => _confirmDelete(context, ref, currentItem),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(String path) {
    final isImage =
        path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.png');

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: EncryptedImage(
          path: path,
          fit: BoxFit.cover,
          errorWidget: _buildFileIcon(path),
        ),
      );
    } else {
      return _buildFileIcon(path);
    }
  }

  Widget _buildFileIcon(String path) {
    final isPdf = path.toLowerCase().endsWith('.pdf');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file_outlined,
            color: isPdf ? AppTheme.urgentRed : AppTheme.primaryAction,
            size: 32,
          ),
          const SizedBox(height: 4),
          const Text(
            'PDF DOCUMENT',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _viewAttachment(BuildContext context, String path) {
    final isImage =
        path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.png');

    if (isImage) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(
                child: Center(
                  child: EncryptedImage(path: path, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // For PDF, we might need a dedicated viewer later, but for now show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF viewer will be implemented in the next update.'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAttachment(
    BuildContext context,
    WidgetRef ref,
    int itemId,
    String filePath,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Attachment',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to remove this file?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.urgentRed),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(vaultProvider.notifier).removeAttachment(itemId, filePath);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VaultItem currentItem,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Item',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to delete "${currentItem.title.isEmpty ? currentItem.category : currentItem.title}"? This action cannot be undone.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppTheme.urgentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(vaultProvider.notifier).deleteItem(currentItem.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildMiniInfo(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.labelCapsStyle(context)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
