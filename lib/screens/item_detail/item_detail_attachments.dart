import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vault_item.dart';
import '../../providers/vault_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/drive_service.dart';
import '../../widgets/global_components.dart';
import '../../theme/app_theme.dart';
import 'item_detail_dialogs.dart';

class ItemDetailAttachments extends ConsumerStatefulWidget {
  final VaultItem item;

  const ItemDetailAttachments({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<ItemDetailAttachments> createState() => _ItemDetailAttachmentsState();
}

class _ItemDetailAttachmentsState extends ConsumerState<ItemDetailAttachments> {
  final Map<String, bool> _downloadingPaths = {};

  Future<void> _handleAttachmentTap(BuildContext context, String path, String? cloudId) async {
    final file = File(path);
    if (file.existsSync()) {
      _viewAttachment(context, path);
      return;
    }

    if (cloudId == null || cloudId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File not found locally and has no cloud backup.'),
          backgroundColor: AppTheme.urgentRed,
        ),
      );
      return;
    }

    // Start download
    setState(() {
      _downloadingPaths[path] = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token == null) {
        throw Exception('Please sign in to Google to download cloud files.');
      }

      final driveService = DriveService(GoogleAuthClient({'Authorization': 'Bearer $token'}));
      try {
        final success = await driveService.downloadAttachment(cloudId, path);
        if (success) {
          // Force a rebuild by updating state
          setState(() {
            _downloadingPaths[path] = false;
          });
          if (context.mounted) {
            _viewAttachment(context, path);
          }
        } else {
          throw Exception('Download failed.');
        }
      } finally {
        driveService.dispose();
      }
    } catch (e) {
      setState(() {
        _downloadingPaths[path] = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppTheme.urgentRed,
          ),
        );
      }
    }
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
    int itemId,
    String filePath,
  ) async {
    final confirm = await ItemDetailDialogs.showDeleteAttachmentDialog(context);
    if (confirm == true && mounted) {
      await ref.read(vaultProvider.notifier).removeAttachment(itemId, filePath);
    }
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

  Widget _buildAttachmentTile(BuildContext context, int index) {
    final path = widget.item.attachedFiles[index];
    final cloudId = index < widget.item.cloudFileIds.length ? widget.item.cloudFileIds[index] : null;
    final fileExists = File(path).existsSync();
    final isDownloading = _downloadingPaths[path] == true;

    return GestureDetector(
      onTap: () => _handleAttachmentTap(context, path, cloudId),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: fileExists
                ? _buildAttachmentPreview(path)
                : Opacity(
                    opacity: 0.5,
                    child: _buildAttachmentPreview(path),
                  ),
          ),
          if (!fileExists)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isDownloading
                      ? const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Icon(
                          Icons.cloud_download_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _confirmDeleteAttachment(
                context,
                widget.item.id,
                path,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
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
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.attachedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATTACHMENTS (${widget.item.attachedFiles.length})',
          style: AppTheme.labelCapsStyle(context),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
          ),
          itemCount: widget.item.attachedFiles.length,
          itemBuilder: (context, index) {
            return _buildAttachmentTile(context, index);
          },
        ),
      ],
    );
  }
}
