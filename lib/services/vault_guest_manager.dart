import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/vault_item.dart';
import '../utils/logger.dart';

/// Manages guest data operations including migration, deletion, and sample data generation.
class VaultGuestManager {
  final Isar isar;

  VaultGuestManager(this.isar);

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
            // Don't migrate sample data if the user is logging in
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

            bool isSemanticDup = false;
            if (existing == null && item.dueDate != null) {
              final dayStart = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
              final dayEnd = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day, 23, 59, 59);
              final candidates = await isar
                  .collection<VaultItem>()
                  .filter()
                  .ownerIdEqualTo(newUid)
                  .isDeletedEqualTo(false)
                  .itemTypeEqualTo(item.itemType)
                  .dueDateBetween(dayStart, dayEnd)
                  .findAll();
              isSemanticDup = candidates.any((c) =>
                  c.title.trim().toLowerCase() == item.title.trim().toLowerCase() &&
                  (c.amount == item.amount ||
                      (c.amount != null &&
                          item.amount != null &&
                          (c.amount! - item.amount!).abs() < 0.01)));
            }

            if (existing != null || isSemanticDup) {
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

  /// Delete all guest data
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

  /// Returns true if there is real (non-sample) data for guest mode
  Future<bool> hasRealGuestData() async {
    try {
      final items = await isar
          .collection<VaultItem>()
          .filter()
          .group((q) => q.ownerIdEqualTo('local_user').or().ownerIdEqualTo(''))
          .isDeletedEqualTo(false)
          .findAll();

      final realItems = items.where((i) => i.isSample == false).toList();
      logger.i(
        'VaultGuestManager: Found ${items.length} guest items, ${realItems.length} are real.',
      );
      return realItems.isNotEmpty;
    } catch (e) {
      logger.e('Error checking guest data', error: e);
      return false;
    }
  }

  /// Delete all sample items
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
      logger.i('VaultGuestManager: Deleted ${samples.length} sample items.');
    }
  }

  /// Generate sample data for a user
  Future<void> generateSampleData(String ownerId) async {
    final now = DateTime.now();
    const uuid = Uuid();
    final samples = [
      // BILL 1: Urgent (Due in 2 days)
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Electric Utility (National Grid)'
        ..itemType = 'Bill'
        ..category = 'Utilities'
        ..amount = 125.40
        ..dueDate = now.add(const Duration(days: 2))
        ..recurrence = 'Monthly'
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,

      // BILL 2: Warning (Due in 5 days)
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'High-Speed Fiber Internet'
        ..itemType = 'Bill'
        ..category = 'Utilities'
        ..amount = 69.99
        ..dueDate = now.add(const Duration(days: 5))
        ..recurrence = 'Monthly'
        ..directDebit = true
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,

      // BILL 3: Safe (Due in 12 days)
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Apartment Rent'
        ..itemType = 'Bill'
        ..category = 'Housing'
        ..amount = 1450.00
        ..dueDate = now.add(const Duration(days: 12))
        ..recurrence = 'Monthly'
        ..directDebit = true
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,

      // BILL 4: Safe (Due in 18 days)
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Auto Insurance (Geico)'
        ..itemType = 'Bill'
        ..category = 'Insurance'
        ..amount = 185.00
        ..dueDate = now.add(const Duration(days: 18))
        ..recurrence = 'Monthly'
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,

      // BILL 5: Safe (Due in 24 days)
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Spotify Family Subscription'
        ..itemType = 'Bill'
        ..category = 'Subscriptions'
        ..amount = 16.99
        ..dueDate = now.add(const Duration(days: 24))
        ..recurrence = 'Monthly'
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,

      // DOCUMENT 1: Warning (Expiring in 4 days)
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Residential Parking Permit'
        ..itemType = 'Document'
        ..category = 'Housing'
        ..dueDate = now.add(const Duration(days: 4))
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,

      // DOCUMENT 2: Expiring in 15 days (Warning)
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Car Insurance Policy'
        ..itemType = 'Document'
        ..category = 'Insurance'
        ..dueDate = now.add(const Duration(days: 15))
        ..isPaid = false
        ..isSample = true
        ..ownerId = ownerId,

      // DOCUMENT 3: Passport (Long expiry)
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Passport (US Citizen)'
        ..itemType = 'Document'
        ..category = 'Identity'
        ..dueDate = now.add(const Duration(days: 1825))
        ..isSample = true
        ..ownerId = ownerId,

      // DOCUMENT 4: Driver License
      VaultItem()
        ..uuid = uuid.v4()
        ..title = "Driver's License"
        ..itemType = 'Document'
        ..category = 'Identity'
        ..dueDate = now.add(const Duration(days: 340))
        ..isSample = true
        ..ownerId = ownerId,

      // DOCUMENT 5: Apartment Lease
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Apartment Lease Agreement'
        ..itemType = 'Document'
        ..category = 'Housing'
        ..dueDate = now.add(const Duration(days: 90))
        ..isSample = true
        ..ownerId = ownerId,

      // BILL 6 (Paid & Settled): Cloud Storage
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Cloud Storage (Google One)'
        ..itemType = 'Bill'
        ..category = 'Subscriptions'
        ..amount = 9.99
        ..dueDate = now.subtract(const Duration(days: 2))
        ..recurrence = 'Monthly'
        ..directDebit = true
        ..isPaid = true
        ..isSample = true
        ..ownerId = ownerId,

      // DOCUMENT 6 (Renewed): Health Insurance
      VaultItem()
        ..uuid = uuid.v4()
        ..title = 'Health Insurance Policy'
        ..itemType = 'Document'
        ..category = 'Health'
        ..dueDate = now.subtract(const Duration(days: 5))
        ..isPaid = true
        ..isSample = true
        ..ownerId = ownerId,
    ];

    await isar.writeTxn(() async {
      await isar.collection<VaultItem>().putAll(samples);
    });
  }
}
