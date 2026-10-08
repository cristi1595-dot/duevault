import 'package:isar_community/isar.dart';
import '../models/vault_item.dart';
import '../utils/logger.dart';
import '../utils/date_helper.dart';
import 'notification_service.dart';

/// Manages automated operations for vault items including recurring bills, autopay, and auto-archiving.
class VaultAutomationManager {
  final Isar isar;

  VaultAutomationManager(this.isar);

  /// Generate the next recurring instance of a bill.
  /// Prevents duplicates by checking both nextUuid and semantic equivalence (same title, itemType, dueDate, amount).
  /// Safely advances past-due recurring instances to the active/upcoming cycle.
  Future<void> generateNextRecurringInstance(VaultItem parent) async {
    if (parent.dueDate == null || parent.recurrence == 'None' || parent.itemType != 'Bill') {
      return;
    }

    DateTime nextDate = DateHelper.calculateNextDueDate(
      parent.dueDate!,
      parent.recurrence,
      targetDay: parent.originalDueDay ?? parent.dueDate!.day,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If nextDate is still in the past (e.g. app wasn't opened for multiple cycles),
    // advance it until it reaches today or a future date so we don't generate stale past duplicates.
    while (nextDate.isBefore(today)) {
      final advanced = DateHelper.calculateNextDueDate(
        nextDate,
        parent.recurrence,
        targetDay: parent.originalDueDay ?? parent.dueDate!.day,
      );
      if (advanced.isAfter(nextDate)) {
        nextDate = advanced;
      } else {
        break;
      }
    }

    final nextUuid = 'next_${parent.uuid}_${nextDate.millisecondsSinceEpoch}';
    final existingNext = await isar
        .collection<VaultItem>()
        .filter()
        .uuidEqualTo(nextUuid)
        .findFirst();

    // Semantic check: does an item for this parent already exist on nextDate?
    final nextDayStart = DateTime(nextDate.year, nextDate.month, nextDate.day);
    final nextDayEnd = DateTime(nextDate.year, nextDate.month, nextDate.day, 23, 59, 59);

    final existingCandidates = await isar
        .collection<VaultItem>()
        .filter()
        .ownerIdEqualTo(parent.ownerId)
        .isDeletedEqualTo(false)
        .itemTypeEqualTo(parent.itemType)
        .dueDateBetween(nextDayStart, nextDayEnd)
        .findAll();

    final alreadyExists = existingNext != null ||
        existingCandidates.any((c) =>
            c.title.trim().toLowerCase() == parent.title.trim().toLowerCase() &&
            (c.amount == parent.amount ||
                (c.amount != null &&
                    parent.amount != null &&
                    (c.amount! - parent.amount!).abs() < 0.01)));

    if (!alreadyExists) {
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
        ..originalDueDay = parent.originalDueDay ?? parent.dueDate!.day
        ..notes = parent.notes
        ..attachedFiles = List<String>.from(parent.attachedFiles)
        ..lastModified = DateTime.now()
        ..wasSynced = false;

      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().put(nextItem);
      });
      logger.i('VaultAutomationManager: Generated next recurring instance for "${parent.title}" due on $nextDate');
    }
  }

