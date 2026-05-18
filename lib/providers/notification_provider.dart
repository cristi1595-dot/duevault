import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
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
      state = config.alertDays.clamp(3, 14);
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

/// Provider for the variable final alert days (0-2)
final finalReminderDaysProvider = StateNotifierProvider<FinalReminderDaysNotifier, int>((ref) {
  return FinalReminderDaysNotifier(ref);
});

class FinalReminderDaysNotifier extends StateNotifier<int> {
  final Ref _ref;
  FinalReminderDaysNotifier(this._ref) : super(0) {
    _load();
  }

  Future<void> _load() async {
    final isar = _ref.read(isarProvider);
    final config = await isar.appConfigs.get(0);
    if (config != null) {
      state = config.finalReminderDays.clamp(0, 2);
    }
  }

  Future<void> setFinalReminderDays(int days) async {
    state = days;
    final isar = _ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.finalReminderDays = days;
      await isar.appConfigs.put(config);
    });
  }
}

/// Provider for final reminder toggle
final finalReminderEnabledProvider = StateNotifierProvider<FinalReminderEnabledNotifier, bool>((ref) {
  return FinalReminderEnabledNotifier(ref);
});

class FinalReminderEnabledNotifier extends StateNotifier<bool> {
  final Ref _ref;
  FinalReminderEnabledNotifier(this._ref) : super(true) {
    _load();
  }

  Future<void> _load() async {
    final isar = _ref.read(isarProvider);
    final config = await isar.appConfigs.get(0);
    if (config != null) {
      state = config.finalReminderEnabled;
    }
  }

  Future<void> toggle(bool enabled) async {
    state = enabled;
    final isar = _ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.finalReminderEnabled = enabled;
      await isar.appConfigs.put(config);
    });
  }
}

/// Provider for global notification time (hour and minute)
final notificationTimeProvider = StateNotifierProvider<NotificationTimeNotifier, TimeOfDay>((ref) {
  return NotificationTimeNotifier(ref);
});

class NotificationTimeNotifier extends StateNotifier<TimeOfDay> {
  final Ref _ref;
  NotificationTimeNotifier(this._ref) : super(const TimeOfDay(hour: 9, minute: 0)) {
    _load();
  }

  Future<void> _load() async {
    final isar = _ref.read(isarProvider);
    final config = await isar.appConfigs.get(0);
    if (config != null) {
      state = TimeOfDay(
        hour: config.notificationHour.clamp(0, 23),
        minute: config.notificationMinute.clamp(0, 59),
      );
    }
  }

  Future<void> setTime(TimeOfDay time) async {
    state = time;
    final isar = _ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.notificationHour = time.hour;
      config.notificationMinute = time.minute;
      await isar.appConfigs.put(config);
    });
  }
}
