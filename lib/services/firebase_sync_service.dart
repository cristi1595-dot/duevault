import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/vault_item.dart';
import '../models/app_config.dart';
import '../providers/database_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/logger.dart';

final firebaseSyncServiceProvider = Provider((ref) => FirebaseSyncService(ref));

class FirebaseSyncService {
  final Ref _ref;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;

  FirebaseSyncService(this._ref);

  void initialize() {
    // Listen for connectivity changes to trigger sync
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        sync();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> sync({bool force = false}) async {
    if (_isSyncing) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if we are processing a critical auth/migration sync
    final isProcessing = _ref.read(isProcessingAuthSyncProvider);
    if (isProcessing && !force) {
      logger.i(
        'FirebaseSyncService: Sync skipped because isProcessingAuthSync is active.',
      );
      return;
    }

    _isSyncing = true;
    try {
      _ref.read(syncProvider.notifier).setSyncing();

      // 1. Upload local changes (Outbound)
      await _uploadLocalChanges(user.uid);

      // 2. Download remote changes (Inbound)
      await _downloadRemoteChanges(user.uid);

      _ref.read(syncProvider.notifier).setSuccess();

      // Reset status after a delay
      Future.delayed(const Duration(seconds: 3), () {
        _ref.read(syncProvider.notifier).resetStatus();
      });
    } catch (e, stack) {
      logger.e('Firebase Sync Error', error: e, stackTrace: stack);
      _ref.read(syncProvider.notifier).setError(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _uploadLocalChanges(String uid) async {
    final isar = _ref.read(isarProvider);

    // Find items modified since last sync or never synced
    final dirtyItems = await isar.vaultItems
        .filter()
        .ownerIdEqualTo(uid)
        .wasSyncedEqualTo(false)
        .findAll();

    if (dirtyItems.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('items');

    for (var item in dirtyItems) {
      final docRef = collection.doc(item.uuid);
      // Senior Architecture: We upload the record even if isDeleted=true
      // so other devices can see the "Tombstone" and delete it locally.
      batch.set(docRef, item.toMap(), SetOptions(merge: true));
    }

    await batch.commit();

    // Mark as synced and clean up deleted items
    await isar.writeTxn(() async {
      for (var item in dirtyItems) {
        item.wasSynced = true;
        await isar.vaultItems.put(item);
      }
    });

    logger.i('Uploaded ${dirtyItems.length} changes to Firebase');
  }

  Future<void> _downloadRemoteChanges(String uid) async {
    final isar = _ref.read(isarProvider);
    final config = await isar.appConfigs.get(0) ?? AppConfig();
    final lastSync =
        config.lastCloudSync ?? DateTime.fromMillisecondsSinceEpoch(0);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('items')
        .where('lastModified', isGreaterThan: lastSync.toIso8601String())
        .get();

    if (snapshot.docs.isEmpty) return;

    await isar.writeTxn(() async {
      for (var doc in snapshot.docs) {
        final remoteItem = VaultItem.fromMap(doc.data());

        // Find local version by UUID
        final localItem = await isar.vaultItems
            .filter()
            .uuidEqualTo(remoteItem.uuid)
            .findFirst();

        if (localItem == null) {
          // New item from another device
          if (!remoteItem.isDeleted) {
            remoteItem.wasSynced = true;
            await isar.vaultItems.put(remoteItem);
          }
        } else {
          // Conflict Resolution: Only update if remote is newer
          if (remoteItem.lastModified.isAfter(localItem.lastModified)) {
            if (remoteItem.isDeleted) {
              localItem.isDeleted = true;
              localItem.wasSynced = true;
              localItem.lastModified = remoteItem.lastModified;
              await isar.vaultItems.put(localItem);
            } else {
              // Merge remote into local (preserving local ID)
              remoteItem.id = localItem.id;
              remoteItem.wasSynced = true;
              await isar.vaultItems.put(remoteItem);
            }
          }
        }
      }

      // Update last sync time
      config.lastCloudSync = DateTime.now();
      await isar.appConfigs.put(config);
    });

    logger.i('Downloaded ${snapshot.docs.length} changes from Firebase');
  }

  Future<void> wipeData(String uid) async {
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('items');

    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) return;

    final docs = snapshot.docs;
    const batchSize = 400;
    for (var i = 0; i < docs.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
      for (var j = i; j < end; j++) {
        batch.delete(docs[j].reference);
      }
      await batch.commit();
    }
    logger.w(
      'FirebaseSyncService: Wiped all Firestore data for user $uid (${docs.length} items)',
    );
  }
}
