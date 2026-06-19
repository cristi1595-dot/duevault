import 'package:isar_community/isar.dart';
import '../models/vault_item.dart';
import '../utils/logger.dart';
import '../utils/date_helper.dart';

/// Manages automated operations for vault items including recurring bills and auto-archiving.
class VaultAutomationManager {
  final Isar isar;

  VaultAutomationManager(this.isar);

  /// Generate the next recurring instance of a bill
  Future<void> generateNextRecurringInstance(VaultItem parent) async {
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
        ..wasSynced = false;

      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().put(nextItem);
      });
      logger.i('Generated next recurring instance for: ${parent.title}');
    }
  }

  /// Auto-archive expired items based on rules:
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
        'VaultAutomationManager: Auto-archiving ${toArchive.length} expired items.',
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

  /// Handle UNDO for recurring bills - delete the next instance if it exists
  Future<void> handleRecurringUndo(VaultItem item) async {
    if (item.recurrence != 'None' &&
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
        await isar.writeTxn(() async {
          existingNext.isDeleted = true;
          existingNext.lastModified = DateTime.now();
          existingNext.wasSynced = false;
          existingNext.cloudFileIds = [];
          await isar.collection<VaultItem>().put(existingNext);
        });
        logger.i('Deleted next recurring instance during undo: ${existingNext.title}');
      }
    }
  }
}
