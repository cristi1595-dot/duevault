import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../models/app_config.dart';
import '../providers/database_provider.dart';
import '../services/auto_sync_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Isar isar;
  final Ref ref;

  ThemeNotifier(this.isar, this.ref) : super(_loadInitial(isar));

  static ThemeMode _loadInitial(Isar isar) {
    final config = isar.appConfigs.getSync(0);
    final themeStr = config?.themeModeString;
    if (themeStr == null) {
      // Legacy fallback
      final isDarkMode = config?.isDarkMode ?? true;
      return isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
    
    switch (themeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _saveTheme(mode);
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final config = await isar.appConfigs.get(0) ?? AppConfig();
    
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        config.isDarkMode = false;
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        config.isDarkMode = true;
        break;
      case ThemeMode.system:
        modeStr = 'system';
        config.isDarkMode = true;
        break;
    }
    config.themeModeString = modeStr;

    await isar.writeTxn(() async {
      await isar.appConfigs.put(config);
    });

    // Trigger auto-backup
    ref.read(autoSyncServiceProvider).scheduleBackup();
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final isar = ref.watch(isarProvider);
  return ThemeNotifier(isar, ref);
});
