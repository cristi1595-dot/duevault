import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/utils/date_helper.dart';

void main() {
  group('DateHelper.calculateNextDueDate', () {
    test('Weekly recurrence adds 7 days', () {
      final initialDate = DateTime(2024, 1, 1); // Monday
      final nextDate = DateHelper.calculateNextDueDate(initialDate, 'Weekly');
      expect(nextDate, DateTime(2024, 1, 8));
    });

    test('Monthly recurrence adds 1 month', () {
      final initialDate = DateTime(2024, 1, 15);
      final nextDate = DateHelper.calculateNextDueDate(initialDate, 'Monthly');
      expect(nextDate, DateTime(2024, 2, 15));
    });

    test('Monthly recurrence handles end of month (Jan 31 -> Feb 29 in leap year)', () {
      final initialDate = DateTime(2024, 1, 31);
      final nextDate = DateHelper.calculateNextDueDate(initialDate, 'Monthly');
      expect(nextDate, DateTime(2024, 2, 29));
    });

    test('Monthly recurrence handles end of month (Jan 31 -> Feb 28 in non-leap year)', () {
      final initialDate = DateTime(2023, 1, 31);
      final nextDate = DateHelper.calculateNextDueDate(initialDate, 'Monthly');
      expect(nextDate, DateTime(2023, 2, 28));
    });

    test('Yearly recurrence adds 1 year', () {
      final initialDate = DateTime(2024, 1, 1);
      final nextDate = DateHelper.calculateNextDueDate(initialDate, 'Yearly');
      expect(nextDate, DateTime(2025, 1, 1));
    });

    test('Yearly recurrence handles Feb 29 edge case', () {
      final initialDate = DateTime(2024, 2, 29);
      final nextDate = DateHelper.calculateNextDueDate(initialDate, 'Yearly');
      expect(nextDate, DateTime(2025, 2, 28));
    });

    test('None recurrence returns same date', () {
      final initialDate = DateTime(2024, 1, 1);
      final nextDate = DateHelper.calculateNextDueDate(initialDate, 'None');
      expect(nextDate, initialDate);
    });
  });
}
