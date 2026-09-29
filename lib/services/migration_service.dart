import 'package:isar_community/isar.dart';

import '../models/app_config.dart';
import '../models/vault_item.dart';

import '../utils/logger.dart';
import 'vault_automation_manager.dart';

class MigrationService {
  /// The current version of the data structure.
  /// Increment this when you need to trigger a new migration.
  static const int currentDataVersion = 5;

  static Future<void> runMigrations(Isar isar) async {
    final config = await isar.collection<AppConfig>().get(0) ?? AppConfig();

    if (config.dataVersion < currentDataVersion) {
      logger.i(
        'MigrationService: Starting migration from v${config.dataVersion} to v$currentDataVersion',
      );

      // RUN MIGRATIONS SEQUENTIALLY
      if (config.dataVersion < 2) {
        await _migrateToV2(isar);
      }
      if (config.dataVersion < 3) {
        await _migrateToV3(isar);
      }
      if (config.dataVersion < 4) {
        await _migrateToV4(isar);
      }
      if (config.dataVersion < 5) {
        await _migrateToV5(isar);
      }

      // After all migrations, update the version and trigger a cloud sync
      await isar.writeTxn(() async {
        config.dataVersion = currentDataVersion;
        config.lastLocalChange = DateTime.now(); // This triggers AutoSync
        await isar.collection<AppConfig>().put(config);
      });

      logger.i('MigrationService: Migration complete.');
    }
  }

  /// Migration v2: Standardize categories
  static Future<void> _migrateToV2(Isar isar) async {
    logger.i('MigrationService: Migrating categories...');

    // Define the old -> new mapping here
    final categoryMapping = {
      'Utility': 'Utilities',
      'House': 'Housing',
      'Car': 'Auto',
      'Internet': 'Telecom',
      'Phone': 'Telecom',
      'Gas': 'Utilities',
      'Water': 'Utilities',
      'Rent': 'Housing',
      'ID Card': 'Identity',
      'Health Insurance': 'Health',
    };

    final items = await isar.collection<VaultItem>().where().findAll();
    final List<VaultItem> toUpdate = [];

    for (var item in items) {
      if (categoryMapping.containsKey(item.category)) {
        item.category = categoryMapping[item.category]!;
        item.lastModified = DateTime.now();
        toUpdate.add(item);
      }
    }

    if (toUpdate.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().putAll(toUpdate);
      });
    }

    logger.i('MigrationService: Migrated ${toUpdate.length} items.');
  }

  /// Migration v3: Fix 'Credit Card' and 'Vehicle' renamings
  static Future<void> _migrateToV3(Isar isar) async {
    logger.i('MigrationService: Migrating categories v3...');

    final categoryMapping = {
      'Credit Card': 'Loans',
      'Vehicle': 'Auto',
      'Contract': 'Legal',
      // Standardize plural vs singular if needed
      'Subscription': 'Subscriptions',
    };

    final allItems = await isar.collection<VaultItem>().where().findAll();
    final List<VaultItem> toUpdate = [];

    await isar.writeTxn(() async {
      for (final item in allItems) {
        if (categoryMapping.containsKey(item.category)) {
          item.category = categoryMapping[item.category]!;
          item.lastModified = DateTime.now();
          toUpdate.add(item);
        }
      }
      if (toUpdate.isNotEmpty) {
        await isar.collection<VaultItem>().putAll(toUpdate);
      }
    });

    logger.i('MigrationService: Migrated ${toUpdate.length} items in v3.');
  }

  /// Migration v4: Rename 'Legal' category to 'Auto' for documents
  static Future<void> _migrateToV4(Isar isar) async {
    logger.i('MigrationService: Migrating categories v4...');

    final allItems = await isar.collection<VaultItem>().where().findAll();
    final List<VaultItem> toUpdate = [];

    await isar.writeTxn(() async {
      for (final item in allItems) {
        if (item.category == 'Legal' && item.itemType == 'Document') {
          item.category = 'Auto';
          item.lastModified = DateTime.now();
          item.wasSynced = false; // Mark for sync engine so cloud updates
          toUpdate.add(item);
        }
      }
      if (toUpdate.isNotEmpty) {
        await isar.collection<VaultItem>().putAll(toUpdate);
      }
    });

    logger.i('MigrationService: Migrated ${toUpdate.length} items in v4.');
  }

  /// Migration v5: Deduplicate any duplicate vault items created by sync/migration
  static Future<void> _migrateToV5(Isar isar) async {
    logger.i('MigrationService: Running deduplication migration v5...');
    final automationManager = VaultAutomationManager(isar);
    final allItems = await isar.collection<VaultItem>().where().findAll();
    final owners = allItems.map((i) => i.ownerId).toSet();
    int totalRemoved = 0;
    for (final ownerId in owners) {
      totalRemoved += await automationManager.deduplicateItems(ownerId);
    }
    logger.i('MigrationService: v5 finished. Deduplicated $totalRemoved duplicate items.');
  }
}
