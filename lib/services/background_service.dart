import 'package:workmanager/workmanager.dart';
import 'package:isar/isar.dart';


import 'package:path_provider/path_provider.dart';

import '../models/user.dart';
import '../models/vault_item.dart';
import '../models/app_config.dart';
import '../utils/date_helper.dart';
import '../utils/logger.dart';




const syncTaskName = "com.duevault.syncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      Isar? isar = Isar.getInstance();
      final bool shouldClose = isar == null;
      if (isar == null) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          isar = await Isar.open(
            [UserSchema, VaultItemSchema, AppConfigSchema],
            directory: dir.path,
            inspector: false, // Essential for Android 15 background isolates
          );
        } catch (e) {
          logger.e('BackgroundService: Failed to open Isar', error: e);
          return Future.value(false);
        }
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

      final List<VaultItem> newInstances = [];

      for (final bill in recurringBills) {
        if (bill.dueDate != null) {
          final nextDueDate = DateHelper.calculateNextDueDate(
            bill.dueDate!, 
            bill.recurrence,
            targetDay: bill.originalDueDay,
          );
          
          if (nextDueDate.isAfter(DateTime.now()) || nextDueDate.isAtSameMomentAs(today)) {
            // Check if this instance already exists (using a derived UUID is better)
            final nextUuid = 'next_${bill.uuid}_${nextDueDate.millisecondsSinceEpoch}';
            
            final existing = await db.vaultItems
                .filter()
                .uuidEqualTo(nextUuid)
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
                ..uuid = nextUuid
                ..recurrence = bill.recurrence
                ..directDebit = bill.directDebit
                ..originalDueDay = bill.originalDueDay
                ..notes = bill.notes
                ..attachedFiles = List.from(bill.attachedFiles);

              newInstances.add(newBill);
            }
          }
        }
      }

      if (newInstances.isNotEmpty) {
        await db.writeTxn(() async {
          await db.vaultItems.putAll(newInstances);
        });
        logger.i('BackgroundService: Generated ${newInstances.length} new recurring bill instances.');
      }

      if (shouldClose) await db.close();
      return Future.value(true);
    } catch (e, stack) {
      logger.e('BackgroundService: Error executing task', error: e, stackTrace: stack);
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
