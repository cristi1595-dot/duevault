import 'package:isar/isar.dart';
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
        ..category = 'Auto'
        ..dueDate = now.add(const Duration(days: 60))
        ..isSample = true
        ..ownerId = ownerId,
    ];

    await isar.writeTxn(() async {
      await isar.collection<VaultItem>().putAll(samples);
    });
  }
}
