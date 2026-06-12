import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/drive_service.dart';
import '../../services/encryption_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../utils/logger.dart';
import '../../models/app_config.dart';
import 'settings_dialogs.dart';

class DeveloperOptionsSection extends ConsumerWidget {
  const DeveloperOptionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'DEVELOPER OPTIONS'),
        const SizedBox(height: 2),
        BentoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildSettingItem(
                context: context,
                icon: Icons.cloud_sync_outlined,
                iconColor: AppTheme.primaryAction,
                title: 'Cloud Backup Diagnostics',
                subtitle: 'Inspect files in Google Drive & Firestore',
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AppTheme.primaryAction,
                ),
                onTap: () => _runCloudDiagnostics(context, ref),
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingItem(
                context: context,
                icon: Icons.settings_backup_restore_rounded,
                iconColor: AppTheme.safeGreen,
                title: 'Force Restore Cloud Backup',
                subtitle: 'Import keys and force sync database',
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AppTheme.safeGreen,
                ),
                onTap: () => _forceRestoreKeysAndData(context, ref),
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingItem(
                context: context,
                icon: Icons.bug_report_outlined,
                iconColor: AppTheme.urgentRed,
                title: 'Simulate Test Crash',
                subtitle: 'Forces an immediate crash for Crashlytics test',
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AppTheme.urgentRed,
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
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2, top: 2),
      child: Text(
        title,
        style: AppTheme.labelCapsStyle(context).copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppTheme.primaryAction, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).textTheme.bodySmall?.color,
              size: 14,
            ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Future<void> _runCloudDiagnostics(BuildContext context, WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not signed in to Google/Firebase.'),
          backgroundColor: AppTheme.urgentRed,
        ),
      );
      return;
    }

    // Show loading
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
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
          } catch (e) {
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
            backgroundColor: Theme.of(ctx).cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Cloud Backup Diagnostics'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                     '🔥 FIRESTORE METADATA:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAction),
                  ),
                  const SizedBox(height: 4),
                  Text('Total Items in Firestore: $firestoreCount'),
                  const SizedBox(height: 4),
                  if (firestoreItems.isNotEmpty)
                    Text(
                      firestoreItems.join('\n'),
                      style: const TextStyle(fontSize: 12),
                    )
                  else
                    const Text('No records found in Firestore.'),
                  const Divider(height: 24),
                  const Text(
                    '📁 GOOGLE DRIVE BACKUPS:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAction),
                  ),
                  const SizedBox(height: 4),
                  Text('Keys Backup: ${keyBackupExists ? "✅ FOUND" : "❌ MISSING"}'),
                  Text('Database Backup: ${dbBackupExists ? "✅ FOUND" : "❌ MISSING"}'),
                  const SizedBox(height: 8),
                  Text(
                    driveFilesInfo,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
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
            title: const Text('Diagnostics Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _forceRestoreKeysAndData(BuildContext context, WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Force Restore Backup'),
        content: const Text(
          'This will download your original encryption keys and database from Google Drive, '
          'and pull all data from Firestore. Your current local data will be replaced. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.safeGreen),
            child: const Text('RESTORE', style: TextStyle(color: Colors.white)),
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
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
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
              title: const Text('Restore Complete'),
              content: const Text('Encryption keys, database, and all cloud records have been successfully restored!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
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
            title: const Text('Restore Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
