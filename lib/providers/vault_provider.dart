import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import '../services/migration_service.dart';
import '../models/vault_item.dart';
import '../repositories/vault_repository.dart';
import '../utils/logger.dart';
import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/auto_sync_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/vault_notification_helper.dart';
import '../services/vault_data_manager.dart';

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return VaultRepository(isar);
});

class VaultNotifier extends Notifier<List<VaultItem>> {
  late VaultRepository _repository;
  bool _isLoading = false;
  Completer<void>? _loadCompleter;
  int _currentLoadVersion = 0;
  static bool _firstLoadDone = false;

  @override
  List<VaultItem> build() {
    _repository = ref.watch(vaultRepositoryProvider);

    // Listen to auth state to trigger reload on login/logout and keep isGuestProvider in sync
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      if (previous?.valueOrNull != next.valueOrNull) {
        final user = next.valueOrNull;
        if (user != null) {
          ref.read(isGuestProvider.notifier).state = false;
        } else {
          ref.read(isGuestProvider.notifier).state = true;
        }
        _loadItems(user);
      }
    });

    // Load items immediately on startup using current value if available
    final initialUser = FirebaseAuth.instance.currentUser;
    if (initialUser != null) {
      // Ensure guest provider is set properly if already authenticated
      Future.microtask(() {
        ref.read(isGuestProvider.notifier).state = false;
      });
    }
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

  User? _lastLoadedUser;
  bool _lastLoadedUserSet = false;

  Future<void> _loadItems(User? initialUser) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_isLoading && _lastLoadedUserSet && _lastLoadedUser?.uid == user?.uid) {
      return;
    }
    _isLoading = true;
    _lastLoadedUser = user;
    _lastLoadedUserSet = true;
    _loadCompleter = Completer<void>();
    final loadVersion = ++_currentLoadVersion;

    try {
      // Stabilization Fix for Android 15/Pixel 9 kernel (userfaultfd)
      if (!_firstLoadDone) {
        await Future.delayed(const Duration(milliseconds: 1000));
        _firstLoadDone = true;
      }

      // CRITICAL: Ensure we are not in the build phase
      await Future.microtask(() {});

      // Re-fetch current user to ensure we use the latest auth state
      final currentUser = FirebaseAuth.instance.currentUser;

      final isar = ref.read(isarProvider);

      // Perform Migrations here (lazy-loaded)
      await MigrationService.runMigrations(isar);

      final ownerId = currentUser?.uid ?? 'local_user';
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

      // Ensure hasSeenDemo is marked true on first run to avoid demo checks elsewhere
      final config = await _repository.getConfig();
      if (!config.hasSeenDemo) {
        config.hasSeenDemo = true;
        await _repository.updateConfig(config);
      }

      // Final fetch to ensure state is perfectly in sync with DB changes above
      state = await _repository.getItems(ownerId);

      // Reschedule all notifications to guarantee system alarms are strictly synchronized with the database
      unawaited(rescheduleAllNotifications());
    } catch (e) {
      logger.e('VaultNotifier: Error loading items', error: e);
    } finally {
      if (loadVersion == _currentLoadVersion) {
        _isLoading = false;
        if (_loadCompleter?.isCompleted == false) {
          _loadCompleter?.complete();
        }
      }
    }
  }

  Future<void> refreshVault() async {
    final user = FirebaseAuth.instance.currentUser;
    await _loadItems(user);
  }

  void _triggerSync() {
    ref.read(autoSyncServiceProvider).scheduleBackup();
    ref.read(firebaseSyncServiceProvider).sync();
  }

  Future<void> addItem(VaultItem item) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final alertDays = ref.read(alertDaysProvider);
    final threeDayAlert = ref.read(threeDayAlertEnabledProvider);
    final notificationsEnabled = ref.read(globalNotificationsProvider);

    final finalReminderDays = ref.read(finalReminderDaysProvider);
    final finalReminderEnabled = ref.read(finalReminderEnabledProvider);
    
    final notificationTime = ref.read(notificationTimeProvider);

    // 1. Delete samples if adding real data
    if (!item.isSample) {
      await _repository.deleteSamplesForUser(firebaseUser?.uid ?? 'local_user');
    }

    // 2. Assign Owner ID
    if (firebaseUser == null) {
      item.ownerId = 'local_user';
    } else {
      item.ownerId = firebaseUser.uid;
    }

    String? token;
    if (firebaseUser != null) {
      try {
        final authService = ref.read(authServiceProvider);
        token = await authService.getFreshAccessToken();
      } catch (e) {
        logger.w('Failed to get fresh access token for deletion cleanup: $e');
      }
    }

    // 3. Save via Repository
    await _repository.saveItem(
      item,
      alertDays: alertDays,
      threeDayAlertEnabled: threeDayAlert,
      finalReminderDays: finalReminderDays,
      finalReminderEnabled: finalReminderEnabled,
      notificationHour: notificationTime.hour,
      notificationMinute: notificationTime.minute,
      notificationsEnabled: notificationsEnabled,
      userAccessToken: token,
    );

    await _markAsDirty();
    // Wait for any in-progress background load to finish, then force a fresh reload
    await waitForLoad();
    _isLoading = false;
    await _loadItems(firebaseUser);
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
    await _markAsDirty();
    await _loadItems(FirebaseAuth.instance.currentUser);
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
      await _markAsDirty();
      await _loadItems(FirebaseAuth.instance.currentUser);
      _triggerSync();
    }
  }

  Future<void> rescheduleAllNotifications() async {
    final alertDays = ref.read(alertDaysProvider);
    final threeDayAlert = ref.read(threeDayAlertEnabledProvider);
    final finalReminderDays = ref.read(finalReminderDaysProvider);
    final finalReminderEnabled = ref.read(finalReminderEnabledProvider);
    final notificationTime = ref.read(notificationTimeProvider);
    final notificationsEnabled = ref.read(globalNotificationsProvider);

    await VaultNotificationHelper.rescheduleAll(
      items: state,
      alertDays: alertDays,
      threeDayAlert: threeDayAlert,
      finalReminderDays: finalReminderDays,
      finalReminderEnabled: finalReminderEnabled,
      notificationTime: notificationTime,
      notificationsEnabled: notificationsEnabled,
    );
  }

  Future<void> deleteItem(int id) async {
    // 1. Immediate UI update for Slidable/Dismissible
    state = state.where((item) => item.id != id).toList();

    // 2. Persistent update
    await _repository.softDeleteItem(id);
    await _markAsDirty();
    await _loadItems(FirebaseAuth.instance.currentUser);
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
    await _loadItems(FirebaseAuth.instance.currentUser);
  }

  Future<void> removeAttachment(int itemId, String localPath) async {
    final isar = ref.read(isarProvider);
    final authService = ref.read(authServiceProvider);
    final token = await authService.getFreshAccessToken();

    final removed = await VaultDataManager.removeAttachment(
      isar: isar,
      itemId: itemId,
      localPath: localPath,
      userAccessToken: token,
    );

    if (removed) {
      final fileName = p.basename(localPath.replaceAll('\\', '/'));
      state = state.map((item) {
        if (item.id == itemId) {
          final updatedFiles = List<String>.from(item.attachedFiles);
          final idx = updatedFiles.indexWhere((path) => p.basename(path.replaceAll('\\', '/')) == fileName);
          
          final updatedCloudIds = List<String>.from(item.cloudFileIds);
          final updatedChecksums = List<String>.from(item.cloudFileChecksums);
          
          if (idx != -1) {
            updatedFiles.removeAt(idx);
            if (idx < updatedCloudIds.length) {
              updatedCloudIds.removeAt(idx);
            }
            if (idx < updatedChecksums.length) {
              updatedChecksums.removeAt(idx);
            }
          }

          final newItem = VaultItem.fromMap(item.toMap())
            ..id = item.id
            ..attachedFiles = updatedFiles
            ..cloudFileIds = updatedCloudIds
            ..cloudFileChecksums = updatedChecksums;
          return newItem;
        }
        return item;
      }).toList();

      await _markAsDirty();
      _triggerSync();
    }
  }

  Future<void> clearLocalCache() async {
    await VaultDataManager.clearLocalCache();
  }

  Future<void> clearAllData({bool alsoDeleteCloud = false}) async {
    final isar = ref.read(isarProvider);
    final user = FirebaseAuth.instance.currentUser;

    String? token;
    if (alsoDeleteCloud && user != null) {
      final authService = ref.read(authServiceProvider);
      token = await authService.getFreshAccessToken();
    }

    await VaultDataManager.clearAllData(
      isar: isar,
      alsoDeleteCloud: alsoDeleteCloud,
      currentUser: user,
      userAccessToken: token,
      firebaseSyncService: ref.read(firebaseSyncServiceProvider),
    );

    state = [];
  }
}

final vaultProvider = NotifierProvider<VaultNotifier, List<VaultItem>>(() {
  return VaultNotifier();
});
