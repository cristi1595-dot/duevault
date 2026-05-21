import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/vault_item.dart';
import '../models/app_config.dart';
import '../utils/logger.dart';
import 'drive_service.dart';

/// Handles the logic for merging cloud data with local data.
class SyncConflictResolver {
  final Isar localIsar;
  final User user;

  SyncConflictResolver({
    required this.localIsar,
    required this.user,
  });

  /// Advanced Smart Merge: Resolves multi-device conflicts using UUIDs and timestamps.
  /// Does NOT overwrite the whole DB.
  Future<Map<String, bool>> mergeWithCloud(
    DriveService driveService, {
    bool isLoginSync = false,
  }) async {
    // 1. Download cloud data to a temp isolate
    final cloudIsar = await driveService.downloadAndOpenDatabase(
      'merge_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    if (cloudIsar == null) {
      return {'localModified': false, 'cloudModified': false};
    }

    try {
      final cloudItems = await cloudIsar
          .collection<VaultItem>()
          .filter()
          .ownerIdEqualTo(user.uid)
          .findAll();
      final localItems = await localIsar
          .collection<VaultItem>()
          .filter()
          .ownerIdEqualTo(user.uid)
          .findAll();

      bool localModified = false;
      bool cloudModified = false;

      await localIsar.writeTxn(() async {
        for (var cloudItem in cloudItems) {
          // Match by UUID for rock-solid identification
          final localItem = localItems
              .where((i) => i.uuid == cloudItem.uuid)
              .firstOrNull;

          if (localItem == null) {
            // If localItem is null and we don't have a record of it, it's new from cloud.
            if (cloudItem.uuid.isEmpty) {
              cloudItem.uuid = const Uuid().v4();
            }
            cloudItem.wasSynced = true; // Mark as synced
            await localIsar.collection<VaultItem>().put(
              cloudItem..id = Isar.autoIncrement,
            );
            localModified = true;
          } else {
            // Item exists in both -> Resolve by lastModified
            if (cloudItem.lastModified.isAfter(
              localItem.lastModified.add(const Duration(seconds: 1)),
            )) {
              // Cloud version is NEWER -> Update local
              cloudItem.id = localItem.id; // Keep local database ID
              cloudItem.wasSynced = true; // Mark as synced
              await localIsar.vaultItems.put(cloudItem);
              localModified = true;
            } else if (localItem.lastModified.isAfter(
              cloudItem.lastModified.add(const Duration(seconds: 1)),
            )) {
              // Local version is NEWER -> Cloud version is stale
              cloudModified = true;
            }

            // SPECIAL CASE: Deletion sync
            // If cloud item is marked as deleted but local is not
            if (cloudItem.isDeleted && !localItem.isDeleted) {
              localItem.isDeleted = true;
              localItem.lastModified = cloudItem.lastModified;
              await localIsar.collection<VaultItem>().put(localItem);
              localModified = true;
            }
          }
        }
      });

      // 2. Check for local items that don't exist in cloud -> They need to be uploaded
      // OR if they were previously synced, it means they were deleted on another device.
      for (var localItem in localItems) {
        final existsInCloud = cloudItems.any((i) => i.uuid == localItem.uuid);
        if (!existsInCloud) {
          if (localItem.wasSynced && !isLoginSync) {
            // Item was in cloud before, but is gone now -> Deleted from another device
            logger.i(
              'SyncConflictResolver: Local item "${localItem.title}" was deleted from cloud. Removing locally...',
            );
            await localIsar.writeTxn(() async {
              await localIsar.collection<VaultItem>().delete(localItem.id);
            });
            localModified = true;
          } else {
            // New local item that hasn't reached the cloud yet
            cloudModified = true;
          }
        }
      }

      return {
        'localModified': localModified,
        'cloudModified': cloudModified,
      };
    } catch (e, stack) {
      logger.e('SyncConflictResolver: Merge error', error: e, stackTrace: stack);
      return {'localModified': false, 'cloudModified': false};
    } finally {
      await cloudIsar.close();
    }
  }

  /// Update sync markers in the local database
  Future<void> updateSyncMarkers() async {
    await localIsar.writeTxn(() async {
      final config = await localIsar.collection<AppConfig>().get(0) ?? AppConfig();
      config.lastCloudSync = DateTime.now();
      config.lastLocalChange = DateTime.now();
      await localIsar.collection<AppConfig>().put(config);
    });
  }
}
