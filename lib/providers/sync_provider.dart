import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';
import '../models/app_config.dart';
import 'package:isar/isar.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final String? message;
  final DateTime? lastSync;

  const SyncState({
    required this.status,
    this.message,
    this.lastSync,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    DateTime? lastSync,
  }) {
    return SyncState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState(status: SyncStatus.idle));

  void setSyncing() {
    state = state.copyWith(status: SyncStatus.syncing);
  }

  void setSuccess({String? message}) {
    state = state.copyWith(
      status: SyncStatus.success,
      message: message,
      lastSync: DateTime.now(),
    );
  }

  void setError(String message) {
    state = state.copyWith(status: SyncStatus.error, message: message);
  }

  void resetStatus() {
    state = state.copyWith(status: SyncStatus.idle, message: null);
  }

  void setStatus(SyncStatus status, {String? message}) {
    state = state.copyWith(status: status, message: message);
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});

// Auto Sync Provider
class AutoSyncNotifier extends StateNotifier<bool> {
  final Isar isar;
  AutoSyncNotifier(this.isar) : super(true) {
    _init();
  }

  void _init() {
    final config = isar.appConfigs.getSync(0);
    if (config != null) {
      state = config.autoSync;
    }
  }

  Future<void> toggleAutoSync(bool value) async {
    state = value;
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.autoSync = value;
      await isar.appConfigs.put(config);
    });
  }
}

final autoSyncProvider = StateNotifierProvider<AutoSyncNotifier, bool>((ref) {
  final isar = ref.watch(isarProvider);
  return AutoSyncNotifier(isar);
});

// WiFi Only Provider
class WifiOnlyNotifier extends StateNotifier<bool> {
  final Isar isar;
  WifiOnlyNotifier(this.isar) : super(false) {
    _init();
  }

  void _init() {
    final config = isar.appConfigs.getSync(0);
    if (config != null) {
      state = config.syncOnWifiOnly;
    }
  }

  Future<void> toggleWifiOnly(bool value) async {
    state = value;
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.syncOnWifiOnly = value;
      await isar.appConfigs.put(config);
    });
  }
}

final wifiOnlyProvider = StateNotifierProvider<WifiOnlyNotifier, bool>((ref) {
  final isar = ref.watch(isarProvider);
  return WifiOnlyNotifier(isar);
});

// Last Sync Timestamp Provider
final lastSyncTimestampProvider = StreamProvider<DateTime?>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.appConfigs.watchObject(0, fireImmediately: true)
      .map((config) => config?.lastCloudSync);
});

/// Provider to track if we are in the middle of a critical sync/migration
final isProcessingAuthSyncProvider = StateProvider<bool>((ref) => false);
