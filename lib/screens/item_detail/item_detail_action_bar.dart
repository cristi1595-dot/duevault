import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/vault_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';

/// Sticky Bottom Action Bar for ItemDetailScreen:
/// Contains Archive/Restore squircle button and Primary Paid/Renewed action button.
class ItemDetailActionBar extends StatelessWidget {
  final VaultItem item;
  final bool isDark;
  final bool isBusy;
  final VoidCallback onToggleArchive;
  final VoidCallback onTogglePaid;

  const ItemDetailActionBar({
    super.key,
    required this.item,
    required this.isDark,
    required this.isBusy,
    required this.onToggleArchive,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final isBill = item.itemType == 'Bill';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
          AppSpacing.base,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(isDark),
          border: Border(
            top: BorderSide(color: AppColors.border(isDark), width: 1.0),
          ),
        ),
        child: Row(
          children: [
            // Secondary Action: Archive / Restore Squircle Button
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated(isDark),
                border: Border.all(color: AppColors.border(isDark)),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: IconButton(
                tooltip: item.isArchived
                    ? 'Restore to Active'
                    : 'Archive Item',
                icon: Icon(
                  item.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  color: AppColors.textPrimary(isDark),
                  size: 22,
                ),
                onPressed: isBusy
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onToggleArchive();
                      },
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Primary Sticky Button: Mark as Paid / Renewed OR Mark as Unpaid / Not Renewed
            Expanded(
              child: SizedBox(
                height: 52,
                child: item.isPaid
                    ? OutlinedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                onTogglePaid();
                              },
                        icon: isBusy
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary(isDark),
                                ),
                              )
                            : const Icon(Icons.undo_rounded, size: 20),
                        label: Text(
                          isBusy
                              ? 'Updating...'
                              : (isBill ? 'Mark as Unpaid' : 'Mark as Not Renewed'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary(isDark),
                          side: BorderSide(color: AppColors.border(isDark)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                      )
                    : PrimaryButton(
                        label: isBusy
                            ? 'Updating...'
                            : (isBill ? 'Mark as Paid' : 'Mark as Renewed'),
                        icon: isBusy ? null : Icons.check_circle_outline_rounded,
                        isLoading: isBusy,
                        height: 52,
                        borderRadius: AppRadius.lg,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onTogglePaid();
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
