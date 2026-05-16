import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';
import '../models/app_config.dart';
import '../services/notification_service.dart';

/// Provider for the variable alert days (1-7)
final alertDaysProvider = StateNotifierProvider<AlertDaysNotifier, int>((ref) {
  return AlertDaysNotifier(ref);
});

class AlertDaysNotifier extends StateNotifier<int> {
  final Ref _ref;
  AlertDaysNotifier(this._ref) : super(3) {
    _load();
  }

  Future<void> _load() async {
    final isar = _ref.read(isarProvider);
    final config = await isar.appConfigs.get(0);
    if (config != null) {
      state = config.alertDays;
    }
  }

  Future<void> setAlertDays(int days) async {
    state = days;
    final isar = _ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.alertDays = days;
      await isar.appConfigs.put(config);
    });
  }
}

/// Provider for the fixed 3-day early alert
final threeDayAlertEnabledProvider =
    StateNotifierProvider<ThreeDayAlertNotifier, bool>((ref) {
      return ThreeDayAlertNotifier(ref);
    });

class ThreeDayAlertNotifier extends StateNotifier<bool> {
  final Ref _ref;
  ThreeDayAlertNotifier(this._ref) : super(true) {
    _load();
  }

  Future<void> _load() async {
    final isar = _ref.read(isarProvider);
    final config = await isar.appConfigs.get(0);
    if (config != null) {
      state = config.threeDayAlertEnabled;
    }
  }

  Future<void> toggle(bool enabled) async {
    state = enabled;
    final isar = _ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.threeDayAlertEnabled = enabled;
      await isar.appConfigs.put(config);
    });
  }
}

/// Provider for global notification toggle
final globalNotificationsProvider =
    StateNotifierProvider<GlobalNotificationsNotifier, bool>((ref) {
      return GlobalNotificationsNotifier(ref);
    });

class GlobalNotificationsNotifier extends StateNotifier<bool> {
  final Ref _ref;
  GlobalNotificationsNotifier(this._ref) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final isar = _ref.read(isarProvider);
    final config = await isar.appConfigs.get(0);
    if (config != null) {
      state = config.globalNotificationsEnabled;
    }
  }

  Future<void> toggle(bool enabled) async {
    state = enabled;
    final isar = _ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.globalNotificationsEnabled = enabled;
      await isar.appConfigs.put(config);
    });

    // Request permissions when enabling
    if (enabled) {
      await NotificationService.requestPermissions();
    }
  }
}
