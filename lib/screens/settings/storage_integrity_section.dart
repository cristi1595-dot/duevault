import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_list_tile.dart';
import 'storage_reset_sheet.dart';

class StorageIntegritySection extends ConsumerWidget {
  const StorageIntegritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsListTile(
      icon: Icons.storage_rounded,
      title: 'Storage Integrity',
      subtitle: 'Manage local database and cloud storage',
      onTap: () => showStorageResetBottomSheet(context, ref),
    );
  }
}
