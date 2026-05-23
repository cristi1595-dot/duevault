import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../models/vault_item.dart';
import '../../providers/auth_provider.dart';
import '../../services/drive_service.dart';
import '../../services/encryption_service.dart';
import '../../widgets/global_components.dart';
import '../../theme/app_theme.dart';


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
  String? _attachmentsDirPath;

  @override
  void initState() {
    super.initState();
    _loadAttachmentsDirectory();
  }

  Future<void> _loadAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _attachmentsDirPath = '${appDir.path}/attachments';
      });
    }
  }

  Future<void> _handleAttachmentTap(
    BuildContext context,
    String absolutePath,
    String? cloudId,
    String fileName,
  ) async {
    final file = File(absolutePath);
    if (file.existsSync()) {
      _viewAttachment(context, absolutePath);
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
      _downloadingPaths[fileName] = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token == null) {
        throw Exception('Please sign in to Google to download cloud files.');
      }

      final driveService = DriveService(GoogleAuthClient({'Authorization': 'Bearer $token'}));
      try {
        final success = await driveService.downloadAttachment(cloudId, absolutePath);
        if (success) {
          // Force a rebuild by updating state
          setState(() {
            _downloadingPaths[fileName] = false;
          });
          if (context.mounted) {
            _viewAttachment(context, absolutePath);
          }
        } else {
          throw Exception('Download failed.');
        }
      } finally {
        driveService.dispose();
      }
    } catch (e) {
      setState(() {
        _downloadingPaths[fileName] = false;
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

  String _detectExtension(List<int> bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return '.pdf';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return '.jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return '.png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return '.gif';
    }
    return '';
  }

  void _viewAttachment(BuildContext context, String path) async {
    try {
      final bytes = await EncryptionService.decryptFileToBytes(path);
      if (bytes == null) {
        throw Exception('Failed to decrypt file.');
      }

      final ext = _detectExtension(bytes);
      final tempDir = await getTemporaryDirectory();
      final baseName = p.basenameWithoutExtension(path.replaceAll('\\', '/'));
      final tempFile = File('${tempDir.path}/$baseName$ext');
      
      await tempFile.writeAsBytes(bytes);

      final result = await OpenFilex.open(tempFile.path);
      
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              backgroundColor: AppTheme.urgentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: AppTheme.urgentRed,
          ),
        );
      }
    }
  }

  Widget _buildAttachmentPreview(String path) {
    final isPdf = path.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      return _buildFileIcon(path, isPdf: true);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: EncryptedImage(
        path: path,
        fit: BoxFit.cover,
        errorWidget: _buildFileIcon(path, isPdf: false),
      ),
    );
  }

  Widget _buildFileIcon(String path, {required bool isPdf}) {
    final ext = p.extension(path).toLowerCase();
    
    String label = 'DOCUMENT';
    IconData icon = Icons.insert_drive_file_outlined;
    Color color = AppTheme.primaryAction;

    if (isPdf) {
      label = 'PDF';
      icon = Icons.picture_as_pdf;
      color = AppTheme.urgentRed;
    } else if (ext == '.enc') {
      label = 'ENCRYPTED';
      icon = Icons.lock_outline;
      color = AppTheme.primaryAction;
    } else if (ext.isNotEmpty) {
      label = ext.substring(1).toUpperCase();
      icon = Icons.insert_drive_file_outlined;
      color = AppTheme.primaryAction;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(BuildContext context, int index) {
    final rawName = widget.item.attachedFiles[index];
    final cleanName = p.basename(rawName.replaceAll('\\', '/'));
    final absolutePath = '$_attachmentsDirPath/$cleanName';
    final cloudId = index < widget.item.cloudFileIds.length ? widget.item.cloudFileIds[index] : null;
    final fileExists = File(absolutePath).existsSync();
    final isDownloading = _downloadingPaths[cleanName] == true;

    return GestureDetector(
      onTap: () => _handleAttachmentTap(context, absolutePath, cloudId, cleanName),
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
                ? _buildAttachmentPreview(absolutePath)
                : Opacity(
                    opacity: 0.5,
                    child: _buildAttachmentPreview(absolutePath),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.attachedFiles.isEmpty || _attachmentsDirPath == null) {
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
