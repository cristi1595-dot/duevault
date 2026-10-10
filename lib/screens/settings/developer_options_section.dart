import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/drive_service.dart';
import '../../services/encryption_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../utils/logger.dart';
import '../../models/app_config.dart';
import 'settings_dialogs.dart';
import 'settings_list_tile.dart';
import 'settings_divider.dart';

class DeveloperOptionsSection extends ConsumerWidget {
  const DeveloperOptionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syncTimestamp = ref.watch(lastSyncTimestampProvider);
    final syncState = ref.watch(syncProvider);

    String syncSubtitle = 'Active & Up to date';
    if (syncState.status == SyncStatus.syncing) {
      syncSubtitle = 'Syncing...';
    } else if (syncTimestamp.valueOrNull != null) {
      final formatted = DateFormat('MMM dd, HH:mm').format(syncTimestamp.valueOrNull!.toLocal());
      syncSubtitle = 'Last sync: $formatted';
    }

    return Column(
      children: [
        SettingsListTile(
          icon: Icons.cloud_done_rounded,
          iconColor: isDark ? AppColors.emerald400 : AppColors.emerald600,
          title: 'Automated Cloud Sync',
          subtitle: syncSubtitle,
          trailing: (syncState.status == SyncStatus.syncing)
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.emerald400 : AppColors.emerald600,
                    ),
                  ),
                )
              : Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                ),
          onTap: () async {
            await HapticFeedback.lightImpact();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Triggering cloud sync...'),
                duration: Duration(seconds: 1),
              ),
            );
            await ref.read(firebaseSyncServiceProvider).sync(force: true);
          },
        ),
        const SettingsDivider(),
        SettingsListTile(
          icon: Icons.cloud_sync_outlined,
          iconColor: isDark ? AppColors.emerald400 : AppColors.emerald600,
          title: 'Cloud Backup Diagnostics',
          subtitle: 'Inspect files in Google Drive & Firestore',
          onTap: () => _runCloudDiagnostics(context, ref),
        ),
        const SettingsDivider(),
        SettingsListTile(
          icon: Icons.settings_backup_restore_rounded,
          iconColor: isDark ? AppColors.emerald400 : AppColors.emerald600,
          title: 'Force Restore Cloud Backup',
          subtitle: 'Import keys and force sync database',
          onTap: () => _forceRestoreKeysAndData(context, ref),
        ),
        const SettingsDivider(),
        SettingsListTile(
          icon: Icons.bug_report_outlined,
          iconColor: AppColors.urgentRose600,
          title: 'Simulate Test Crash',
          subtitle: 'Forces an immediate crash for Crashlytics test',
          trailing: const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.urgentRose600,
          ),
          onTap: () async {
            final confirm = await SettingsDialogs.showCrashTestDialog(context);

            if (confirm == true) {
              logger.i('Simulating app crash via Firebase Crashlytics...');
              await Future.delayed(const Duration(milliseconds: 500));
              FirebaseCrashlytics.instance.crash();
            }
          },
        ),
      ],
    );
  }

  Future<void> _runCloudDiagnostics(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not signed in to Google/Firebase.'),
          backgroundColor: AppColors.urgentRose600,
        ),
      );
      return;
    }

    // Show loading
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.emerald400 : AppColors.emerald600,
            ),
          ),
        ),
      ),
    );

    try {
      // 1. Check Firestore count
      final firestoreSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('items')
          .get();
      final firestoreCount = firestoreSnapshot.docs.length;
      final List<String> firestoreItems = [];
      for (var doc in firestoreSnapshot.docs) {
        final data = doc.data();
        final titleEnc = data['title'] as String?;
        String title = 'Unreadable';
        if (titleEnc != null) {
          try {
            final dec = await EncryptionService.decryptText(titleEnc);
            title = dec ?? 'Empty';
          } catch (e, stack) {
            logger.e('Failed to decrypt title for Firestore item', error: e, stackTrace: stack);
            title = 'Encrypted (Decryption key missing)';
          }
        }
        final isDeleted = data['isDeleted'] == true;
        firestoreItems.add('- $title ${isDeleted ? "(Deleted Tombstone)" : ""}');
      }

      // 2. Check Google Drive files
      final authService = ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      String driveFilesInfo = 'No Google Drive access/token.';
      bool keyBackupExists = false;
      bool dbBackupExists = false;

      if (token != null) {
        final driveService = DriveService(GoogleAuthClient({'Authorization': 'Bearer $token'}));
        try {
          final fileList = await driveService.driveApi.files.list(
            spaces: 'appDataFolder',
            $fields: 'files(id, name, size, modifiedTime, md5Checksum)',
          );

          if (fileList.files != null && fileList.files!.isNotEmpty) {
            final buffer = StringBuffer();
            for (var file in fileList.files!) {
              buffer.writeln('📁 ${file.name}');
              buffer.writeln('  Size: ${file.size != null ? "${(int.parse(file.size!) / 1024).toStringAsFixed(1)} KB" : "Unknown"}');
              buffer.writeln('  Modified: ${file.modifiedTime?.toLocal()}');
              buffer.writeln();
              if (file.name == 'duevault_keys.json') keyBackupExists = true;
              if (file.name == 'duevault_backup.isar') dbBackupExists = true;
            }
            driveFilesInfo = buffer.toString();
          } else {
            driveFilesInfo = 'No files found in Google Drive appDataFolder.';
          }
        } finally {
          driveService.dispose();
        }
      }

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
      }

      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: BorderSide(color: AppColors.border(isDark)),
            ),
            title: Text(
              'Cloud Backup Diagnostics',
              style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🔥 FIRESTORE METADATA:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Items in Firestore: $firestoreCount',
                    style: TextStyle(color: AppColors.textPrimary(isDark)),
                  ),
                  const SizedBox(height: 4),
                  if (firestoreItems.isNotEmpty)
                    Text(
                      firestoreItems.join('\n'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDark),
                      ),
                    )
                  else
                    Text(
                      'No records found in Firestore.',
                      style: TextStyle(color: AppColors.textSecondary(isDark)),
                    ),
                  Divider(height: 24, color: AppColors.border(isDark)),
                  Text(
                    '📁 GOOGLE DRIVE BACKUPS:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keys Backup: ${keyBackupExists ? "✅ FOUND" : "❌ MISSING"}',
                    style: TextStyle(color: AppColors.textPrimary(isDark)),
                  ),
                  Text(
                    'Database Backup: ${dbBackupExists ? "✅ FOUND" : "❌ MISSING"}',
                    style: TextStyle(color: AppColors.textPrimary(isDark)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    driveFilesInfo,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
      }
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: BorderSide(color: AppColors.border(isDark)),
            ),
            title: Text(
              'Diagnostics Error',
              style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
            ),
            content: Text(
              e.toString(),
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _forceRestoreKeysAndData(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: AppColors.border(isDark)),
        ),
        title: Text(
          'Force Restore Backup',
          style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
        ),
        content: Text(
          'This will download your original encryption keys and database from Google Drive, '
          'and pull all data from Firestore. Your current local data will be replaced. Proceed?',
          style: TextStyle(color: AppColors.textSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.emerald500 : AppColors.emerald600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('RESTORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.emerald400 : AppColors.emerald600,
            ),
          ),
        ),
      ),
    );

    try {
      final authService = ref.read(authServiceProvider);
      final token = await authService.getFreshAccessToken();
      if (token == null) throw Exception('No Google Access Token');

      final authHeaders = {'Authorization': 'Bearer $token'};
      final driveService = DriveService(GoogleAuthClient(authHeaders));

      try {
        final restoredIsar = await driveService.restoreDatabase();
        if (restoredIsar == null) {
          throw Exception('Failed to restore database from Google Drive. Ensure backup file exists.');
        }

        // Update the provider state
        ref.read(isarProvider.notifier).state = restoredIsar;

        // Reset sync checkpoint
        await restoredIsar.writeTxn(() async {
          final config = await restoredIsar.collection<AppConfig>().get(0) ?? AppConfig();
          config.lastCloudSync = DateTime.fromMillisecondsSinceEpoch(0);
          await restoredIsar.appConfigs.put(config);
        });

        // Trigger full Firestore sync
        await ref.read(firebaseSyncServiceProvider).sync();

        // Refresh state
        await ref.read(vaultProvider.notifier).refreshVault();

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface(isDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                side: BorderSide(color: AppColors.border(isDark)),
              ),
              title: Text(
                'Restore Complete',
                style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
              ),
              content: Text(
                'Encryption keys, database, and all cloud records have been successfully restored!',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } finally {
        driveService.dispose();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: BorderSide(color: AppColors.border(isDark)),
            ),
            title: Text(
              'Restore Failed',
              style: AppTypography.headlineMedium(AppColors.textPrimary(isDark)),
            ),
            content: Text(
              e.toString(),
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}
