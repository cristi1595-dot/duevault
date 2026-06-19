import 'package:isar_community/isar.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/drive_service.dart';
import '../models/vault_item.dart';
import '../models/app_config.dart';
import '../services/notification_service.dart';
import '../services/vault_item_processor.dart';
import '../services/vault_guest_manager.dart';
import '../services/vault_automation_manager.dart';
import '../utils/logger.dart';

class VaultRepository {
  final Isar isar;
  late final VaultGuestManager _guestManager;
  late final VaultAutomationManager _automationManager;

  VaultRepository(this.isar) {
    _guestManager = VaultGuestManager(isar);
    _automationManager = VaultAutomationManager(isar);
  }

  /// Load all items for a specific owner
  Future<List<VaultItem>> getItems(String ownerId) async {
    try {
      return await isar
          .collection<VaultItem>()
          .filter()
          .ownerIdEqualTo(ownerId)
          .isDeletedEqualTo(false)
          .findAll();
    } catch (e, stack) {
      logger.e(
        'Error loading items for owner: $ownerId',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Mark an item as deleted (soft delete)
  Future<void> softDeleteItem(int id) async {
    try {
      final item = await isar.collection<VaultItem>().get(id);
      if (item != null) {
        await isar.writeTxn(() async {
          item.isDeleted = true;
          item.lastModified = DateTime.now();
          item.wasSynced = false;
          item.cloudFileIds = [];
          await isar.collection<VaultItem>().put(item);
        });

        await NotificationService.cancelBillNotifications(id);
        logger.i('Item soft-deleted: $id');
      }
    } catch (e, stack) {
      logger.e('Error during soft delete: $id', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Add or update a vault item with file processing and encryption
  Future<VaultItem> saveItem(
    VaultItem item, {
    int? alertDays,
    bool? threeDayAlertEnabled,
    int? finalReminderDays,
    bool? finalReminderEnabled,
    int? notificationHour,
    int? notificationMinute,
    bool notificationsEnabled = false,
    String? userAccessToken,
  }) async {
    try {
      // 1. If updating an existing item, compare attachments to detect removals
      if (item.id != Isar.autoIncrement) {
        final oldItem = await isar.collection<VaultItem>().get(item.id);
        if (oldItem != null) {
          final List<String> removedFiles = [];
          final List<String> removedCloudIds = [];

          for (int i = 0; i < oldItem.attachedFiles.length; i++) {
            final oldPath = oldItem.attachedFiles[i];
            final oldFileName = p.basename(oldPath.replaceAll('\\', '/'));

            // Check if this file is still present in the updated item's attachments
            final stillExists = item.attachedFiles.any((newPath) =>
                p.basename(newPath.replaceAll('\\', '/')) == oldFileName);

            if (!stillExists) {
              removedFiles.add(oldFileName);
              if (i < oldItem.cloudFileIds.length) {
                removedCloudIds.add(oldItem.cloudFileIds[i]);
              }
            }
          }

          // Delete removed files locally
          if (removedFiles.isNotEmpty) {
            final appDir = await getApplicationDocumentsDirectory();
            for (final fileName in removedFiles) {
              try {
                final file = File('${appDir.path}/attachments/$fileName');
                if (await file.exists()) {
                  await file.delete();
                  logger.i('Local removed file deleted: $fileName');
                }
              } catch (e) {
                logger.e('Failed to delete local removed file: $fileName', error: e);
              }
            }
          }

          // Delete removed files from cloud
          if (removedCloudIds.isNotEmpty && userAccessToken != null) {
            for (final cloudId in removedCloudIds) {
              if (cloudId.isNotEmpty) {
                unawaited(_deleteCloudFile(cloudId, userAccessToken));
              }
            }
          }

          // Align cloudFileIds and cloudFileChecksums of updated item
          final List<String> newCloudIds = [];
          final List<String> newChecksums = [];
          for (int i = 0; i < oldItem.attachedFiles.length; i++) {
            final oldFileName = p.basename(oldItem.attachedFiles[i].replaceAll('\\', '/'));
            final stillExists = item.attachedFiles.any((newPath) =>
                p.basename(newPath.replaceAll('\\', '/')) == oldFileName);
            if (stillExists) {
              if (i < oldItem.cloudFileIds.length) {
                newCloudIds.add(oldItem.cloudFileIds[i]);
              }
              if (i < oldItem.cloudFileChecksums.length) {
                newChecksums.add(oldItem.cloudFileChecksums[i]);
              }
            }
          }
          item.cloudFileIds = newCloudIds;
          item.cloudFileChecksums = newChecksums;
        }
      }

      // Process the item (validation, encryption, file handling)
      final processedItem = await VaultItemProcessor.prepareForSave(item);

      // Persist to database
      try {
        await isar.writeTxn(() async {
          await isar.collection<VaultItem>().put(processedItem);
        });
      } on IsarError catch (e) {
        if (e.toString().contains('full') || e.toString().contains('Disk')) {
          throw Exception(
            'Storage is full. Please free up some space and try again.',
          );
        }
        rethrow;
      }

      // Schedule notifications if enabled
      if (notificationsEnabled &&
          (processedItem.itemType == 'Bill' || processedItem.itemType == 'Document') &&
          processedItem.dueDate != null &&
          !processedItem.isPaid) {
        await NotificationService.scheduleDualAlerts(
          billId: processedItem.id,
          billTitle: processedItem.title,
          dueDate: processedItem.dueDate!,
          firstReminderDays: alertDays ?? 3,
          finalReminderDays: finalReminderDays ?? 0,
          isFirstReminderEnabled: threeDayAlertEnabled ?? true,
          isFinalReminderEnabled: finalReminderEnabled ?? true,
          notificationHour: notificationHour ?? 9,
          notificationMinute: notificationMinute ?? 0,
          itemType: processedItem.itemType ?? 'Document',
          amount: processedItem.amount,
        );
      }

      logger.i('Item saved successfully: ${processedItem.title} (${processedItem.uuid})');
      return processedItem;
    } catch (e, stack) {
      logger.e('Error saving item: ${item.title}', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Toggle paid status and handle recurring bill generation
  Future<VaultItem?> updatePaidStatus(int id, bool isPaid) async {
    try {
      final item = await isar.collection<VaultItem>().get(id);
      if (item == null) return null;

      // Handle UNDO for recurring bills
      if (!isPaid) {
        await _automationManager.handleRecurringUndo(item);
      }

      item.isPaid = isPaid;
      item.lastModified = DateTime.now();
      item.wasSynced = false;

      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().put(item);
      });

      if (isPaid) {
        await NotificationService.cancelBillNotifications(id);

        // Generate next instance for recurring bills
        if (item.recurrence != 'None' &&
            item.dueDate != null &&
            item.itemType == 'Bill') {
          await _automationManager.generateNextRecurringInstance(item);
        }
      }

      logger.i('Paid status updated for: ${item.title} -> $isPaid');
      return item;
    } catch (e, stack) {
      logger.e('Error updating paid status: $id', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> updateConfig(AppConfig config) async {
    await isar.writeTxn(() async {
      await isar.collection<AppConfig>().put(config);
    });
  }

  Future<AppConfig> getConfig() async {
    return await isar.collection<AppConfig>().get(0) ?? AppConfig();
  }

  // Guest Management Methods - Delegated to VaultGuestManager
  Future<void> migrateGuestData(String newUid) async {
    await _guestManager.migrateGuestData(newUid);
  }

  Future<void> deleteGuestData() async {
    await _guestManager.deleteGuestData();
  }

  Future<bool> hasRealGuestData() async {
    return _guestManager.hasRealGuestData();
  }

  Future<void> deleteSamplesForUser(String ownerId) async {
    await _guestManager.deleteSamplesForUser(ownerId);
  }

  Future<void> generateSampleData(String ownerId) async {
    await _guestManager.generateSampleData(ownerId);
  }

  // Automation Methods - Delegated to VaultAutomationManager
  Future<void> autoArchiveExpiredItems(String ownerId) async {
    await _automationManager.autoArchiveExpiredItems(ownerId);
  }

  Future<void> _deleteCloudFile(String fileId, String token) async {
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
