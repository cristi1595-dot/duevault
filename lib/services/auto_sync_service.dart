import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/sync_provider.dart';
import '../models/vault_item.dart';
import '../models/app_config.dart';
import '../utils/logger.dart';
import 'drive_service.dart';
import 'sync_conflict_resolver.dart';
import 'attachment_sync_manager.dart';

/// Orchestrates the automatic backup and synchronization processes.
class AutoSyncService {
  final Ref _ref;
  Timer? _debounceTimer;
  bool _isSyncing = false;

  AutoSyncService(this._ref);

  bool get _isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Debounced auto-backup — waits 2s after last change.
  void scheduleBackup({bool immediate = false}) {
    if (!_isSignedIn) return;

    final autoSyncEnabled = _ref.read(autoSyncProvider);
    if (!autoSyncEnabled) return;

    final isProcessing = _ref.read(isProcessingAuthSyncProvider);
    if (isProcessing) {
      logger.i('AutoSyncService: Backup scheduled but skipped (auth sync active).');
      return;
    }

    _debounceTimer?.cancel();

    if (immediate) {
      _performBackup();
    } else {
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        _performBackup();
      });
    }
  }

  /// Perform the actual backup in the background
  Future<void> _performBackup() async {
    if (_isSyncing || !_isSignedIn) return;

    final isProcessing = _ref.read(isProcessingAuthSyncProvider);
    if (isProcessing) return;

    final autoSyncEnabled = _ref.read(autoSyncProvider);
    final wifiOnly = _ref.read(wifiOnlyProvider);
    if (!autoSyncEnabled) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    final canSync = connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn) ||
        (connectivityResult.contains(ConnectivityResult.mobile) && !wifiOnly);

    if (!canSync) {
      logger.w('Auto-backup skipped: Connectivity restrictions');
      return;
    }

    _isSyncing = true;

    try {
      _ref.read(syncProvider.notifier).setSyncing();
      final authService = _ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();

      if (token != null) {
        final authHeaders = {'Authorization': 'Bearer $token'};
        final driveService = DriveService(GoogleAuthClient(authHeaders));
        try {
          final isar = _ref.read(isarProvider);
          final user = FirebaseAuth.instance.currentUser!;
          
          // 1. Sync Attachments
          final attachmentManager = AttachmentSyncManager(localIsar: isar, user: user);
          await attachmentManager.syncAttachments(driveService);

          // 2. Backup Database
          final success = await driveService.backupDatabase();
          if (success) {
            final dir = await getApplicationDocumentsDirectory();
            final dbFile = File('${dir.path}/default.isar');
            final checksum = await driveService.getFileChecksum(dbFile);

            await driveService.uploadMetadata({
              'last_modified': DateTime.now().toIso8601String(),
              'checksum': checksum,
              'device_name': Platform.isAndroid ? 'Android' : 'iOS',
            });

            _ref.read(syncProvider.notifier).setSuccess();

            await isar.writeTxn(() async {
              final itemsToMark = await isar.collection<VaultItem>()
                  .filter().wasSyncedEqualTo(false).findAll();
              for (var item in itemsToMark) {
                item.wasSynced = true;
              }
              await isar.collection<VaultItem>().putAll(itemsToMark);

              final config = await isar.collection<AppConfig>().get(0) ?? AppConfig();
              config.lastCloudSync = DateTime.now();
              config.localDatabaseChecksum = checksum;
              await isar.appConfigs.put(config);
            });

            Timer(const Duration(seconds: 3), () {
              _ref.read(syncProvider.notifier).resetStatus();
            });
          } else {
            _ref.read(syncProvider.notifier).setError('Backup failed');
          }
        } finally {
          driveService.dispose();
        }
      } else {
        _ref.read(syncProvider.notifier).setError('No Drive Access');
      }
    } catch (e, stack) {
      logger.e('Auto-backup error', error: e, stackTrace: stack);
      _ref.read(syncProvider.notifier).setError(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Merges guest data or restores account data after login
  Future<String> syncAfterLogin() async {
    if (!_isSignedIn) return 'none';

    try {
      final authService = _ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token == null) return 'none';

      final authHeaders = {'Authorization': 'Bearer $token'};
      final driveService = DriveService(GoogleAuthClient(authHeaders));

      try {
        final cloudChecksum = await driveService.getBackupChecksum();

        if (cloudChecksum == null) {
          final localItems = _ref.read(vaultProvider);
          if (localItems.any((item) => !item.isSample)) {
            final success = await driveService.backupDatabase();
            if (success) return 'uploaded';
          }
          return 'empty';
        }

        final isar = _ref.read(isarProvider);
        final user = FirebaseAuth.instance.currentUser!;
        final resolver = SyncConflictResolver(localIsar: isar, user: user);
        
        final results = await resolver.mergeWithCloud(driveService, isLoginSync: true);
        if (results['localModified'] == true) {
          final attachmentManager = AttachmentSyncManager(localIsar: isar, user: user);
          await attachmentManager.syncAttachments(driveService);
          return 'restored';
        }
      } finally {
        driveService.dispose();
      }
    } catch (e, stack) {
      logger.e('Sync after login error', error: e, stackTrace: stack);
    }
    return 'none';
  }

  /// Checks if there are local changes not synced to cloud or if cloud has newer data.
  Future<void> syncOnStartup() async {
    if (!_isSignedIn) return;

    try {
      final isar = _ref.read(isarProvider);
      final config = await isar.collection<AppConfig>().get(0) ?? AppConfig();

      final now = DateTime.now();
      if (config.lastSyncCheck != null &&
          now.difference(config.lastSyncCheck!).inMinutes < 15) {
        return;
      }

      final authService = _ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token == null) return;

      final authHeaders = {'Authorization': 'Bearer $token'};
      final driveService = DriveService(GoogleAuthClient(authHeaders));

      try {
        final cloudChecksum = await driveService.getBackupChecksum();
        final dir = await getApplicationDocumentsDirectory();
        final dbFile = File('${dir.path}/default.isar');
        final localChecksum = await driveService.getFileChecksum(dbFile);

        await isar.writeTxn(() async {
          final currentConfig = await isar.appConfigs.get(0) ?? AppConfig();
          currentConfig.lastSyncCheck = now;
          currentConfig.localDatabaseChecksum = localChecksum;
          await isar.appConfigs.put(currentConfig);
        });

        if (cloudChecksum == null) {
          if (config.lastLocalChange != null) {
            await _performBackup();
          }
          return;
        }

        if (cloudChecksum == localChecksum) return;

        final cloudMetadata = await driveService.getCloudMetadata();
        final localTime = config.lastLocalChange;

        if (cloudMetadata != null) {
          final cloudTimeString = cloudMetadata['last_modified'] as String?;
          final cloudTime = cloudTimeString != null ? DateTime.tryParse(cloudTimeString) : null;

          if (cloudTime != null) {
            if (localTime == null || cloudTime.isAfter(localTime.add(const Duration(seconds: 5)))) {
              final user = FirebaseAuth.instance.currentUser!;
              final resolver = SyncConflictResolver(localIsar: isar, user: user);
              final results = await resolver.mergeWithCloud(driveService);
              
              if (results['localModified'] == true) {
                await _ref.read(vaultProvider.notifier).refreshVault();
                final attachmentManager = AttachmentSyncManager(localIsar: isar, user: user);
                await attachmentManager.syncAttachments(driveService);
              }

              if (results['cloudModified'] == true) {
                scheduleBackup();
              }
              
              await resolver.updateSyncMarkers();
            } else if (localTime.isAfter(cloudTime.add(const Duration(seconds: 5)))) {
              await _performBackup();
            }
          }
        }
      } finally {
        driveService.dispose();
      }
    } catch (e, stack) {
      logger.e('AutoSyncService: Error during syncOnStartup', error: e, stackTrace: stack);
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

final autoSyncServiceProvider = Provider<AutoSyncService>((ref) {
  final service = AutoSyncService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
