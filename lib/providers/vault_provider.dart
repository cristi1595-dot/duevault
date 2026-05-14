import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault_item.dart';
import '../models/app_config.dart';
import '../repositories/vault_repository.dart';
import '../utils/logger.dart';
import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/auto_sync_service.dart';
import '../services/notification_service.dart';
import '../services/encryption_service.dart';
import '../services/drive_service.dart';


final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return VaultRepository(isar);
});


class VaultNotifier extends Notifier<List<VaultItem>> {
  late VaultRepository _repository;
  bool _isLoading = false;

  @override
  List<VaultItem> build() {
    _repository = ref.watch(vaultRepositoryProvider);
    
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
  Future<void> _autoArchiveExpiredItems(String ownerId) async {
    final isar = ref.read(isarProvider);
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
      logger.i('VaultNotifier: Auto-archiving ${toArchive.length} expired items.');
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
    final config = await _repository.getConfig();
    config.lastLocalChange = DateTime.now();
    await _repository.updateConfig(config);
  }

  Future<void> _loadItems(User? user) async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      final ownerId = user?.uid ?? 'local_user';

      // Run Smart Auto-Archive before setting state
      await _autoArchiveExpiredItems(ownerId);
      
      final freshItems = await _repository.getItems(ownerId);

      // Check if we need to add sample data (ONLY at the very first opening for guest mode)
      if (user == null) {
        final config = await _repository.getConfig();
        if (!config.hasSeenDemo && freshItems.isEmpty) {
          logger.i('VaultNotifier: Generating demo data.');
          await _generateSampleData();
          state = await _repository.getItems('local_user');
          return;
        }
      }
      
      state = freshItems;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _generateSampleData() async {
    final now = DateTime.now();
    final samples = [
      VaultItem()..title = 'Electricity Bill (Demo)'..itemType = 'Bill'..category = 'Housing'..amount = 45.0..dueDate = now.subtract(const Duration(days: 2))..isPaid = false..isSample = true..ownerId = 'local_user',
      VaultItem()..title = 'Internet Subscription (Demo)'..itemType = 'Bill'..category = 'Subscriptions'..amount = 29.99..dueDate = now.add(const Duration(days: 5))..isPaid = false..isSample = true..ownerId = 'local_user',
      VaultItem()..title = 'Visa Credit Card (Demo)'..itemType = 'Bill'..category = 'Loans'..amount = 150.0..dueDate = now.add(const Duration(days: 10))..isPaid = false..isSample = true..ownerId = 'local_user',
      VaultItem()..title = 'Car Insurance (Demo)'..itemType = 'Bill'..category = 'Auto'..amount = 85.50..dueDate = now.add(const Duration(days: 15))..isPaid = false..isSample = true..ownerId = 'local_user',
      VaultItem()..title = 'Identity Card (Demo)'..itemType = 'Document'..category = 'Identity'..dueDate = now.add(const Duration(days: 450))..isSample = true..ownerId = 'local_user',
      VaultItem()..title = 'Rental Agreement (Demo)'..itemType = 'Document'..category = 'Legal'..dueDate = now.add(const Duration(days: 60))..isSample = true..ownerId = 'local_user',
    ];

    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.vaultItems.putAll(samples);
    });

