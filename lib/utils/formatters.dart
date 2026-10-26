import 'package:intl/intl.dart';

class Formatters {
  /// Money format strictly English: e.g., "50,000 TK" or "50,000 Taka"
  static String formatMoney(double amount, {bool short = false}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final formatted = formatter.format(amount.round());
    return short ? '$formatted TK' : '$formatted Taka';
  }

  /// Bangladesh 12H Format e.g., "12 May 2026, 09:41 AM"
  static String formatDateTimeBD(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a', 'en_US').format(dt);
  }

  /// Format Date only e.g., "12 May 2026"
  static String formatDateBD(DateTime dt) {
    return DateFormat('dd MMM yyyy', 'en_US').format(dt);
  }

  /// Format Time only e.g., "09:41 AM"
  static String formatTimeBD(DateTime dt) {
    return DateFormat('hh:mm a', 'en_US').format(dt);
  }

  /// Format Month Key e.g., "2026-03"
  static String getMonthKey(DateTime dt) {
    return DateFormat('yyyy-MM').format(dt);
  }

  /// Get Week start (Sunday) for a given date
  static DateTime getStartOfWeek(DateTime date) {
    // Week starts on Sunday in BD per requirements
    int daysToSubtract = date.weekday % 7; // Sunday = 7 -> 0, Mon = 1 -> 1, ... Sat = 6 -> 6
    final start = DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
    return start;
  }

  /// Get Week end (Saturday)
  static DateTime getEndOfWeek(DateTime date) {
    final start = getStartOfWeek(date);
    return start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }
}
