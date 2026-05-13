import 'dart:io';
// Vault items provider with auto-sync and local persistence
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/vault_item.dart';
import '../models/app_config.dart';
import 'database_provider.dart';
import '../services/auto_sync_service.dart';
import '../services/notification_service.dart';
import '../services/drive_service.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/encryption_service.dart';
import '../utils/date_helper.dart';
import 'package:uuid/uuid.dart';

class VaultNotifier extends Notifier<List<VaultItem>> {
  @override
  List<VaultItem> build() {
    // Watch auth state to trigger reload on login/logout
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    // Load items async
    _loadItems(user);
    
    return [];
  }

  /// Rules: 
  /// 1. Bill + DirectDebit + Expired -> Auto-archive
  /// 2. Bill/Doc + Paid + Expired -> Auto-archive
  Future<void> _autoArchiveExpiredItems(Isar isar, String ownerId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final toArchive = await isar.vaultItems.filter()
        .ownerIdEqualTo(ownerId)
        .isArchivedEqualTo(false)
        .and()
        .group((q) => q
          .group((q2) => q2.directDebitEqualTo(true).dueDateLessThan(today))
          .or()
          .group((q2) => q2.isPaidEqualTo(true).dueDateLessThan(today))
        )
        .findAll();

    if (toArchive.isNotEmpty) {
      debugPrint('VaultNotifier: Auto-archiving ${toArchive.length} expired items.');
      await isar.writeTxn(() async {
        for (var item in toArchive) {
          item.isArchived = true;
          await isar.vaultItems.put(item);
        }
      });
      await _markAsDirty();
    }
  }

