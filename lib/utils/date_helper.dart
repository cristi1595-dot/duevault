

class DateHelper {
  /// Calculates the next due date based on recurrence string.
  /// Handles end-of-month edge cases (e.g., Jan 31 -> Feb 28/29).
  /// [targetDay] allows keeping the same day even if a previous month clamped it (e.g. Feb 28 -> March 31).
  static DateTime calculateNextDueDate(DateTime current, String recurrence, {int? targetDay}) {
    if (recurrence == 'None') return current;

    if (recurrence == 'Weekly') {
      final next = current.add(const Duration(days: 7));
      return DateTime(next.year, next.month, next.day);
    }

    if (recurrence == 'Monthly') {
      // Logic for adding a month safely
      int nextYear = current.year;
      int nextMonth = current.month + 1;
      
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }

      // Use targetDay if provided, otherwise stick to current day
      final int rawNextDay = targetDay ?? current.day;
      
      // Check if the day exists in the next month
      final int lastDayOfNextMonth = _getLastDayOfMonth(nextYear, nextMonth);
      final int nextDay = rawNextDay > lastDayOfNextMonth ? lastDayOfNextMonth : rawNextDay;

      return DateTime(nextYear, nextMonth, nextDay);
    }

    if (recurrence == 'Yearly') {
      final int nextYear = current.year + 1;
      final int nextMonth = current.month;
      
      // Use targetDay if provided
      final int rawNextDay = targetDay ?? current.day;

      // Handle Feb 29 edge case
      final int lastDayOfNextMonth = _getLastDayOfMonth(nextYear, nextMonth);
      final int nextDay = rawNextDay > lastDayOfNextMonth ? lastDayOfNextMonth : rawNextDay;

      return DateTime(nextYear, nextMonth, nextDay);
    }

    return current;
  }

  static int _getLastDayOfMonth(int year, int month) {
    // Adding 0 as day to DateTime(year, month + 1, 0) gives the last day of the previous month (which is our target month)
    return DateTime(year, month + 1, 0).day;
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