    final config = await _repository.getConfig();
    config.hasSeenDemo = true;
    await _repository.updateConfig(config);
  }

  Future<void> refreshVault() async {
    final user = FirebaseAuth.instance.currentUser;
    await _loadItems(user);
  }

  void _autoBackup() {
    ref.read(autoSyncServiceProvider).scheduleBackup();
  }

  Future<void> addItem(VaultItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    final alertDays = ref.read(alertDaysProvider);
    final threeDayAlert = ref.read(threeDayAlertEnabledProvider);
    final notificationsEnabled = ref.read(globalNotificationsProvider);

    // 1. Delete samples if adding real data
    if (!item.isSample) {
      final isar = ref.read(isarProvider);
      final samples = await isar.vaultItems.filter().isSampleEqualTo(true).findAll();
      if (samples.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.vaultItems.deleteAll(samples.map((s) => s.id).toList());
        });
      }
    }

    // 2. Assign Owner ID (CRITICAL FIX: Was missing, items were disappearing)
    item.ownerId = user?.uid ?? 'local_user';

    // 3. Save via Repository
    await _repository.saveItem(
      item,
      alertDays: alertDays,
      threeDayAlertEnabled: threeDayAlert,
      notificationsEnabled: notificationsEnabled,
    );

    await _loadItems(user);
    await _markAsDirty();
    _autoBackup();
  }

  Future<void> updatePaidStatus(int id, bool isPaid) async {
    await _repository.updatePaidStatus(id, isPaid);
    await _loadItems(FirebaseAuth.instance.currentUser);
    await _markAsDirty();
    _autoBackup();
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

  Future<void> deleteItem(int id) async {
    await _repository.softDeleteItem(id);
    await _loadItems(FirebaseAuth.instance.currentUser);
    await _markAsDirty();
    _autoBackup();
  }

  Future<void> migrateGuestData(String newUid) async {
    await _repository.migrateGuestData(newUid);
    await _loadItems(FirebaseAuth.instance.currentUser);
    await _markAsDirty();
    _autoBackup();
  }


  Future<void> removeAttachment(int itemId, String localPath) async {
    final isar = ref.read(isarProvider);
    final item = await isar.vaultItems.get(itemId);
    if (item == null) return;

    // 1. Remove from local file system
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      logger.e('Error deleting local file: $localPath', error: e);
    }

    // 2. Identify and remove from cloud (Drive)
    final index = item.attachedFiles.indexOf(localPath);
    if (index != -1) {
      if (index < item.cloudFileIds.length) {
        final cloudId = item.cloudFileIds[index];
        if (cloudId.isNotEmpty) {
          // Trigger async cloud deletion
          _deleteFromCloud(cloudId);
        }
        item.cloudFileIds.removeAt(index);
      }
      
      // Update item lists
      item.attachedFiles.removeAt(index);
      item.lastModified = DateTime.now();
      
      // 3. Persist change
      await isar.writeTxn(() async {
        await isar.vaultItems.put(item);
      });

      await _loadItems(FirebaseAuth.instance.currentUser);
      await _markAsDirty();
      _autoBackup();
      
      logger.i('Attachment removed: $localPath');
    }
  }

  Future<void> _deleteFromCloud(String fileId) async {
    final authService = ref.read(authServiceProvider);
    final token = await authService.getFreshAccessToken();
    if (token != null) {
      final driveService = DriveService(GoogleAuthClient({'Authorization': 'Bearer $token'}));
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


  Future<void> clearAllData({bool alsoDeleteCloud = false}) async {
    logger.w('VaultNotifier: clearAllData called! alsoDeleteCloud: $alsoDeleteCloud');
    final isar = ref.read(isarProvider);
    
    // 1. Notifications cleanup
    final allItems = await isar.vaultItems.where().findAll();
    for (final item in allItems) {
      await NotificationService.cancelNotification(item.id);
    }

    // 2. Local wipe
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (await attachmentsDir.exists()) {
      await attachmentsDir.delete(recursive: true);
    }

    await EncryptionService.deleteKey();

    await isar.writeTxn(() async {
      await isar.vaultItems.clear();
      if (alsoDeleteCloud) {
        await isar.appConfigs.clear();
      }
    });

    // 2b. Recreate attachments directory to avoid path errors
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    state = [];
    
    // 3. Cloud wipe
    if (alsoDeleteCloud && FirebaseAuth.instance.currentUser != null) {
      final authService = ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token != null) {
        final driveService = DriveService(GoogleAuthClient({'Authorization': 'Bearer $token'}));
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

