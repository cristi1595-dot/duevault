import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_config.dart';
import '../services/migration_service.dart';
import '../models/vault_item.dart';
import '../repositories/vault_repository.dart';
import '../utils/logger.dart';
import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/auto_sync_service.dart';
import '../services/firebase_sync_service.dart';
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
  Completer<void>? _loadCompleter;
  int _currentLoadVersion = 0;

  @override
  List<VaultItem> build() {
    _repository = ref.watch(vaultRepositoryProvider);

    // Listen to auth state to trigger reload on login/logout
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      if (previous?.valueOrNull != next.valueOrNull) {
        _loadItems(next.valueOrNull);
      }
    });

    // Load items immediately on startup using current value if available
    final initialUser = ref.read(authStateProvider).valueOrNull;
    _loadItems(initialUser);

    return [];
  }

  Future<void> waitForLoad() async {
    if (_isLoading && _loadCompleter != null) {
      await _loadCompleter!.future;
    }
  }

  Future<void> _markAsDirty() async {
    final config = await _repository.getConfig();
    config.lastLocalChange = DateTime.now();
    await _repository.updateConfig(config);
  }

  Future<void> _loadItems(User? initialUser) async {
    if (_isLoading) return;
    _isLoading = true;
    _loadCompleter = Completer<void>();
    final loadVersion = ++_currentLoadVersion;

    try {
      // Stabilization Fix for Android 15/Pixel 9 kernel (userfaultfd)
      await Future.delayed(const Duration(milliseconds: 1000));

      // CRITICAL: Ensure we are not in the build phase
      await Future.microtask(() {});

      // Re-fetch current user to ensure we use the latest auth state
      final user = ref.read(authStateProvider).valueOrNull;

      final isar = ref.read(isarProvider);

      // Perform Migrations here (lazy-loaded)
      await MigrationService.runMigrations(isar);

      final ownerId = user?.uid ?? 'local_user';
      logger.i(
        'VaultNotifier: Loading items for owner: $ownerId (v$loadVersion)',
      );

      // Run Smart Auto-Archive (Backgrounded, non-blocking)
      unawaited(
        _repository
            .autoArchiveExpiredItems(ownerId)
            .then((_) => _markAsDirty())
            .catchError((e) {
              logger.e('VaultNotifier: Auto-archive error', error: e);
            }),
      );

      final freshItems = await _repository.getItems(ownerId);

      // Senior Debug: Also check if any guest items were left behind
      if (ownerId != 'local_user') {
        final guestCount = await isar
            .collection<VaultItem>()
            .filter()
            .ownerIdEqualTo('local_user')
            .isSampleEqualTo(false)
            .count();
        if (guestCount > 0) {
          logger.w(
            'VaultNotifier: Found $guestCount ORPHAN guest items while logged in as $ownerId!',
          );
        }
      }

      // ABORT if a newer load has started
      if (loadVersion != _currentLoadVersion) {
        logger.w(
          'VaultNotifier: Discarding load v$loadVersion (newer version exists)',
        );
        return;
      }
      logger.i(
        'VaultNotifier: Found ${freshItems.length} items in DB for $ownerId',
      );

      // Check if we need to add sample data (ONLY at the very first opening for guest mode)
      if (user == null) {
        final config = await _repository.getConfig();
        if (!config.hasSeenDemo && freshItems.isEmpty) {
          logger.i(
            'Vault: Fresh install detected. Generating sample data for Guest.',
          );
          await _repository.generateSampleData('local_user');
          final updatedItems = await _repository.getItems('local_user');
          state = updatedItems;
        }
      } else {
        // Real user logged in -> Ensure sample data from guest mode is gone
        await _repository.deleteSamplesForUser(user.uid);
        // Re-load items to show clean state
        state = await _repository.getItems(user.uid);

        // Also mark as having seen demo so it doesn't reappear if they log out
        final config = await _repository.getConfig();
        if (!config.hasSeenDemo) {
          config.hasSeenDemo = true;
          await _repository.updateConfig(config);
        }
      }

      // Final fetch to ensure state is perfectly in sync with DB changes above
      state = await _repository.getItems(ownerId);
    } catch (e) {
      logger.e('VaultNotifier: Error loading items', error: e);
    } finally {
      _isLoading = false;
      if (_loadCompleter?.isCompleted == false) {
        _loadCompleter?.complete();
      }
    }
  }

  Future<void> refreshVault() async {
    final user = ref.read(authStateProvider).valueOrNull;
    await _loadItems(user);
  }

  void _triggerSync() {
    ref.read(autoSyncServiceProvider).scheduleBackup();
    ref.read(firebaseSyncServiceProvider).sync();
  }

  Future<void> addItem(VaultItem item) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final alertDays = ref.read(alertDaysProvider);
    final threeDayAlert = ref.read(threeDayAlertEnabledProvider);
    final notificationsEnabled = ref.read(globalNotificationsProvider);

    // 1. Delete samples if adding real data
    if (!item.isSample) {
      await _repository.deleteSamplesForUser(user?.uid ?? 'local_user');
    }

    // 2. Assign Owner ID (CRITICAL FIX: Respect isGuest state strictly)
    final isGuest = ref.read(isGuestProvider);

    if (isGuest || user == null) {
      item.ownerId = 'local_user';
    } else {
      item.ownerId = user.uid;
    }

    // 3. Save via Repository
    await _repository.saveItem(
      item,
      alertDays: alertDays,
      threeDayAlertEnabled: threeDayAlert,
      notificationsEnabled: notificationsEnabled,
    );

    await _loadItems(user);
    await _markAsDirty();
    _triggerSync();
  }

  Future<void> updatePaidStatus(int id, bool isPaid) async {
    // 1. Immediate UI update
    state = state.map((item) {
      if (item.id == id) {
        // Create a new item with updated status for immediate UI feedback
        return VaultItem.fromMap(item.toMap())
          ..id = item.id
          ..isPaid = isPaid;
      }
      return item;
    }).toList();

    // 2. Persistent update
    await _repository.updatePaidStatus(id, isPaid);
    await _loadItems(ref.read(authStateProvider).valueOrNull);
    await _markAsDirty();
    _triggerSync();
  }

  Future<void> toggleArchiveStatus(int id, bool archived) async {
    // 1. Immediate UI update to satisfy Slidable/Dismissible requirements
    state = state.where((item) => item.id != id).toList();

    // 2. Persistent update
    final isar = ref.read(isarProvider);
    final item = await isar.collection<VaultItem>().get(id);
    if (item != null) {
      item.isArchived = archived;
      item.lastModified = DateTime.now();
      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().put(item);
      });
      await _loadItems(ref.read(authStateProvider).valueOrNull);
      await _markAsDirty();
      _triggerSync();
    }
  }

  Future<void> deleteItem(int id) async {
    // 1. Immediate UI update for Slidable/Dismissible
    state = state.where((item) => item.id != id).toList();

    // 2. Persistent update
    await _repository.softDeleteItem(id);
    await _loadItems(ref.read(authStateProvider).valueOrNull);
    await _markAsDirty();
    _triggerSync();
  }

  Future<void> migrateGuestData(String newUid) async {
    // 1. Move data in DB
    await _repository.migrateGuestData(newUid);

    // 2. Update UI immediately and cancel any pending background loads
    _currentLoadVersion++;
    final items = await _repository.getItems(newUid);
    logger.i(
      'Migration: UI updated with ${items.length} items for UID: $newUid (canceling stale loads)',
    );
    state = items;

    // 3. Mark for sync
    await _markAsDirty();
    _triggerSync();
  }

  Future<void> deleteGuestData() async {
    await _repository.deleteGuestData();
    await _loadItems(ref.read(authStateProvider).valueOrNull);
  }

  Future<void> removeAttachment(int itemId, String localPath) async {
    final isar = ref.read(isarProvider);
    final item = await isar.collection<VaultItem>().get(itemId);
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
          unawaited(_deleteFromCloud(cloudId));
        }
        item.cloudFileIds.removeAt(index);
      }

      // Update item lists
      item.attachedFiles.removeAt(index);
      item.lastModified = DateTime.now();

      // 3. Persist change
      await isar.writeTxn(() async {
        await isar.collection<VaultItem>().put(item);
      });

      await _loadItems(FirebaseAuth.instance.currentUser);
      await _markAsDirty();
      _triggerSync();

      logger.i('Attachment removed: $localPath');
    }
  }

  Future<void> _deleteFromCloud(String fileId) async {
    final authService = ref.read(authServiceProvider);
    final token = await authService.getFreshAccessToken();
    if (token != null) {
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

  Future<void> clearAllData({bool alsoDeleteCloud = false}) async {
    logger.w(
      'VaultNotifier: clearAllData called! alsoDeleteCloud: $alsoDeleteCloud',
    );
    final isar = ref.read(isarProvider);

    // 1. Notifications cleanup
    final allItems = await isar.collection<VaultItem>().where().findAll();
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
      await isar.collection<VaultItem>().clear();
      if (alsoDeleteCloud) {
        await isar.collection<AppConfig>().clear();
      }
    });

    // 2b. Recreate attachments directory to avoid path errors
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    state = [];

    // 3. Cloud wipe
    if (alsoDeleteCloud) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        // Wipe Firestore
        await ref.read(firebaseSyncServiceProvider).wipeData(user.uid);

        // Wipe Drive
        final authService = ref.read(authServiceProvider);
        final token = await authService.getFreshAccessToken();
        if (token != null) {
          final driveService = DriveService(
            GoogleAuthClient({'Authorization': 'Bearer $token'}),
          );
          try {
            await driveService.deleteBackup();
          } finally {
            driveService.dispose();
          }
        }
      }
    }
  }
}

final vaultProvider = NotifierProvider<VaultNotifier, List<VaultItem>>(() {
  return VaultNotifier();
});
