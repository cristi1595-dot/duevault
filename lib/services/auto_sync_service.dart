import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';

import 'dart:io';
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
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../utils/logger.dart';


/// Handles automatic backup to Google Drive after data changes,
/// and automatic restore when the user signs in.
class AutoSyncService {
  final Ref _ref;
  Timer? _debounceTimer;
  bool _isSyncing = false;

  AutoSyncService(this._ref);

  /// Check if user is signed in with Google (not guest)
  bool get _isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Debounced auto-backup — waits 2s after last change.
  /// If [immediate] is true, it starts right away (e.g. app going to background).
  void scheduleBackup({bool immediate = false}) {
    if (!_isSignedIn) return;
 
    final autoSyncEnabled = _ref.read(autoSyncProvider);
    if (!autoSyncEnabled) return;
 
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
      logger.w('Auto-backup skipped: Connectivity restrictions or no internet');
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
          // 1. Sync Attachments first
          await _syncAttachments(driveService);

          final success = await driveService.backupDatabase();
          if (success) {
            // Calculate and Store checksum (Senior Fix: Data savings)
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
            await isar.writeTxn(() async {
              final itemsToMark = await isar.collection<VaultItem>().filter().wasSyncedEqualTo(false).findAll();
              for (var item in itemsToMark) {
                item.wasSynced = true;
              }
              await isar.collection<VaultItem>().putAll(itemsToMark);

              final config = await isar.collection<AppConfig>().get(0) ?? AppConfig();
              config.lastCloudSync = DateTime.now();
              config.localDatabaseChecksum = checksum; // Store for comparison
              await isar.appConfigs.put(config);
            });

            Timer(const Duration(seconds: 3), () {
              _ref.read(syncProvider.notifier).resetStatus();
            });
          } else {
            _ref.read(syncProvider.notifier).setError('Backup failed');
          }
          logger.i('Auto-backup ${success ? 'successful' : 'failed'}');
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
  /// Returns a string describing the result ('restored', 'uploaded', 'none')
  Future<String> syncAfterLogin() async {
    if (!_isSignedIn) return 'none';

    try {
      final authService = _ref.read(authServiceProvider);
      // Force refresh to ensure we have the new scopes (fix C2)
      final token = await authService.getFreshAccessToken();
      if (token == null) {
        logger.w('AutoSyncService: Failed to get token during syncAfterLogin');
        return 'none';
      }

      final authHeaders = {'Authorization': 'Bearer $token'};
      final driveService = DriveService(GoogleAuthClient(authHeaders));

      try {
        // 1. Check if cloud backup exists first
        final cloudChecksum = await driveService.getBackupChecksum();
        
        if (cloudChecksum == null) {
          logger.i('AutoSyncService: No cloud backup found.');
          
          // 2. If NO backup exists but we have local data, upload it now
          final localItems = _ref.read(vaultProvider);
          final hasRealLocalData = localItems.any((item) => !item.isSample);
          
          if (hasRealLocalData) {
            logger.i('AutoSyncService: Uploading initial local data to new account...');
            final success = await driveService.backupDatabase();
            if (success) return 'uploaded';
          } else {
            // No cloud data and no local data
            return 'empty';
          }
          return 'none';
        }

        // 3. If cloud backup exists, perform Smart Merge
        final success = await _mergeWithCloud(driveService, isLoginSync: true);
        if (success) {
          // Sync attachments for the merged items
          await _syncAttachments(driveService);
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
      
      // Senior Fix: 15-minute cooldown for cloud checks to save data
      final now = DateTime.now();
      if (config.lastSyncCheck != null && 
          now.difference(config.lastSyncCheck!).inMinutes < 15) {
        logger.i('AutoSyncService: Skipping startup check (cooldown active).');
        return;
      }

      final authService = _ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token == null) return;

      final authHeaders = {'Authorization': 'Bearer $token'};
      final driveService = DriveService(GoogleAuthClient(authHeaders));

      try {
        // Fetch cloud checksum first (extremely small data usage)
        final cloudChecksum = await driveService.getBackupChecksum();
        
        // Calculate local checksum for comparison
        final dir = await getApplicationDocumentsDirectory();
        final dbFile = File('${dir.path}/default.isar');
        final localChecksum = await driveService.getFileChecksum(dbFile);

        // Update sync check markers
        await isar.writeTxn(() async {
          final currentConfig = await isar.appConfigs.get(0) ?? AppConfig();
          currentConfig.lastSyncCheck = now;
          currentConfig.localDatabaseChecksum = localChecksum;
          await isar.appConfigs.put(currentConfig);
        });

        if (cloudChecksum == null) {
          // No cloud data -> Backup if local exists
          if (config.lastLocalChange != null) {
             logger.i('AutoSyncService: No cloud backup found. Uploading initial local data...');
             await _performBackup();
          }
          return;
        }

        if (cloudChecksum == localChecksum) {
          logger.i('AutoSyncService: Cloud data is identical (checksum match). Skipping sync.');
          return;
        }

        // Checksums differ -> Check metadata for modification time to decide who is newer
        final cloudMetadata = await driveService.getCloudMetadata();
        final localTime = config.lastLocalChange;

        if (cloudMetadata != null) {
          final cloudTimeString = cloudMetadata['last_modified'] as String?;
          final cloudTime = cloudTimeString != null ? DateTime.tryParse(cloudTimeString) : null;

          if (cloudTime != null) {
             if (localTime == null || cloudTime.isAfter(localTime.add(const Duration(seconds: 5)))) {
                logger.i('AutoSyncService: Cloud data is different and newer. Triggering smart merge...');
                await _mergeWithCloud(driveService, isLoginSync: false);
                await _syncAttachments(driveService);
              } 
              else if (localTime.isAfter(cloudTime.add(const Duration(seconds: 5)))) {
                logger.i('AutoSyncService: Local data is newer. Triggering background backup...');
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

  /// Advanced Smart Merge: Resolves multi-device conflicts using UUIDs and timestamps.
  /// Does NOT overwrite the whole DB.
  Future<bool> _mergeWithCloud(DriveService driveService, {bool isLoginSync = false}) async {
    final localIsar = _ref.read(isarProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // 1. Download cloud data to a temp isolate
    final cloudIsar = await driveService.downloadAndOpenDatabase('merge_${DateTime.now().millisecondsSinceEpoch}');
    if (cloudIsar == null) return false;

    try {
      final cloudItems = await cloudIsar.collection<VaultItem>().filter().ownerIdEqualTo(user.uid).findAll();
      final localItems = await localIsar.collection<VaultItem>().filter().ownerIdEqualTo(user.uid).findAll();

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
            await localIsar.collection<VaultItem>().put(cloudItem..id = Isar.autoIncrement);
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
              await localIsar.collection<VaultItem>().put(localItem);
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
          if (localItem.wasSynced && !isLoginSync) {
            // Item was in cloud before, but is gone now -> Deleted from another device
            logger.i('AutoSyncService: Local item "${localItem.title}" was deleted from cloud. Removing locally...');
            await localIsar.writeTxn(() async {
              // We do a hard delete or soft delete here? 
              // User request: "trebuie eliminat și local"
              await localIsar.collection<VaultItem>().delete(localItem.id);
            });
            localModified = true;
          } else {
            // New local item that hasn't reached the cloud yet
            cloudModified = true;
          }
        }
      }


      if (localModified) {
        logger.i('AutoSyncService: Merge complete. Local UI refreshed.');
        await _ref.read(vaultProvider.notifier).refreshVault();
      }

      if (cloudModified) {
        logger.i('AutoSyncService: Merge complete. Local changes detected, scheduling backup...');
        scheduleBackup();
      }

      // 3. Update Sync Marker to prevent loops
      await localIsar.writeTxn(() async {
        final config = await localIsar.collection<AppConfig>().get(0) ?? AppConfig();
        config.lastCloudSync = DateTime.now();
        config.lastLocalChange = DateTime.now();
        await localIsar.collection<AppConfig>().put(config);
      });


      return true;
    } catch (e, stack) {
      logger.e('AutoSyncService: Merge error', error: e, stackTrace: stack);
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

    final items = await isar.collection<VaultItem>().filter().ownerIdEqualTo(user.uid).findAll();

    for (var item in items) {
      try {
        bool modified = false;

        // 1. CLEANUP: Delete local files that are no longer tracked in Cloud IDs
        if (item.attachedFiles.length > item.cloudFileIds.length) {
          final newPaths = List<String>.from(item.attachedFiles);
          final newChecksums = List<String>.from(item.cloudFileChecksums);

          for (int i = item.attachedFiles.length - 1; i >= item.cloudFileIds.length; i--) {
            final localPath = item.attachedFiles[i];
            final file = File(localPath);
            if (await file.exists()) {
              await file.delete();
            }
            newPaths.removeAt(i);
            if (i < newChecksums.length) newChecksums.removeAt(i);
            modified = true;
          }
          item.attachedFiles = newPaths;
          item.cloudFileChecksums = newChecksums;
        }

        // 2. UPLOAD/UPDATE files in Cloud based on Checksums
        for (int i = 0; i < item.attachedFiles.length; i++) {
          final localFile = File(item.attachedFiles[i]);
          if (!await localFile.exists()) continue;

          // Calculate current local checksum
          final currentBytes = await localFile.readAsBytes();
          final currentChecksum = md5.convert(currentBytes).toString();
          
          bool needsUpload = false;
          String? existingCloudId;

          if (i >= item.cloudFileIds.length) {
            // Case A: New file (index out of cloud range)
            needsUpload = true;
          } else {
            // Case B: Existing file index -> Check if content changed
            existingCloudId = item.cloudFileIds[i];
            final lastKnownChecksum = i < item.cloudFileChecksums.length ? item.cloudFileChecksums[i] : '';
            
            if (currentChecksum != lastKnownChecksum) {
              logger.i('AutoSyncService: Attachment content changed for ${item.title} at index $i. Re-uploading...');
              needsUpload = true;
              // If we re-upload, we might want to delete the old cloud file first to avoid orphans,
              // but update() is also an option if DriveService supports it.
            }
          }

          if (needsUpload) {
            // Senior Fix: Delete the old file from Drive if we are replacing it
            if (existingCloudId != null) {
              await driveService.deleteFile(existingCloudId);
            }

            final cloudId = await driveService.uploadAttachment(localFile, 'attach_${item.uuid}_$i');
            if (cloudId != null) {
              final newIds = List<String>.from(item.cloudFileIds);
              final newChecksums = List<String>.from(item.cloudFileChecksums);

              if (i >= newIds.length) {
                newIds.add(cloudId);
                newChecksums.add(currentChecksum);
              } else {
                newIds[i] = cloudId;
                newChecksums[i] = currentChecksum;
              }
              
              item.cloudFileIds = newIds;
              item.cloudFileChecksums = newChecksums;
              modified = true;
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

            final success = await driveService.downloadAttachment(cloudId, localPath);
            if (success) {
              final newPaths = List<String>.from(item.attachedFiles);
              newPaths.add(localPath);
              item.attachedFiles = newPaths;
              
              // After download, update the local checksum to match what we just got
              final downloadedBytes = await File(localPath).readAsBytes();
              final downloadedChecksum = md5.convert(downloadedBytes).toString();
              
              final newChecksums = List<String>.from(item.cloudFileChecksums);
              if (i >= newChecksums.length) {
                newChecksums.add(downloadedChecksum);
              } else {
                newChecksums[i] = downloadedChecksum;
              }
              item.cloudFileChecksums = newChecksums;
              
              modified = true;
            }
          }
        }

        if (modified) {
          await isar.writeTxn(() async {
            await isar.collection<VaultItem>().put(item);
          });
        }
      } catch (e) {
        logger.e('Error syncing attachments for item ${item.title}', error: e);
        // Continue with next item instead of crashing
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