  Future<void> _markAsDirty() async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.lastLocalChange = DateTime.now();
      await isar.appConfigs.put(config);
    });
  }

  Future<void> _loadItems(User? user) async {
    final isar = ref.read(isarProvider);

    List<VaultItem> items;
    if (user == null) {
      debugPrint('VaultNotifier: Loading items for GUEST (local_user)');
      // Guest mode: ONLY show items belonging to 'local_user'
      items = await isar.vaultItems
          .filter()
          .ownerIdEqualTo('local_user')
          .isDeletedEqualTo(false)
          .findAll();
    } else {
      debugPrint('VaultNotifier: Loading items for USER (${user.uid})');
      // Authenticated: ONLY show items belonging to this account
      items = await isar.vaultItems
          .filter()
          .ownerIdEqualTo(user.uid)
          .isDeletedEqualTo(false)
          .findAll();
    }

    // Run Smart Auto-Archive before setting state
    await _autoArchiveExpiredItems(isar, user?.uid ?? 'local_user');
    
    // Refresh items list if anything was archived
    if (user == null) {
      items = await isar.vaultItems.filter().ownerIdEqualTo('local_user').isDeletedEqualTo(false).findAll();
    } else {
      items = await isar.vaultItems.filter().ownerIdEqualTo(user.uid).isDeletedEqualTo(false).findAll();
    }
    
    // Decrypting items for the UI state: DEPRECATED (Moved to detail screen for speed)
    // for (var item in items) {
    //   item.notes = await EncryptionService.decryptText(item.notes);
    // }
    
    // Check if we need to add sample data (ONLY at the very first opening for guest mode)
    if (user == null) {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      if (!config.hasSeenDemo) {
        final totalCount = await isar.vaultItems.filter().ownerIdEqualTo('local_user').count();
        if (totalCount == 0) {
          debugPrint('VaultNotifier: Generating demo data for the first time.');
          await _generateSampleData();
          items = await isar.vaultItems.filter().ownerIdEqualTo('local_user').findAll();
        }
      }
    }
    
    state = items;
  }

  Future<void> _generateSampleData() async {
    final isar = ref.read(isarProvider);
    final now = DateTime.now();
    
    final samples = [
      // 1. Overdue Bill
      VaultItem()
        ..title = 'Electricity Bill (Demo)'
        ..itemType = 'Bill'
        ..category = 'Housing'
        ..amount = 45.0
        ..dueDate = now.subtract(const Duration(days: 2))
        ..isPaid = false
        ..isSample = true,
      
      // 2. Upcoming Bill
      VaultItem()
        ..title = 'Internet Subscription (Demo)'
        ..itemType = 'Bill'
        ..category = 'Subscriptions'
        ..amount = 29.99
        ..dueDate = now.add(const Duration(days: 5))
        ..isPaid = false
        ..isSample = true,

      // 3. Credit Card Bill
      VaultItem()
        ..title = 'Visa Credit Card (Demo)'
        ..itemType = 'Bill'
        ..category = 'Credit Card'
        ..amount = 150.0
        ..dueDate = now.add(const Duration(days: 10))
        ..isPaid = false
        ..isSample = true,

      // 4. Auto Bill
      VaultItem()
        ..title = 'Car Insurance (Demo)'
        ..itemType = 'Bill'
        ..category = 'Auto'
        ..amount = 85.50
        ..dueDate = now.add(const Duration(days: 15))
        ..isPaid = false
        ..isSample = true,

      // 5. Document 1
      VaultItem()
        ..title = 'Identity Card (Demo)'
        ..itemType = 'Document'
        ..category = 'Identity'
        ..dueDate = now.add(const Duration(days: 450))
        ..isSample = true
        ..notes = 'Sample document entry.',

      // 6. Document 2
      VaultItem()
        ..title = 'Rental Agreement (Demo)'
        ..itemType = 'Document'
        ..category = 'Contract'
        ..dueDate = now.add(const Duration(days: 60))
        ..isSample = true,

      // 7. Warranty Document
      VaultItem()
        ..title = 'iPhone Warranty (Demo)'
        ..itemType = 'Document'
        ..category = 'Warranty'
        ..dueDate = now.add(const Duration(days: 300))
        ..isSample = true,

      // 8. Health Document
      VaultItem()
        ..title = 'Health Insurance (Demo)'
        ..itemType = 'Document'
        ..category = 'Health'
        ..dueDate = now.add(const Duration(days: 120))
        ..isSample = true,
    ];

    for (var item in samples) {
      if (item.notes != null) {
        item.notes = await EncryptionService.encryptText(item.notes);
      }
    }

    await isar.writeTxn(() async {
      await isar.vaultItems.putAll(samples);
      
      // Mark as seen so we don't regenerate after logout/wipe
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.hasSeenDemo = true;
      await isar.appConfigs.put(config);
    });
  }

  /// Force reload all items from Isar — call after restore or erase
  Future<void> refreshVault() async {
    final user = FirebaseAuth.instance.currentUser;
    await _loadItems(user);
  }

  /// Schedule an auto-backup after a data mutation (debounced)
  void _autoBackup() {
    ref.read(autoSyncServiceProvider).scheduleBackup();
  }

  /// Migrates data from guest mode ('local_user') to a real account
  Future<void> migrateGuestData(String newOwnerId) async {
    final isar = ref.read(isarProvider);
    final guestItems = await isar.vaultItems.filter()
        .ownerIdEqualTo('local_user')
        .isSampleEqualTo(false)
        .findAll();
    
    // Also find samples to delete them
    final sampleItems = await isar.vaultItems.filter()
        .ownerIdEqualTo('local_user')
        .isSampleEqualTo(true)
        .findAll();
    
    if (guestItems.isNotEmpty || sampleItems.isNotEmpty) {
      await isar.writeTxn(() async {
        // 1. Migrate real items (Bulk update)
        for (var item in guestItems) {
          item.ownerId = newOwnerId;
          if (item.uuid.isEmpty) item.uuid = const Uuid().v4();
          item.lastModified = DateTime.now();
        }
        await isar.vaultItems.putAll(guestItems);

        // 2. Delete sample items
        if (sampleItems.isNotEmpty) {
          await isar.vaultItems.deleteAll(sampleItems.map((e) => e.id).toList());
        }
      });
      
      // Update state without full reload if possible
      state = [...state.where((e) => !e.isSample), ...guestItems];
      _autoBackup(); 
    }
  }

  Future<void> addItem(VaultItem item) async {
    // Normalize due date to midnight to avoid duplication issues
    if (item.dueDate != null) {
      item.dueDate = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
    }
    final isar = ref.read(isarProvider);
    final user = FirebaseAuth.instance.currentUser;
    
    // Set owner ID if it's still default
    if (item.ownerId == 'local_user' && user != null) {
      item.ownerId = user.uid;
    }

    // Ensure UUID exists for sync tracking
    if (item.uuid.isEmpty) {
      item.uuid = const Uuid().v4();
    }

    // Capture the original due day for recurring bills (fix 3.1)
    if (item.dueDate != null && item.recurrence != 'None') {
      item.originalDueDay = item.dueDate!.day;
    }

    // AUTO-CLEANUP: If adding a REAL item, delete all SAMPLE items first
    if (!item.isSample) {
      final samples = await isar.vaultItems.filter().isSampleEqualTo(true).findAll();
      if (samples.isNotEmpty) {
        await isar.writeTxn(() async {
          final idsToDelete = samples.map((s) => s.id).toList();
          await isar.vaultItems.deleteAll(idsToDelete);
        });
      }
    }

    // MULTI-FILE PERSISTENCE: Copy all files to internal storage
    List<String> finalPaths = [];
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    for (final path in item.attachedFiles) {
      if (!path.contains('app_flutter/attachments')) {
        final originalFile = File(path);
        if (await originalFile.exists()) {
          final fileName = 'doc_${DateTime.now().microsecondsSinceEpoch}_${p.basename(path)}';
          final newPath = '${attachmentsDir.path}/$fileName';
          await originalFile.copy(newPath);
          
          // CRITICAL: Encrypt the file on disk immediately after copy
          await EncryptionService.encryptFile(newPath);
          
          finalPaths.add(newPath);
        }
      } else {
        finalPaths.add(path); // Already in internal storage
      }
    }
    item.attachedFiles = finalPaths;

    item.notes = await EncryptionService.encryptText(item.notes);
    item.lastModified = DateTime.now();

    await isar.writeTxn(() async {
      await isar.vaultItems.put(item);
    });

    // Schedule notification for Bills & Documents
    if ((item.itemType == 'Bill' || item.itemType == 'Document') && item.dueDate != null && !item.isPaid) {
      final globalEnabled = ref.read(globalNotificationsProvider);
      if (globalEnabled) {
        await NotificationService.scheduleVaultReminder(
          id: item.id,
          title: item.title,
          dueDate: item.dueDate!,
          primaryDaysBefore: ref.read(alertDaysProvider),
          threeDayAlertEnabled: ref.read(threeDayAlertEnabledProvider),
          isDocument: item.itemType == 'Document',
        );
      }
    }

    // Optimization: Add or Update in state
    final index = state.indexWhere((e) => e.id == item.id && e.id != Isar.autoIncrement);
    if (index != -1) {
      final newState = [...state];
      newState[index] = item;
      state = newState;
    } else {
      state = [...state, item];
    }
    
    await _markAsDirty();
    _autoBackup();
  }

  Future<void> updatePaidStatus(int id, bool isPaid) async {
    final isar = ref.read(isarProvider);
    final item = await isar.vaultItems.get(id);
    if (item != null) {
      // UNDO LOGIC for Recurring Bills: If we are marking as UNPAID, and it was recurring, 
      // we need to find and delete the "next" instance that was auto-generated.
      if (!isPaid && item.recurrence != 'None' && item.dueDate != null && item.itemType == 'Bill') {
        final nextDate = DateHelper.calculateNextDueDate(item.dueDate!, item.recurrence);
        final nextUuid = 'next_${item.uuid}_${nextDate.millisecondsSinceEpoch}';
        
        final existingNext = await isar.vaultItems.filter()
            .ownerIdEqualTo(item.ownerId)
            .uuidEqualTo(nextUuid)
            .isPaidEqualTo(false)
            .findFirst();
        
        if (existingNext != null) {
          await deleteItem(existingNext.id);
        }
      }



      item.isPaid = isPaid;
      item.lastModified = DateTime.now();
      await isar.writeTxn(() async {
        await isar.vaultItems.put(item);
      });
      
      // Cancel notification if paid
      if (isPaid) {
        await NotificationService.cancelNotification(id);
      } else if ((item.itemType == 'Bill' || item.itemType == 'Document') && item.dueDate != null) {
        // Reschedule if unpaid again
        final globalEnabled = ref.read(globalNotificationsProvider);
        if (globalEnabled) {
          await NotificationService.scheduleVaultReminder(
            id: item.id,
            title: item.title,
            dueDate: item.dueDate!,
            primaryDaysBefore: ref.read(alertDaysProvider),
            threeDayAlertEnabled: ref.read(threeDayAlertEnabledProvider),
            isDocument: item.itemType == 'Document',
          );
        }
      }



      // AUTO-RENEW Logic: Create next instance for recurring bills
      if (isPaid && item.recurrence != 'None' && item.dueDate != null && item.itemType == 'Bill') {
        final nextDate = DateHelper.calculateNextDueDate(
          item.dueDate!,
          item.recurrence,
          targetDay: item.originalDueDay,
        );
        
        // Use composite UUID for rock-solid identification
        final nextUuid = 'next_${item.uuid}_${nextDate.millisecondsSinceEpoch}';
        final existingNext = await isar.vaultItems.filter()
            .ownerIdEqualTo(item.ownerId)
            .uuidEqualTo(nextUuid)
            .findFirst();

        if (existingNext == null) {
          final nextItem = VaultItem()
            ..ownerId = item.ownerId
            ..title = item.title
            ..category = item.category
            ..amount = item.amount
            ..itemType = item.itemType
            ..recurrence = item.recurrence
            ..directDebit = item.directDebit
            ..dueDate = nextDate
            ..isPaid = false
            ..uuid = nextUuid 
            ..originalDueDay = item.originalDueDay
            ..lastModified = DateTime.now();


          
          await isar.writeTxn(() async {
            await isar.vaultItems.put(nextItem);
          });

          // Schedule notification for the NEW bill
          final globalEnabled = ref.read(globalNotificationsProvider);
          if (globalEnabled) {
            await NotificationService.scheduleVaultReminder(
              id: nextItem.id,
              title: nextItem.title,
              dueDate: nextItem.dueDate!,
              primaryDaysBefore: ref.read(alertDaysProvider),
              threeDayAlertEnabled: ref.read(threeDayAlertEnabledProvider),
              isDocument: nextItem.itemType == 'Document',
            );
          }
        }
      }

      // Final single reload
      await _loadItems(FirebaseAuth.instance.currentUser);
      await _markAsDirty();
      _autoBackup();
    }
  }

  Future<void> toggleArchiveStatus(int id, bool archived) async {
    final isar = ref.read(isarProvider);
    final item = await isar.vaultItems.get(id);
    if (item != null) {
      item.isArchived = archived;
      item.lastModified = DateTime.now();
      await isar.writeTxn(() async {
        await isar.vaultItems.put(item);
      });
      await _loadItems(FirebaseAuth.instance.currentUser);
      await _markAsDirty();
      _autoBackup();
    }
  }

  Future<void> removeAttachment(int itemId, String filePath) async {
    final isar = ref.read(isarProvider);
    final item = await isar.vaultItems.get(itemId);
    if (item != null) {
      // 1. Get cloud ID before removal if it exists
      final index = item.attachedFiles.indexOf(filePath);
      String? cloudIdToDelete;
      if (index != -1 && index < item.cloudFileIds.length) {
        cloudIdToDelete = item.cloudFileIds[index];
      }

      // 2. Physical local delete
      final file = File(filePath);
      if (await file.exists()) await file.delete();
      
      // 3. Update local item lists
      final newFiles = List<String>.from(item.attachedFiles);
      newFiles.remove(filePath);
      item.attachedFiles = newFiles;

      if (cloudIdToDelete != null) {
        final newCloudIds = List<String>.from(item.cloudFileIds);
        newCloudIds.remove(cloudIdToDelete);
        item.cloudFileIds = newCloudIds;
        
        // 4. TRIGGER CLOUD CLEANUP
        _deleteFileFromDrive(cloudIdToDelete);
      }
      
      await isar.writeTxn(() async {
        await isar.vaultItems.put(item);
      });
      await _loadItems(FirebaseAuth.instance.currentUser);
      await _markAsDirty();
      _autoBackup();
    }
  }

  /// Helper to delete a file from Drive in the background
  Future<void> _deleteFileFromDrive(String fileId) async {
    try {
      final authService = ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token != null) {
        final driveService = DriveService(GoogleAuthClient({'Authorization': 'Bearer $token'}));
        await driveService.deleteFile(fileId);
        driveService.dispose();
        debugPrint('Cloud Cleanup: Deleted file $fileId from Drive.');
      }
    } catch (e) {
      debugPrint('Cloud Cleanup Error: $e');
    }
  }


  Future<void> deleteItem(int id) async {
    final isar = ref.read(isarProvider);
    final item = await isar.vaultItems.get(id);

    // Soft delete instead of physical delete
    if (item != null) {
      item.isDeleted = true;
      item.lastModified = DateTime.now();
      
      // Still delete physical files to save space
      for (final path in item.attachedFiles) {
        final file = File(path);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            debugPrint('Could not delete file: $e');
          }
        }
      }

      // TRIGGER CLOUD CLEANUP for all attachments
      for (final cloudId in item.cloudFileIds) {
        _deleteFileFromDrive(cloudId);
      }
      item.cloudFileIds = []; // Clear cloud IDs as they are being deleted


      await isar.writeTxn(() async {
        await isar.vaultItems.put(item);
      });
    }

    // Cancel notification
    await NotificationService.cancelNotification(id);

    await _loadItems(FirebaseAuth.instance.currentUser);
    await _markAsDirty();
    _autoBackup();
  }

  Future<void> clearAllData({bool alsoDeleteCloud = false}) async {
    debugPrint('VaultNotifier: clearAllData called! alsoDeleteCloud: $alsoDeleteCloud');
    final isar = ref.read(isarProvider);
    
    // 1. Get all items to clean up notifications
    final allItems = await isar.vaultItems.where().findAll();
    for (final item in allItems) {
      // Cancel scheduled notifications
      await NotificationService.cancelNotification(item.id);
    }

    // 2. Physical delete of the ENTIRE attachments directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      if (await attachmentsDir.exists()) {
        await attachmentsDir.delete(recursive: true);
        debugPrint('VaultNotifier: Attachments directory deleted.');
      }
    } catch (e) {
      debugPrint('VaultNotifier: Error deleting attachments: $e');
    }

    // 3. Delete Encryption Master Key from Secure Storage
    try {
      await EncryptionService.deleteKey();
      debugPrint('VaultNotifier: Encryption key wiped.');
    } catch (e) {
      debugPrint('VaultNotifier: Error wiping encryption key: $e');
    }

    // 4. Clear Isar database
    await isar.writeTxn(() async {
      await isar.vaultItems.clear();
      // Reset config during a full Factory Reset (alsoDeleteCloud)
      if (alsoDeleteCloud) {
        await isar.appConfigs.clear();
      }
    });

    // 5. Force state update
    state = [];
    
    // 6. Optional Cloud wipe (Factory Reset)
    if (alsoDeleteCloud && FirebaseAuth.instance.currentUser != null) {
      final authService = ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token != null) {
        final authHeaders = {'Authorization': 'Bearer $token'};
        final driveService = DriveService(GoogleAuthClient(authHeaders));
        try {
          await driveService.deleteBackup();
        } finally {
          driveService.dispose();
        }
      }
    }
  }
}

final vaultProvider = NotifierProvider<VaultNotifier, List<VaultItem>>(() {
  return VaultNotifier();
});
