import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/global_components.dart';
import 'settings_list_tile.dart';
import 'settings_section_header.dart';
import 'storage_reset_sheet.dart';

class StorageIntegritySection extends ConsumerWidget {
  const StorageIntegritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'STORAGE INTEGRITY'),
        const SizedBox(height: 2),
        BentoCard(
          padding: EdgeInsets.zero,
          child: SettingsListTile(
            icon: Icons.storage_rounded,
            title: 'Storage Integrity',
            subtitle: 'Manage local database and cloud storage',
            onTap: () => showStorageResetBottomSheet(context, ref),
          ),
        ),
      ],
    );
  }
}
