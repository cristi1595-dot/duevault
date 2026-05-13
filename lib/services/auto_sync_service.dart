import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../models/vault_item.dart';
import 'drive_service.dart';
import '../providers/sync_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/app_config.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';


/// Handles automatic backup to Google Drive after data changes,
/// and automatic restore when the user signs in.
class AutoSyncService {
  final Ref _ref;
  Timer? _debounceTimer;
  bool _isSyncing = false;

  AutoSyncService(this._ref);

  /// Check if user is signed in with Google (not guest)
  bool get _isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Debounced auto-backup — waits 5s after last change to avoid spamming Drive
  void scheduleBackup() {
    if (!_isSignedIn) return;

    // Check if auto-sync is enabled by user
    final autoSyncEnabled = _ref.read(autoSyncProvider);
    if (!autoSyncEnabled) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      _performBackup();
    });
  }

  /// Perform the actual backup in the background
  Future<void> _performBackup() async {
    if (_isSyncing || !_isSignedIn) return;

    // 1. Check Preferences
    final autoSyncEnabled = _ref.read(autoSyncProvider);
    final wifiOnly = _ref.read(wifiOnlyProvider);
    if (!autoSyncEnabled) return;

    // 2. Check Connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    bool canSync = false;

    if (connectivityResult.contains(ConnectivityResult.wifi) || 
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.vpn)) {
      canSync = true;
    } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
      canSync = !wifiOnly; // Only sync on mobile if wifiOnly is OFF
    }

    if (!canSync) {
      debugPrint('Auto-backup skipped: Connectivity restrictions or no internet');
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
          // 1. Sync Attachments first (ensure IDs are in DB before DB backup)
          await _syncAttachments(driveService);

          final success = await driveService.backupDatabase();
          if (success) {
            // Calculate checksum for metadata
            final dir = await getApplicationDocumentsDirectory();
            final dbFile = File('${dir.path}/default.isar');
            final checksum = await driveService.getFileChecksum(dbFile);

            // Upload sync metadata
            await driveService.uploadMetadata({
              'last_modified': DateTime.now().toIso8601String(),
              'checksum': checksum,
              'device_name': Platform.isAndroid ? 'Android' : 'iOS',
            });


            _ref.read(syncProvider.notifier).setSuccess();
            
            // Mark all local items as synced
            final isar = _ref.read(isarProvider);
            final itemsToMark = await isar.vaultItems.where().findAll();
            await isar.writeTxn(() async {
              for (var item in itemsToMark) {
                if (!item.wasSynced) {
                  item.wasSynced = true;
                  await isar.vaultItems.put(item);
                }
              }
            });


            
            // Update Sync Timestamp in Config

            await isar.writeTxn(() async {
              final config = await isar.collection<AppConfig>().get(0) ?? AppConfig();
              config.lastCloudSync = DateTime.now();
              await isar.collection<AppConfig>().put(config);
            });

            // Reset to idle after 3 seconds
            Timer(const Duration(seconds: 3), () {
              _ref.read(syncProvider.notifier).resetStatus();
            });
          } else {
            _ref.read(syncProvider.notifier).setError('Backup failed');
          }
          debugPrint('Auto-backup ${success ? 'successful' : 'failed'}');
        } finally {
          driveService.dispose();
        }
      } else {
        _ref.read(syncProvider.notifier).setError('No Drive Access');
      }
    } catch (e) {
      debugPrint('Auto-backup error: $e');
      _ref.read(syncProvider.notifier).setError(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Merges guest data or restores account data after login
  /// Returns a string describing the result ('restored', 'uploaded', 'none')
  Future<String> syncAfterLogin() async {
    if (!_isSignedIn) return 'none';

    try {
      final authService = _ref.read(authServiceProvider);
      // Force refresh to ensure we have the new scopes (fix C2)
      final token = await authService.getFreshAccessToken();
      if (token == null) {
        debugPrint('AutoSyncService: Failed to get token during syncAfterLogin');
        return 'none';
      }

      final authHeaders = {'Authorization': 'Bearer $token'};
      final driveService = DriveService(GoogleAuthClient(authHeaders));

      try {
        // Use Smart Merge instead of blind restore
        final success = await _mergeWithCloud(driveService);
        if (success) {
          await _syncAttachments(driveService);
          return 'restored';
        }

        // 3. If NO backup exists but we have local data, upload it now
        final localItems = _ref.read(vaultProvider);
        final hasRealLocalData = localItems.any((item) => !item.isSample);
        if (hasRealLocalData) {
          debugPrint('AutoSyncService: No cloud backup found, uploading local data...');
          final success = await driveService.backupDatabase();
          if (success) return 'uploaded';
        }
      } finally {
        driveService.dispose();
      }
    } catch (e) {
      debugPrint('Sync after login error: $e');
    }
    return 'none';
  }

  /// Checks if there are local changes not synced to cloud or if cloud has newer data.
  Future<void> syncOnStartup() async {
    if (!_isSignedIn) return;

    try {
      final isar = _ref.read(isarProvider);
      final config = await isar.collection<AppConfig>().get(0) ?? AppConfig();
      
      final authService = _ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token == null) return;

      final authHeaders = {'Authorization': 'Bearer $token'};
      final driveService = DriveService(GoogleAuthClient(authHeaders));

      try {
        final cloudMetadata = await driveService.getCloudMetadata();
        final localTime = config.lastLocalChange;

        if (cloudMetadata != null) {
          final cloudTimeString = cloudMetadata['last_modified'] as String?;
          final cloudChecksum = cloudMetadata['checksum'] as String?;
          final cloudTime = cloudTimeString != null ? DateTime.tryParse(cloudTimeString) : null;

          // Calculate local checksum for comparison
          final dir = await getApplicationDocumentsDirectory();
          final localChecksum = await driveService.getFileChecksum(File('${dir.path}/default.isar'));

          if (cloudTime != null) {
            // ONLY SYNC IF CHECKSUM IS DIFFERENT
            if (cloudChecksum != localChecksum) {
              // CLOUD IS NEWER OR POSSIBLY DIFFERENT -> MERGE
              if (localTime == null || cloudTime.isAfter(localTime.add(const Duration(seconds: 5)))) {
                debugPrint('AutoSyncService: Cloud data is different and newer. Triggering smart merge...');
                await _mergeWithCloud(driveService);
                await _syncAttachments(driveService);
              } 
              // LOCAL IS NEWER -> BACKUP
              else if (localTime.isAfter(cloudTime.add(const Duration(seconds: 5)))) {
                debugPrint('AutoSyncService: Local data is newer. Triggering background backup...');
                await _performBackup();
              }
            } else {
              debugPrint('AutoSyncService: Cloud data is identical (checksum match). Skipping sync.');
            }
          } 
          else if (localTime != null) {
            // NO CLOUD DATA -> BACKUP
            debugPrint('AutoSyncService: No cloud backup found. Uploading initial local data...');
            await _performBackup();
          }
        } else if (localTime != null) {
          // NO CLOUD DATA -> BACKUP
          debugPrint('AutoSyncService: No cloud backup found. Uploading initial local data...');
          await _performBackup();
        }
      } finally {
        driveService.dispose();
      }
    } catch (e) {
      debugPrint('AutoSyncService: Error during syncOnStartup: $e');
    }
  }

  /// Advanced Smart Merge: Resolves multi-device conflicts using UUIDs and timestamps.
  /// Does NOT overwrite the whole DB.
  Future<bool> _mergeWithCloud(DriveService driveService) async {
    final localIsar = _ref.read(isarProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // 1. Download cloud data to a temp isolate
    final cloudIsar = await driveService.downloadAndOpenDatabase('merge_${DateTime.now().millisecondsSinceEpoch}');
    if (cloudIsar == null) return false;

    try {
      final cloudItems = await cloudIsar.vaultItems.filter().ownerIdEqualTo(user.uid).findAll();
      final localItems = await localIsar.vaultItems.filter().ownerIdEqualTo(user.uid).findAll();

      bool localModified = false;
      bool cloudModified = false;

      await localIsar.writeTxn(() async {
        for (var cloudItem in cloudItems) {
          // Match by UUID for rock-solid identification
          final localItem = localItems.where((i) => i.uuid == cloudItem.uuid).firstOrNull;

          if (localItem == null) {
            // If localItem is null and we don't have a record of it, it's new from cloud.
            if (cloudItem.uuid.isEmpty) {
              cloudItem.uuid = const Uuid().v4();
            }
            cloudItem.wasSynced = true; // Mark as synced
            await localIsar.vaultItems.put(cloudItem..id = Isar.autoIncrement);
            localModified = true;
          } else {
            // Item exists in both -> Resolve by lastModified
            if (cloudItem.lastModified.isAfter(localItem.lastModified.add(const Duration(seconds: 1)))) {
              // Cloud version is NEWER -> Update local
              cloudItem.id = localItem.id; // Keep local database ID
              cloudItem.wasSynced = true; // Mark as synced
              await localIsar.vaultItems.put(cloudItem);
              localModified = true;

            } else if (localItem.lastModified.isAfter(cloudItem.lastModified.add(const Duration(seconds: 1)))) {
              // Local version is NEWER -> Cloud version is stale
              cloudModified = true;
            }
            
            // SPECIAL CASE: Deletion sync
            // If cloud item is marked as deleted but local is not
            if (cloudItem.isDeleted && !localItem.isDeleted) {
              localItem.isDeleted = true;
              localItem.lastModified = cloudItem.lastModified;
              await localIsar.vaultItems.put(localItem);
              localModified = true;
            }
          }
        }
      });


      // 2. Check for local items that don't exist in cloud -> They need to be uploaded
      // OR if they were previously synced, it means they were deleted on another device.
      for (var localItem in localItems) {
        final existsInCloud = cloudItems.any((i) => i.uuid == localItem.uuid);
        if (!existsInCloud) {
          if (localItem.wasSynced) {
            // Item was in cloud before, but is gone now -> Deleted from another device
            debugPrint('AutoSyncService: Local item "${localItem.title}" was deleted from cloud. Removing locally...');
            await localIsar.writeTxn(() async {
              // We do a hard delete or soft delete here? 
              // User request: "trebuie eliminat și local"
              await localIsar.vaultItems.delete(localItem.id);
            });
            localModified = true;
          } else {
            // New local item that hasn't reached the cloud yet
            cloudModified = true;
          }
        }
      }


      if (localModified) {
        debugPrint('AutoSyncService: Merge complete. Local UI refreshed.');
        await _ref.read(vaultProvider.notifier).refreshVault();
      }

      if (cloudModified) {
        debugPrint('AutoSyncService: Merge complete. Local changes detected, scheduling backup...');
        scheduleBackup();
      }

      // 3. Update Sync Marker to prevent loops
      await localIsar.writeTxn(() async {
        final config = await localIsar.appConfigs.get(0) ?? AppConfig();
        config.lastCloudSync = DateTime.now();
        // Set local change to NOW so it matches or exceeds cloud time
        config.lastLocalChange = DateTime.now();
        await localIsar.appConfigs.put(config);
      });

      return true;
    } catch (e) {
      debugPrint('AutoSyncService: Merge error: $e');
      return false;
    } finally {
      await cloudIsar.close();
    }
  }

  /// Synchronizes local attachments with Google Drive
  Future<void> _syncAttachments(DriveService driveService) async {
    final isar = _ref.read(isarProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final items = await isar.vaultItems.filter().ownerIdEqualTo(user.uid).findAll();

    for (var item in items) {
      bool modified = false;

      // 1. CLEANUP: Delete local files that are no longer in Cloud
      // If we have local files but cloudFileIds is shorter or empty, we need to reconcile
      if (item.attachedFiles.length > item.cloudFileIds.length) {
        final newPaths = List<String>.from(item.attachedFiles);
        // We remove items from the end or based on missing cloud IDs
        // To be safe and simple: if cloud has N items, we should only have the first N local items
        for (int i = item.attachedFiles.length - 1; i >= item.cloudFileIds.length; i--) {
          final localPath = item.attachedFiles[i];
          final file = File(localPath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('AutoSyncService: Deleted local attachment ${i + 1} for "${item.title}" (missing from cloud)');
          }
          newPaths.removeAt(i);
          modified = true;
        }
        item.attachedFiles = newPaths;
      }

      // 2. UPLOAD missing files to Cloud
      for (int i = 0; i < item.attachedFiles.length; i++) {
        // If this local file doesn't have a corresponding Cloud ID yet
        if (i >= item.cloudFileIds.length) {
          final file = File(item.attachedFiles[i]);
          if (await file.exists()) {
            debugPrint('AutoSyncService: Uploading attachment ${i + 1} for "${item.title}"...');
            final cloudId = await driveService.uploadAttachment(file, 'attach_${item.uuid}_$i');
            if (cloudId != null) {
              final newIds = List<String>.from(item.cloudFileIds);
              newIds.add(cloudId);
              item.cloudFileIds = newIds;
              modified = true;
            }
          }
        }
      }

      // 3. DOWNLOAD missing files from Cloud
      if (item.cloudFileIds.length > item.attachedFiles.length) {
        final appDir = await getApplicationDocumentsDirectory();
        final attachmentsDir = Directory('${appDir.path}/attachments');
        if (!await attachmentsDir.exists()) await attachmentsDir.create(recursive: true);

        for (int i = item.attachedFiles.length; i < item.cloudFileIds.length; i++) {
          final cloudId = item.cloudFileIds[i];
          final fileName = 'doc_sync_${DateTime.now().microsecondsSinceEpoch}_$i.enc';
          final localPath = '${attachmentsDir.path}/$fileName';

          debugPrint('AutoSyncService: Downloading attachment ${i + 1} for "${item.title}"...');
          final success = await driveService.downloadAttachment(cloudId, localPath);
          if (success) {
            final newPaths = List<String>.from(item.attachedFiles);
            newPaths.add(localPath);
            item.attachedFiles = newPaths;
            modified = true;
          }
        }
      }

      if (modified) {
        await isar.writeTxn(() async {
          await isar.vaultItems.put(item);
        });
      }
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
