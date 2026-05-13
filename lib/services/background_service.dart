import 'package:workmanager/workmanager.dart';
import 'package:isar/isar.dart';


import 'package:path_provider/path_provider.dart';

import '../models/user.dart';
import '../models/vault_item.dart';
import '../models/app_config.dart';




const syncTaskName = "com.duevault.syncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      Isar? isar = Isar.getInstance();
      final bool shouldClose = isar == null;
      if (isar == null) {
        final dir = await getApplicationDocumentsDirectory();
        isar = await Isar.open(
          [UserSchema, VaultItemSchema, AppConfigSchema],
          directory: dir.path,
        );


      }


      final Isar db = isar;



      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Find ALL recurring bills that are paid and whose due date is in the past or today
      final recurringBills = await db.vaultItems
          .filter()
          .not().recurrenceEqualTo('None')
          .and()
          .isPaidEqualTo(true)
          .findAll();

      for (final bill in recurringBills) {
        if (bill.dueDate != null) {
          final due = DateTime(bill.dueDate!.year, bill.dueDate!.month, bill.dueDate!.day);
          
          if (due.isBefore(today) || due.isAtSameMomentAs(today)) {
            DateTime nextDueDate;

            if (bill.recurrence == 'Weekly') {
              nextDueDate = due.add(const Duration(days: 7));
            } else if (bill.recurrence == 'Yearly') {
              // Clamp day for leap year edge case (Feb 29 → Feb 28)
              final nextYear = due.year + 1;
              final lastDayOfMonth = DateTime(nextYear, due.month + 1, 0).day;
              final clampedDay = due.day > lastDayOfMonth ? lastDayOfMonth : due.day;
              nextDueDate = DateTime(nextYear, due.month, clampedDay);
            } else {
              // Monthly (default)
              // Safe next month calculation (e.g., Jan 31 → Feb 28)
              final nextMonth = due.month == 12 ? 1 : due.month + 1;
              final nextYear = due.month == 12 ? due.year + 1 : due.year;
              final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
              final clampedDay = due.day > lastDayOfNextMonth ? lastDayOfNextMonth : due.day;
              nextDueDate = DateTime(nextYear, nextMonth, clampedDay);
            }

            final existing = await db.vaultItems
                .filter()
                .titleEqualTo(bill.title)
                .dueDateEqualTo(nextDueDate)
                .findFirst();

            if (existing == null) {
              final newBill = VaultItem()
                ..ownerId = bill.ownerId
                ..itemType = bill.itemType
                ..category = bill.category
                ..title = bill.title
                ..amount = bill.amount
                ..dueDate = nextDueDate
                ..isPaid = false
                ..recurrence = bill.recurrence
                ..directDebit = bill.directDebit
                ..notes = bill.notes
                ..attachedFiles = List.from(bill.attachedFiles);

              await db.writeTxn(() async {
                await db.vaultItems.put(newBill);
              });
            }
          }
        }
      }

      if (shouldClose) await db.close();
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static void initialize() {
    Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static void registerPeriodicTask() {
    Workmanager().registerPeriodicTask(
      "1",
      syncTaskName,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected, 
      ),
    );
  }
}
