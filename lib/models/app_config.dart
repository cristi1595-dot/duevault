import 'package:isar_community/isar.dart';

part 'app_config.g.dart';

@collection
class AppConfig {
  Id id = 0; // Use a fixed ID to ensure only one config object exists
  bool hasSeenOnboarding = false;
  bool hasSeenDemo = false;
  String currencyCode = 'USD';
  int alertDays = 3;
  bool threeDayAlertEnabled = true;
  int finalReminderDays = 0;
  bool finalReminderEnabled = true;
  int notificationHour = 9;
  int notificationMinute = 0;
  bool isDarkMode = true;
  bool autoSync = true;
  bool syncOnWifiOnly = false;
  bool globalNotificationsEnabled = false;
  bool isSecurityEnabled = false;
  bool lockOnBackground = true;
  bool hasAcceptedPrivacyPolicy = false;
  bool isGuest = false; // Persist guest session
  int dataVersion = 1; // Track data migrations

  DateTime? lastLocalChange;
  DateTime? lastCloudSync;
  DateTime? lastSyncCheck; // 15m cooldown for cloud checks
  String? localDatabaseChecksum; // For efficient sync
  bool needsBackup = false; // Flag for interrupted backups
  bool guestDataMigrated = false; // Migration only happens once
}
