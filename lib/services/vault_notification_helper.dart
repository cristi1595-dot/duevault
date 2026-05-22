import 'package:flutter/material.dart';
import '../models/vault_item.dart';
import 'notification_service.dart';

class VaultNotificationHelper {
  /// Iterates over all vault items and schedules or cancels notifications based on current settings.
  static Future<void> rescheduleAll({
    required List<VaultItem> items,
    required int alertDays,
    required bool threeDayAlert,
    required int finalReminderDays,
    required bool finalReminderEnabled,
    required TimeOfDay notificationTime,
    required bool notificationsEnabled,
  }) async {
    // ═══════ DIAGNOSTIC: State ═══════
    debugPrint('╔══════════════════════════════════════════════════════');
    debugPrint('║ 🔄 rescheduleAllNotifications() CALLED');
    debugPrint('║ Global Notifications Enabled: $notificationsEnabled');
    debugPrint('║ First Reminder: ${threeDayAlert ? "ON" : "OFF"} ($alertDays days)');
    debugPrint('║ Final Reminder: ${finalReminderEnabled ? "ON" : "OFF"} ($finalReminderDays days)');
    debugPrint('║ Notification Time: ${notificationTime.hour}:${notificationTime.minute.toString().padLeft(2, '0')}');
    debugPrint('║ Total items in Riverpod state: ${items.length}');
    debugPrint('╚══════════════════════════════════════════════════════');
    // ═══════ END DIAGNOSTIC ═══════

    int scheduledCount = 0;
    int skippedCount = 0;

    for (final item in items) {
      if ((item.itemType == 'Bill' || item.itemType == 'Document') &&
          item.dueDate != null &&
          !item.isPaid &&
          !item.isArchived) {
        if (notificationsEnabled) {
          scheduledCount++;
          await NotificationService.scheduleDualAlerts(
            billId: item.id,
            billTitle: item.title,
            dueDate: item.dueDate!,
            firstReminderDays: alertDays,
            finalReminderDays: finalReminderDays,
            isFirstReminderEnabled: threeDayAlert,
            isFinalReminderEnabled: finalReminderEnabled,
            notificationHour: notificationTime.hour,
            notificationMinute: notificationTime.minute,
            itemType: item.itemType ?? 'Document',
            amount: item.amount,
          );
        } else {
          await NotificationService.cancelBillNotifications(item.id);
        }
      } else {
        skippedCount++;
      }
    }

    // ═══════ DIAGNOSTIC: Summary ═══════
    debugPrint(
      '🏁 rescheduleAll DONE: $scheduledCount scheduled, $skippedCount skipped (paid/archived/no-date)',
    );
    // ═══════ END DIAGNOSTIC ═══════
  }
}
