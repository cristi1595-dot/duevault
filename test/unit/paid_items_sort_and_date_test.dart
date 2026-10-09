import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/models/vault_item.dart';

int compareClosestToFarthest(DateTime? a, DateTime? b, DateTime today) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;

  final aDay = DateTime(a.year, a.month, a.day);
  final bDay = DateTime(b.year, b.month, b.day);

  final aDiff = aDay.difference(today).inDays;
  final bDiff = bDay.difference(today).inDays;

  // Both upcoming (>= 0): closest upcoming date first (e.g. +2 before +24)
  if (aDiff >= 0 && bDiff >= 0) {
    return aDiff.compareTo(bDiff);
  }
  // Both in past (< 0): closest past date to today first (e.g. -1 before -30)
  if (aDiff < 0 && bDiff < 0) {
    return bDiff.compareTo(aDiff);
  }
  // Upcoming before past
  return aDiff >= 0 ? -1 : 1;
}

void main() {
  group('Paid items sorting (closest to farthest)', () {
    final today = DateTime(2026, 10, 9);

    test('sorts upcoming paid items from soonest to farthest date', () {
      final itemSoon = VaultItem()
        ..title = 'Electric'
        ..dueDate = DateTime(2026, 10, 11) // +2 days
        ..isPaid = true;

      final itemMedium = VaultItem()
        ..title = 'Internet'
        ..dueDate = DateTime(2026, 10, 14) // +5 days
        ..isPaid = true;

      final itemFar = VaultItem()
        ..title = 'Spotify'
        ..dueDate = DateTime(2026, 11, 2) // +24 days
        ..isPaid = true;

      final list = [itemFar, itemSoon, itemMedium];
      list.sort((a, b) => compareClosestToFarthest(a.dueDate, b.dueDate, today));

      expect(list.map((i) => i.title).toList(), ['Electric', 'Internet', 'Spotify']);
    });

    test('sorts past paid items from closest (most recent) to oldest date', () {
      final itemYesterday = VaultItem()
        ..title = 'Water'
        ..dueDate = DateTime(2026, 10, 8) // -1 day
        ..isPaid = true;

      final itemLastWeek = VaultItem()
        ..title = 'Gas'
        ..dueDate = DateTime(2026, 10, 2) // -7 days
        ..isPaid = true;

      final itemLastMonth = VaultItem()
        ..title = 'Old'
        ..dueDate = DateTime(2026, 9, 9) // -30 days
        ..isPaid = true;

      final list = [itemLastMonth, itemYesterday, itemLastWeek];
      list.sort((a, b) => compareClosestToFarthest(a.dueDate, b.dueDate, today));

      expect(list.map((i) => i.title).toList(), ['Water', 'Gas', 'Old']);
    });

    test('places null due dates at the end', () {
      final itemWithDate = VaultItem()
        ..title = 'Bill with date'
        ..dueDate = DateTime(2026, 10, 15)
        ..isPaid = true;

      final itemNoDate = VaultItem()
        ..title = 'Bill no date'
        ..dueDate = null
        ..isPaid = true;

      final list = [itemNoDate, itemWithDate];
      list.sort((a, b) => compareClosestToFarthest(a.dueDate, b.dueDate, today));

      expect(list.first.title, 'Bill with date');
      expect(list.last.title, 'Bill no date');
    });
  });
}
