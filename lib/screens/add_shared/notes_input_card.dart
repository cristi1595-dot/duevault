import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'bento_input_wrapper.dart';

/// Reusable Notes & Remarks Card for AddBillScreen and AddDocumentScreen:
/// Shows a button to reveal notes when collapsed, and an expandable BentoInputWrapper when active.
class NotesInputCard extends StatelessWidget {
  final TextEditingController notesController;
  final bool showNotes;
  final bool isDark;
  final bool isBill;
  final VoidCallback onAddNotesPressed;
  final VoidCallback onClosePressed;

  const NotesInputCard({
    super.key,
    required this.notesController,
    required this.showNotes,
    required this.isDark,
    this.isBill = true,
    required this.onAddNotesPressed,
    required this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isBill
        ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
        : (isDark ? AppColors.violet400 : AppColors.violet600);
    final accentLabelColor = isBill
        ? (isDark ? AppColors.emerald400 : AppColors.emerald700)
        : (isDark ? AppColors.violet400 : AppColors.violet600);

    if (!showNotes) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            onAddNotesPressed();
          },
          icon: Icon(
            Icons.note_add_outlined,
            size: 18,
            color: accentColor,
          ),
          label: Text(
            'Add Notes & Remarks',
            style: TextStyle(
              color: accentLabelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return BentoInputWrapper(
      label: 'NOTES & REMARKS',
      icon: Icons.description_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: notesController,
                maxLines: 2,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: isBill
                      ? 'Add invoice number, payment details...'
                      : 'Add document number, remarks...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted(isDark),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary(isDark),
              ),
              onPressed: onClosePressed,
            ),
          ],
        ),
      ),
    );
  }
}
