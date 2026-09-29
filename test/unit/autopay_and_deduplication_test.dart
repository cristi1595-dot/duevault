import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/utils/date_helper.dart';

void main() {
  group('Deduplication Logic Tests', () {
    test('Identifies and groups semantic duplicates correctly', () {
      final dueDate = DateTime(2026, 9, 26);
      final item1 = VaultItem()
        ..id = 1
        ..ownerId = 'user_1'
        ..title = 'Rata Masina'
        ..itemType = 'Bill'
        ..amount = 300.0
        ..dueDate = dueDate
        ..recurrence = 'Monthly'
        ..wasSynced = true;

      final item2 = VaultItem()
        ..id = 2
        ..ownerId = 'user_1'
        ..title = 'Rata masina'
        ..itemType = 'Bill'
        ..amount = 300.0
        ..dueDate = dueDate
        ..recurrence = 'Monthly'
        ..wasSynced = false;

      String createSignature(VaultItem item) {
        final normTitle = item.title.trim().toLowerCase();
        final type = item.itemType ?? 'Bill';
        final dueStr = item.dueDate != null
            ? '${item.dueDate!.year}-${item.dueDate!.month.toString().padLeft(2, '0')}-${item.dueDate!.day.toString().padLeft(2, '0')}'
            : 'no_date';
        final amtStr = item.amount != null ? item.amount!.toStringAsFixed(2) : 'no_amt';
        return '$normTitle|$type|$dueStr|$amtStr';
      }

      final sig1 = createSignature(item1);
      final sig2 = createSignature(item2);

      expect(sig1, equals(sig2));
      expect(sig1, equals('rata masina|Bill|2026-09-26|300.00'));
    });

    test('Prefers synced items and items with attachments when sorting duplicates', () {
      final itemA = VaultItem()
        ..id = 10
        ..title = 'Rent'
        ..attachedFiles = []
        ..wasSynced = false
        ..lastModified = DateTime(2026, 9, 1);

      final itemB = VaultItem()
        ..id = 11
        ..title = 'Rent'
        ..attachedFiles = ['receipt.pdf']
        ..wasSynced = true
        ..lastModified = DateTime(2026, 9, 2);

      final list = [itemA, itemB];
      list.sort((a, b) {
        final aHasFiles = a.attachedFiles.isNotEmpty ? 1 : 0;
        final bHasFiles = b.attachedFiles.isNotEmpty ? 1 : 0;
        if (aHasFiles != bHasFiles) return bHasFiles.compareTo(aHasFiles);

        final aSynced = a.wasSynced ? 1 : 0;
        final bSynced = b.wasSynced ? 1 : 0;
        if (aSynced != bSynced) return bSynced.compareTo(aSynced);

        return b.lastModified.compareTo(a.lastModified);
      });

      expect(list.first.id, equals(11));
      expect(list.first.attachedFiles, isNotEmpty);
    });
  });

  group('Autopay & Date Rollover Logic Tests', () {
    test('Calculates next cycle for monthly autopay bills', () {
      final augustBill = DateTime(2026, 8, 26);
      final next = DateHelper.calculateNextDueDate(augustBill, 'Monthly', targetDay: 26);

      expect(next.year, equals(2026));
      expect(next.month, equals(9));
      expect(next.day, equals(26));
    });

    test('Advances past-due recurring dates to upcoming cycle', () {
      final pastDate = DateTime(2026, 1, 15);
      final today = DateTime(2026, 9, 28);

      DateTime current = pastDate;
      while (current.isBefore(today)) {
        final advanced = DateHelper.calculateNextDueDate(current, 'Monthly', targetDay: 15);
        if (advanced.isAfter(current)) {
          current = advanced;
        } else {
          break;
        }
      }

      expect(current.isAfter(today) || current.isAtSameMomentAs(today), isTrue);
      expect(current.day, equals(15));
      expect(current.month, equals(10)); // Next is Oct 15, 2026
    });

    test('Autopay bills in future are not marked paid, while past/today are marked paid', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final futureDue = today.add(const Duration(days: 10));
      final pastDue = today.subtract(const Duration(days: 2));

      bool isDuePassed(DateTime due) {
        final dayOnly = DateTime(due.year, due.month, due.day);
        return dayOnly.isBefore(today) || dayOnly.isAtSameMomentAs(today);
      }

      expect(isDuePassed(futureDue), isFalse);
      expect(isDuePassed(pastDue), isTrue);
      expect(isDuePassed(today), isTrue);
    });
  });
}
