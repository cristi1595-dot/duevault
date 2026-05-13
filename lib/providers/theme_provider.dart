import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/app_config.dart';
import '../providers/database_provider.dart';
import '../services/auto_sync_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Isar isar;
  final Ref ref;

  ThemeNotifier(this.isar, this.ref) : super(_loadInitial(isar));

  static ThemeMode _loadInitial(Isar isar) {
    final config = isar.appConfigs.getSync(0);
    final isDarkMode = config?.isDarkMode ?? true;
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    await _saveTheme(newMode == ThemeMode.dark);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _saveTheme(mode == ThemeMode.dark);
  }

  Future<void> _saveTheme(bool isDark) async {
    final config = await isar.appConfigs.get(0) ?? AppConfig();
    config.isDarkMode = isDark;
    
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
