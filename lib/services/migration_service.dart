import 'package:isar/isar.dart';

import '../models/app_config.dart';
import '../models/vault_item.dart';

import '../utils/logger.dart';

class MigrationService {
  /// The current version of the data structure. 
  /// Increment this when you need to trigger a new migration.
  static const int currentDataVersion = 3;


  static Future<void> runMigrations(Isar isar) async {
    final config = await isar.collection<AppConfig>().get(0) ?? AppConfig();
    
    if (config.dataVersion < currentDataVersion) {
      logger.i('MigrationService: Starting migration from v${config.dataVersion} to v$currentDataVersion');
      
      // RUN MIGRATIONS SEQUENTIALLY
      if (config.dataVersion < 2) {
        await _migrateToV2(isar);
      }
      if (config.dataVersion < 3) {
        await _migrateToV3(isar);
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
}

