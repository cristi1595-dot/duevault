import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/vault_item.dart';
import '../models/app_config.dart';
import 'encryption_service.dart';
import 'firebase_sync_service.dart';
import 'drive_service.dart';
import 'notification_service.dart';
import '../utils/logger.dart';

class VaultDataManager {
  /// Deletes a local attachment and schedules deletion of its Google Drive backup.
  /// Returns `true` if the attachment was found and removed, otherwise `false`.
  static Future<bool> removeAttachment({
    required Isar isar,
    required int itemId,
    required String localPath,
    required String? userAccessToken,
  }) async {
    final item = await isar.collection<VaultItem>().get(itemId);
    if (item == null) return false;

    final fileName = p.basename(localPath.replaceAll('\\', '/'));
    final appDir = await getApplicationDocumentsDirectory();
    final resolvedPath = '${appDir.path}/attachments/$fileName';

    // 1. Remove from local file system
    try {
      final file = File(resolvedPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      logger.e('Error deleting local file: $resolvedPath', error: e);
    }

    // 2. Identify and remove from cloud (Drive)
    final index = item.attachedFiles.indexWhere((path) => p.basename(path.replaceAll('\\', '/')) == fileName);
    if (index == -1) {
      logger.w('removeAttachment: File $fileName not found in item attachments: ${item.attachedFiles}');
      return false;
    }

    if (index < item.cloudFileIds.length) {
      final cloudId = item.cloudFileIds[index];
      if (cloudId.isNotEmpty) {
        // Trigger async cloud deletion
        unawaited(_deleteFromCloud(cloudId, userAccessToken));
      }
      item.cloudFileIds.removeAt(index);
    }

    if (index < item.cloudFileChecksums.length) {
      item.cloudFileChecksums.removeAt(index);
    }

    // Update item lists
    item.attachedFiles.removeAt(index);
    item.lastModified = DateTime.now();

    // 3. Persist change
    await isar.writeTxn(() async {
      await isar.collection<VaultItem>().put(item);
    });

    logger.i('Attachment removed: $fileName');
    return true;
  }

  static Future<void> _deleteFromCloud(String fileId, String? token) async {
    if (token != null) {
      final driveService = DriveService(
        GoogleAuthClient({'Authorization': 'Bearer $token'}),
      );
      try {
        await driveService.deleteFile(fileId);
        logger.i('Cloud file deleted: $fileId');
      } catch (e) {
        logger.e('Failed to delete cloud file: $fileId', error: e);
      } finally {
        driveService.dispose();
      }
    }
  }

  /// Clears local cached attachments.
  static Future<void> clearLocalCache() async {
    logger.i('VaultDataManager: clearLocalCache called!');
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (await attachmentsDir.exists()) {
      final entities = await attachmentsDir.list().toList();
      for (final entity in entities) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (e) {
            logger.e('Error deleting cached file: ${entity.path}', error: e);
          }
        }
      }
    }
  }

  /// Wipes all local database records, cached attachments, and encryption keys.
  /// Optionally wipes cloud backups (Firestore & Google Drive).
  static Future<void> clearAllData({
    required Isar isar,
    required bool alsoDeleteCloud,
    required User? currentUser,
    required String? userAccessToken,
    required FirebaseSyncService firebaseSyncService,
  }) async {
    logger.w(
      'VaultDataManager: clearAllData called! alsoDeleteCloud: $alsoDeleteCloud',
    );

    // 1. Cancel all notifications
    final allItems = await isar.collection<VaultItem>().where().findAll();
    for (final item in allItems) {
      await NotificationService.cancelBillNotifications(item.id);
    }

    // 2. Local wipe
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (await attachmentsDir.exists()) {
      await attachmentsDir.delete(recursive: true);
    }

    await EncryptionService.deleteKey();

    await isar.writeTxn(() async {
      await isar.collection<VaultItem>().clear();
      if (alsoDeleteCloud) {
        await isar.collection<AppConfig>().clear();
      }
    });

    // Recreate attachments directory to avoid path errors
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    // 3. Cloud wipe
    if (alsoDeleteCloud && currentUser != null) {
      // Wipe Firestore
      await firebaseSyncService.wipeData(currentUser.uid);

      // Wipe Drive
      if (userAccessToken != null) {
        final driveService = DriveService(
          GoogleAuthClient({'Authorization': 'Bearer $userAccessToken'}),
        );
        try {
          await driveService.deleteBackup();
        } finally {
          driveService.dispose();
        }
      }
    }
  }
}
