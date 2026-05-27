import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';
import 'bento_input_wrapper.dart';
import '../../providers/premium_provider.dart';
import '../../providers/auth_provider.dart';

class AttachmentSection extends ConsumerWidget {
  final List<String> attachedFiles;
  final bool useOcr;
  final bool isProcessingOcr;
  final VoidCallback onPickImage;
  final VoidCallback onPickFiles;
  final ValueChanged<int> onRemoveAttachment;
  final ValueChanged<bool> onOcrToggleChanged;

  const AttachmentSection({
    super.key,
    required this.attachedFiles,
    required this.useOcr,
    required this.isProcessingOcr,
    required this.onPickImage,
    required this.onPickFiles,
    required this.onRemoveAttachment,
    required this.onOcrToggleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BentoInputWrapper(
      label: 'ATTACHMENTS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _buildCameraCardWithOcrToggle(context, ref)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.upload_file_outlined,
                    title: 'Upload Files',
                    subtitle: 'PDF, JPG, PNG',
                    onTap: onPickFiles,
                  ),
                ),
              ],
            ),
          ),
          if (attachedFiles.isNotEmpty)
            Container(
              height: 90,
              padding: const EdgeInsets.only(
                left: 12,
                bottom: 12,
                top: 4,
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachedFiles.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final path = attachedFiles[index];
                  return Stack(
                     children: [
                      Container(
                        width: 70,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: _buildAttachmentIcon(path),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveAttachment(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.primaryAction, size: 32),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color ??
                        AppTheme.lightTextSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraCardWithOcrToggle(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final isPro = !isGuest && isPremium;

    return GestureDetector(
      onTap: isProcessingOcr ? null : onPickImage,
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: useOcr
                ? AppTheme.primaryAction.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor,
            width: useOcr ? 1.5 : 1.0,
          ),
          boxShadow: useOcr
              ? [
                  BoxShadow(
                    color: AppTheme.primaryAction.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isProcessingOcr)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else
                  Icon(
                    isPro ? Icons.auto_awesome : Icons.photo_camera_outlined,
                    color: useOcr
                        ? AppTheme.primaryAction
                        : AppTheme.lightTextSecondary,
                    size: 32,
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isProcessingOcr ? 'Scanning...' : (isPro ? 'Smart Scan' : 'Take a picture'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (!ref.watch(isPremiumProvider)) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAction.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.primaryAction.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryAction,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      useOcr ? 'AUTO-FILL ON' : 'AUTO-FILL OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: useOcr
                            ? AppTheme.primaryAction
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 20,
                      width: 32,
                      child: Switch(
                        value: useOcr,
                        onChanged: onOcrToggleChanged,
                        activeThumbColor: AppTheme.primaryAction,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentIcon(String path) {
    final lowerPath = path.toLowerCase();
    final isPdf = lowerPath.endsWith('.pdf');
    if (isPdf) {
      return _buildFileIcon(path, isPdf: true);
    }

    final isStored = path.contains('app_flutter/attachments') ||
        path.contains('/attachments/') ||
        (!path.contains('/') && !path.contains('\\')) ||
        lowerPath.endsWith('.enc');

    final cleanPath = lowerPath.replaceAll('.enc', '');
    final isImage = cleanPath.endsWith('.jpg') ||
        cleanPath.endsWith('.jpeg') ||
        cleanPath.endsWith('.png') ||
        cleanPath.endsWith('.heic') ||
        cleanPath.endsWith('.heif') ||
        cleanPath.endsWith('.webp');

    if (isStored) {
      if (isImage) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: EncryptedImage(
            path: path,
            fit: BoxFit.cover,
            errorWidget: _buildFileIcon(path, isPdf: false),
          ),
        );
      } else {
        return _buildFileIcon(path, isPdf: false);
      }
    } else {
      if (isImage) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFileIcon(path, isPdf: false),
          ),
        );
      } else {
        return _buildFileIcon(path, isPdf: false);
      }
    }
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