  /// Process Autopay bills and auto-archive expired items:
  /// 1. Autopay bills whose due date is past or today:
  ///    - Marked as isPaid = true
  ///    - If recurring, next instance is generated
  ///    - If strictly before today, marked as isArchived = true
  /// 2. Regular paid items strictly before today:
  ///    - Marked as isArchived = true
  Future<void> processAutopayAndRecurrence(String ownerId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Find all active autopay bills where dueDate is past or today
    final autopayBills = await isar
        .collection<VaultItem>()
        .filter()
        .ownerIdEqualTo(ownerId)
        .isDeletedEqualTo(false)
        .directDebitEqualTo(true)
        .dueDateLessThan(today.add(const Duration(days: 1))) // includes today
        .findAll();

    final updatedBills = <VaultItem>[];
    for (final bill in autopayBills) {
      if (bill.dueDate == null) continue;
      final dueDayOnly = DateTime(bill.dueDate!.year, bill.dueDate!.month, bill.dueDate!.day);
      final isPast = dueDayOnly.isBefore(today);

      bool needsUpdate = false;
      if (!bill.isPaid) {
        bill.isPaid = true;
        needsUpdate = true;
      }

      if (isPast && !bill.isArchived) {
        bill.isArchived = true;
        needsUpdate = true;
      }

      if (needsUpdate) {
        bill.lastModified = DateTime.now();
        bill.wasSynced = false;
        updatedBills.add(bill);
      }
    }

    if (updatedBills.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().putAll(updatedBills);
      });
    }

    // Generate next recurring instance if recurring
    for (final bill in autopayBills) {
      if (bill.recurrence != 'None' && bill.itemType == 'Bill') {
        await generateNextRecurringInstance(bill);
      }
    }

    // 2. Auto-archive regular paid expired items
    final paidExpired = await isar
        .collection<VaultItem>()
        .filter()
        .ownerIdEqualTo(ownerId)
        .isDeletedEqualTo(false)
        .isArchivedEqualTo(false)
        .isPaidEqualTo(true)
        .dueDateLessThan(today)
        .findAll();

    if (paidExpired.isNotEmpty) {
      await isar.writeTxn(() async {
        for (var item in paidExpired) {
          item.isArchived = true;
          item.lastModified = DateTime.now();
          item.wasSynced = false;
        }
        await isar.collection<VaultItem>().putAll(paidExpired);
      });
      // Also ensure recurring instances exist for paid expired items
      for (var item in paidExpired) {
        if (item.recurrence != 'None' && item.itemType == 'Bill' && item.dueDate != null) {
          await generateNextRecurringInstance(item);
        }
      }
    }
  }

  /// Alias for backward compatibility
  Future<void> autoArchiveExpiredItems(String ownerId) async {
    await processAutopayAndRecurrence(ownerId);
  }

  /// Cleans up any existing duplicate items in the database.
  /// Two items are duplicates if they have the same owner, itemType, normalized title,
  /// same calendar due date, and same amount.
  Future<int> deduplicateItems(String ownerId) async {
    final allItems = await isar
        .collection<VaultItem>()
        .filter()
        .ownerIdEqualTo(ownerId)
        .isDeletedEqualTo(false)
        .findAll();

    if (allItems.isEmpty) return 0;

    final groups = <String, List<VaultItem>>{};
    for (final item in allItems) {
      final normTitle = item.title.trim().toLowerCase();
      final type = item.itemType ?? 'Bill';
      final dueStr = item.dueDate != null
          ? '${item.dueDate!.year}-${item.dueDate!.month.toString().padLeft(2, '0')}-${item.dueDate!.day.toString().padLeft(2, '0')}'
          : 'no_date';
      final amtStr = item.amount != null ? item.amount!.toStringAsFixed(2) : 'no_amt';
      final key = '$normTitle|$type|$dueStr|$amtStr';
      groups.putIfAbsent(key, () => []).add(item);
    }

    final List<VaultItem> toDelete = [];
    for (final entry in groups.entries) {
      final duplicates = entry.value;
      if (duplicates.length > 1) {
        // Sort to determine the primary item to keep:
        // 1. Has attachments first
        // 2. Was synced first
        // 3. Latest lastModified
        // 4. Lowest ID
        duplicates.sort((a, b) {
          final aHasFiles = a.attachedFiles.isNotEmpty ? 1 : 0;
          final bHasFiles = b.attachedFiles.isNotEmpty ? 1 : 0;
          if (aHasFiles != bHasFiles) return bHasFiles.compareTo(aHasFiles);

          final aSynced = a.wasSynced ? 1 : 0;
          final bSynced = b.wasSynced ? 1 : 0;
          if (aSynced != bSynced) return bSynced.compareTo(aSynced);

          final modComp = b.lastModified.compareTo(a.lastModified);
          if (modComp != 0) return modComp;

          return a.id.compareTo(b.id);
        });

        // Keep duplicates.first, soft-delete the rest so they disappear locally and get tombstoned for sync
        for (int i = 1; i < duplicates.length; i++) {
          final dup = duplicates[i];
          dup.isDeleted = true;
          dup.wasSynced = false;
          dup.lastModified = DateTime.now();
          toDelete.add(dup);
        }
      }
    }

    if (toDelete.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().putAll(toDelete);
      });
      for (final item in toDelete) {
        await NotificationService.cancelBillNotifications(item.id);
      }
      logger.i('VaultAutomationManager: Removed ${toDelete.length} duplicate items for owner $ownerId');
    }
    return toDelete.length;
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
