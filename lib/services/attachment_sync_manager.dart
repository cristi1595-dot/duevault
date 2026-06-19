import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar_community/isar.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/vault_item.dart';
import '../utils/logger.dart';
import 'drive_service.dart';

/// Manages synchronization of physical attachments with Google Drive.
class AttachmentSyncManager {
  final Isar localIsar;
  final User user;

  AttachmentSyncManager({
    required this.localIsar,
    required this.user,
  });

  /// Synchronizes local attachments with Google Drive
  Future<void> syncAttachments(DriveService driveService) async {
    final items = await localIsar
        .collection<VaultItem>()
        .filter()
        .ownerIdEqualTo(user.uid)
        .findAll();

    for (var item in items) {
      try {
        bool modified = false;

        final appDir = await getApplicationDocumentsDirectory();
        final attachmentsDir = Directory('${appDir.path}/attachments');

        // 2. UPLOAD/UPDATE files in Cloud based on Checksums
        for (int i = 0; i < item.attachedFiles.length; i++) {
          final fileName = p.basename(item.attachedFiles[i].replaceAll('\\', '/'));
          final localFile = File('${attachmentsDir.path}/$fileName');
          if (!await localFile.exists()) continue;

          // Calculate current local checksum
          final currentBytes = await localFile.readAsBytes();
          final currentChecksum = md5.convert(currentBytes).toString();

          bool needsUpload = false;
          String? existingCloudId;

          if (i >= item.cloudFileIds.length) {
            // Case A: New file (index out of cloud range)
            needsUpload = true;
          } else {
            // Case B: Existing file index -> Check if content changed
            existingCloudId = item.cloudFileIds[i];
            final lastKnownChecksum = i < item.cloudFileChecksums.length
                ? item.cloudFileChecksums[i]
                : '';

            if (currentChecksum != lastKnownChecksum) {
              logger.i(
                'AttachmentSyncManager: Attachment content changed for ${item.title} at index $i. Re-uploading...',
              );
              needsUpload = true;
            }
          }

          if (needsUpload) {
            // Delete the old file from Drive if we are replacing it
            if (existingCloudId != null) {
              await driveService.deleteFile(existingCloudId);
            }

            final cloudId = await driveService.uploadAttachment(
              localFile,
              'attach_${item.uuid}_$i',
            );
            if (cloudId != null) {
              final newIds = List<String>.from(item.cloudFileIds);
              final newChecksums = List<String>.from(item.cloudFileChecksums);

              if (i >= newIds.length) {
                newIds.add(cloudId);
                newChecksums.add(currentChecksum);
              } else {
                newIds[i] = cloudId;
                newChecksums[i] = currentChecksum;
              }

              item.cloudFileIds = newIds;
              item.cloudFileChecksums = newChecksums;
              modified = true;
            }
          }
        }

        // 3. DOWNLOAD missing files from Cloud
        if (item.cloudFileIds.length > item.attachedFiles.length) {
          final appDir = await getApplicationDocumentsDirectory();
          final attachmentsDir = Directory('${appDir.path}/attachments');
          if (!await attachmentsDir.exists()) {
            await attachmentsDir.create(recursive: true);
          }

          for (
            int i = item.attachedFiles.length;
            i < item.cloudFileIds.length;
            i++
          ) {
            final cloudId = item.cloudFileIds[i];
            final fileName =
                'doc_sync_${DateTime.now().microsecondsSinceEpoch}_$i.enc';
            final localPath = '${attachmentsDir.path}/$fileName';

            final success = await driveService.downloadAttachment(
              cloudId,
              localPath,
            );
            if (success) {
              final newPaths = List<String>.from(item.attachedFiles);
              newPaths.add(fileName);
              item.attachedFiles = newPaths;

              // After download, update the local checksum to match what we just got
              final downloadedBytes = await File(localPath).readAsBytes();
              final downloadedChecksum = md5
                  .convert(downloadedBytes)
                  .toString();

              final newChecksums = List<String>.from(item.cloudFileChecksums);
              if (i >= newChecksums.length) {
                newChecksums.add(downloadedChecksum);
              } else {
                newChecksums[i] = downloadedChecksum;
              }
              item.cloudFileChecksums = newChecksums;

              modified = true;
            }
          }
        }

        if (modified) {
          await localIsar.writeTxn(() async {
            await localIsar.collection<VaultItem>().put(item);
          });
        }
      } catch (e) {
        logger.e('Error syncing attachments for item ${item.title}', error: e);
      }
    }
  }
}
