import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../models/vault_item.dart';
import '../models/app_config.dart';
import '../services/encryption_service.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';
import '../utils/date_helper.dart';

class VaultRepository {
  final Isar isar;

  VaultRepository(this.isar);

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
          item.wasSynced = false; // Mark for sync engine
          item.cloudFileIds = []; // Clear cloud IDs for cleanup
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
  }) async {
    try {
      // 1. Normalize dates
      if (item.dueDate != null) {
        item.dueDate = DateTime(
          item.dueDate!.year,
          item.dueDate!.month,
          item.dueDate!.day,
        );
        if (item.recurrence != 'None') {
          item.originalDueDay ??= item.dueDate!.day;
        }
      }

      // 2. Ensure identity
      if (item.uuid.isEmpty) {
        item.uuid = const Uuid().v4();
      }

      // 3. Process attachments
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final List<String> finalPaths = [];
      final List<String> checksums = [];

      for (final path in item.attachedFiles) {
        // Only process files that are NOT already in our internal attachments folder
        if (!path.contains('app_flutter/attachments')) {
          final originalFile = File(path);
          if (await originalFile.exists()) {
            final fileName =
                'doc_${DateTime.now().microsecondsSinceEpoch}_${p.basename(path)}';
            final newPath = '${attachmentsDir.path}/$fileName';

            // Optimization: Read and Write once. Encryption is handled in-place for now,
            // but we ensure the file exists in the destination first.
            try {
              final bytes = await originalFile.readAsBytes();
              final fileToSave = File(newPath);
              await fileToSave.writeAsBytes(bytes);
              await EncryptionService.encryptFile(newPath);

              // Calculate MD5 of the encrypted file for cloud comparison
              final encryptedBytes = await fileToSave.readAsBytes();
              checksums.add(md5.convert(encryptedBytes).toString());
            } on FileSystemException catch (e) {
              if (e.osError?.errorCode == 28 || e.message.contains('space')) {
                throw Exception('Cannot save attachment: Storage is full.');
              }
              rethrow;
            }

            finalPaths.add(newPath);
          }
        } else {
          // Already in internal storage, just recalculate checksum if missing or verify it
          finalPaths.add(path);
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            checksums.add(md5.convert(bytes).toString());
          }
        }
      }
      item.attachedFiles = finalPaths;
      item.cloudFileChecksums = checksums;

      // 4. Encrypt notes
      if (item.notes != null &&
          item.notes!.isNotEmpty &&
          !item.notes!.startsWith('encrypted:')) {
        // Check if already encrypted to avoid double encryption (Senior check)
        final encrypted = await EncryptionService.encryptText(item.notes);
        if (encrypted != null) {
          item.notes = 'encrypted:$encrypted';
        }
      }

      item.lastModified = DateTime.now();
      item.wasSynced = false; // Mark for sync engine

      // 5. Persist
      try {
        await isar.writeTxn(() async {
          await isar.collection<VaultItem>().put(item);
        });
      } on IsarError catch (e) {
        if (e.toString().contains('full') || e.toString().contains('Disk')) {
          throw Exception(
            'Storage is full. Please free up some space and try again.',
          );
        }
        rethrow;
      }

      // 6. Notifications
      if (notificationsEnabled &&
          (item.itemType == 'Bill' || item.itemType == 'Document') &&
          item.dueDate != null &&
          !item.isPaid) {
        await NotificationService.scheduleDualAlerts(
          billId: item.id,
          billTitle: item.title,
          dueDate: item.dueDate!,
          firstReminderDays: alertDays ?? 3,
          finalReminderDays: finalReminderDays ?? 0,
          isFirstReminderEnabled: threeDayAlertEnabled ?? true,
          isFinalReminderEnabled: finalReminderEnabled ?? true,
          notificationHour: notificationHour ?? 9,
          notificationMinute: notificationMinute ?? 0,
          itemType: item.itemType ?? 'Document',
          amount: item.amount,
        );
      }

      logger.i('Item saved successfully: ${item.title} (${item.uuid})');
      return item;
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
      if (!isPaid &&
          item.recurrence != 'None' &&
          item.dueDate != null &&
          item.itemType == 'Bill') {
        final nextDate = DateHelper.calculateNextDueDate(
          item.dueDate!,
          item.recurrence,
        );
        final nextUuid = 'next_${item.uuid}_${nextDate.millisecondsSinceEpoch}';

        final existingNext = await isar
            .collection<VaultItem>()
            .filter()
            .uuidEqualTo(nextUuid)
            .isPaidEqualTo(false)
            .findFirst();

        if (existingNext != null) {
          await softDeleteItem(existingNext.id);
        }
      }

      item.isPaid = isPaid;
      item.lastModified = DateTime.now();
      item.wasSynced = false; // Mark for sync engine

      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().put(item);
      });

      if (isPaid) {
        await NotificationService.cancelBillNotifications(id);

        // Generate next instance for recurring bills
        if (item.recurrence != 'None' &&
            item.dueDate != null &&
            item.itemType == 'Bill') {
          await _generateNextRecurringInstance(item);
        }
      }

      logger.i('Paid status updated for: ${item.title} -> $isPaid');
      return item;
    } catch (e, stack) {
      logger.e('Error updating paid status: $id', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _generateNextRecurringInstance(VaultItem parent) async {
    final nextDate = DateHelper.calculateNextDueDate(
      parent.dueDate!,
      parent.recurrence,
      targetDay: parent.originalDueDay,
    );

    final nextUuid = 'next_${parent.uuid}_${nextDate.millisecondsSinceEpoch}';
    final existingNext = await isar
        .collection<VaultItem>()
        .filter()
        .uuidEqualTo(nextUuid)
        .findFirst();

    if (existingNext == null) {
      final nextItem = VaultItem()
        ..ownerId = parent.ownerId
        ..title = parent.title
        ..category = parent.category
        ..amount = parent.amount
        ..itemType = parent.itemType
        ..recurrence = parent.recurrence
        ..directDebit = parent.directDebit
        ..dueDate = nextDate
        ..isPaid = false
        ..uuid = nextUuid
        ..originalDueDay = parent.originalDueDay
        ..lastModified = DateTime.now()
        ..wasSynced = false; // Mark for sync engine

      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().put(nextItem);
      });
      logger.i('Generated next recurring instance for: ${parent.title}');
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

  /// Migrate items from 'local_user' to a real UID
  Future<void> migrateGuestData(String newUid) async {
    try {
      final guestItems = await isar
          .collection<VaultItem>()
          .filter()
          .group((q) => q.ownerIdEqualTo('local_user').or().ownerIdEqualTo(''))
          .findAll();

      if (guestItems.isNotEmpty) {
        logger.i('Migration: Starting for ${guestItems.length} items...');
        await isar.writeTxn(() async {
          for (var item in guestItems) {
            // Senior QA: Don't migrate sample data if the user is logging in
            if (item.isSample) {
              logger.i('Migration: Skipping sample item: ${item.title}');
              await isar.collection<VaultItem>().delete(item.id);
              continue;
            }

            final existing = await isar
                .collection<VaultItem>()
                .filter()
                .ownerIdEqualTo(newUid)
                .uuidEqualTo(item.uuid)
                .findFirst();

            if (existing != null) {
              logger.i(
                'Migration: Item "${item.title}" already exists in cloud account. Deleting guest copy.',
              );
              await isar.collection<VaultItem>().delete(item.id);
            } else {
              logger.i('Migration: Moving "${item.title}" to $newUid');
              item.ownerId = newUid;
              item.lastModified = DateTime.now();
              item.wasSynced = false;
              await isar.collection<VaultItem>().put(item);
            }
          }
        });
        logger.i('Migration: Finished processing guest items.');
      } else {
        logger.i('Migration: No guest data found to migrate.');
      }
    } catch (e, stack) {
      logger.e('Error migrating guest data', error: e, stackTrace: stack);
    }
  }

  Future<void> deleteGuestData() async {
    try {
      final guestItems = await isar
          .collection<VaultItem>()
          .filter()
          .group((q) => q.ownerIdEqualTo('local_user').or().ownerIdEqualTo(''))
          .findAll();

      if (guestItems.isNotEmpty) {
        logger.i(
          'Deletion: Starting to delete ${guestItems.length} guest items...',
        );
        await isar.writeTxn(() async {
          await isar.collection<VaultItem>().deleteAll(
            guestItems.map((item) => item.id).toList(),
          );
        });
        logger.i('Deletion: Finished deleting guest items.');
      }
    } catch (e, stack) {
      logger.e('Error deleting guest data', error: e, stackTrace: stack);
    }
  }

  /// Rules:
  /// 1. Bill + DirectDebit + Expired -> Auto-archive
  /// 2. Bill/Doc + Paid + Expired -> Auto-archive
  Future<void> autoArchiveExpiredItems(String ownerId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final toArchive = await isar
        .collection<VaultItem>()
        .filter()
        .ownerIdEqualTo(ownerId)
        .isArchivedEqualTo(false)
        .and()
        .group(
          (q) => q
              .group((q2) => q2.directDebitEqualTo(true).dueDateLessThan(today))
              .or()
              .group((q2) => q2.isPaidEqualTo(true).dueDateLessThan(today)),
        )
        .findAll();

    if (toArchive.isNotEmpty) {
      logger.i(
        'VaultRepository: Auto-archiving ${toArchive.length} expired items.',
      );
      await isar.writeTxn(() async {
        for (var item in toArchive) {
          item.isArchived = true;
          item.lastModified = DateTime.now();
          await isar.collection<VaultItem>().put(item);
        }
      });
    }
  }

  Future<void> deleteSamplesForUser(String ownerId) async {
    final samples = await isar
        .collection<VaultItem>()
        .filter()
        .isSampleEqualTo(true)
        .findAll();
    if (samples.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().deleteAll(
          samples.map((s) => s.id).toList(),
        );
      });
      logger.i('VaultRepository: Deleted ${samples.length} sample items.');
    }
  }

  Future<void> generateSampleData(String ownerId) async {
    final now = DateTime.now();
    const uuid = Uuid();
    final samples = [
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Electricity Bill (Demo)'
        ..itemType = 'Bill'
        ..category = 'Housing'
        ..amount = 45.0
        ..dueDate = now.subtract(const Duration(days: 2))
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Internet Subscription (Demo)'
        ..itemType = 'Bill'
        ..category = 'Subscriptions'
        ..amount = 29.99
        ..dueDate = now.add(const Duration(days: 5))
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Visa Credit Card (Demo)'
        ..itemType = 'Bill'
        ..category = 'Loans'
        ..amount = 150.0
        ..dueDate = now.add(const Duration(days: 10))
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Car Insurance (Demo)'
        ..itemType = 'Bill'
        ..category = 'Auto'
        ..amount = 85.50
        ..dueDate = now.add(const Duration(days: 15))
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Identity Card (Demo)'
        ..itemType = 'Document'
        ..category = 'Identity'
        ..dueDate = now.add(const Duration(days: 450))
        ..isSample = true
        ..ownerId = ownerId,
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Rental Agreement (Demo)'
        ..itemType = 'Document'
        ..category = 'Legal'
        ..dueDate = now.add(const Duration(days: 60))
        ..isSample = true
        ..ownerId = ownerId,
    ];

    await isar.writeTxn(() async {
      await isar.collection<VaultItem>().putAll(samples);
    });
  }

  /// Returns true if there is real (non-sample) data for guest mode
  Future<bool> hasRealGuestData() async {
    try {
      final items = await isar
          .collection<VaultItem>()
          .filter()
          .group((q) => q.ownerIdEqualTo('local_user').or().ownerIdEqualTo(''))
          .isDeletedEqualTo(false)
          .findAll();

      // Filter manually to be 100% sure about the sample flag
      final realItems = items.where((i) => i.isSample == false).toList();
      logger.i(
        'VaultRepository: Found ${items.length} guest items, ${realItems.length} are real.',
      );
      return realItems.isNotEmpty;
    } catch (e) {
      logger.e('Error checking guest data', error: e);
      return false;
    }
  }
}
