import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/app_config.dart';
import 'database_provider.dart';
import '../services/auto_sync_service.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSync;
  final String? errorMessage;

  SyncState({
    this.status = SyncStatus.idle,
    this.lastSync,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSync,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(SyncState());

  void setSyncing() => state = state.copyWith(status: SyncStatus.syncing);
  
  void setSuccess() => state = state.copyWith(
    status: SyncStatus.success,
    lastSync: DateTime.now(),
    errorMessage: null,
  );
  
  void setError(String message) => state = state.copyWith(
    status: SyncStatus.error,
    errorMessage: message,
  );

  void resetStatus() {
    if (state.status != SyncStatus.syncing) {
      state = state.copyWith(status: SyncStatus.idle);
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});

class AutoSyncNotifier extends StateNotifier<bool> {
  final Isar isar;
  final Ref ref;

  AutoSyncNotifier(this.isar, this.ref) : super(_loadInitial(isar));

  static bool _loadInitial(Isar isar) {
    final config = isar.appConfigs.getSync(0);
    return config?.autoSync ?? true;
  }

  Future<void> toggleAutoSync(bool value) async {
    state = value;
    final config = await isar.appConfigs.get(0) ?? AppConfig();
    config.autoSync = value;
    await isar.writeTxn(() async {
      await isar.appConfigs.put(config);
    });
    
    // If turned ON, trigger a sync
    if (value) {
      ref.read(autoSyncServiceProvider).scheduleBackup();
    }
  }
}

final autoSyncProvider = StateNotifierProvider<AutoSyncNotifier, bool>((ref) {
  final isar = ref.watch(isarProvider);
  return AutoSyncNotifier(isar, ref);
});

class WifiOnlyNotifier extends StateNotifier<bool> {
  final Isar isar;
  final Ref ref;

  WifiOnlyNotifier(this.isar, this.ref) : super(_loadInitial(isar));

  static bool _loadInitial(Isar isar) {
    final config = isar.appConfigs.getSync(0);
    return config?.syncOnWifiOnly ?? false;
  }

  Future<void> toggleWifiOnly(bool value) async {
    state = value;
    final config = await isar.appConfigs.get(0) ?? AppConfig();
    config.syncOnWifiOnly = value;
    await isar.writeTxn(() async {
      await isar.appConfigs.put(config);
    });

    // Re-check sync status
    ref.read(autoSyncServiceProvider).scheduleBackup();
  }
}

final wifiOnlyProvider = StateNotifierProvider<WifiOnlyNotifier, bool>((ref) {
  final isar = ref.watch(isarProvider);
  return WifiOnlyNotifier(isar, ref);
});

final lastSyncTimestampProvider = StreamProvider<DateTime?>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.appConfigs.watchObject(0, fireImmediately: true).map((config) => config?.lastCloudSync);
});

