import 'package:intl/intl.dart';

class WeeklyDateRange {
  const WeeklyDateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  String format(String locale) {
    final startFormat = DateFormat('d MMM', locale);
    final endFormat = DateFormat('d MMM', locale);
    return '${startFormat.format(start)} - ${endFormat.format(end)}';
  }

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }
}

abstract final class DateTimeUtils {
  /// Returns the Monday 00:00:00 -> Sunday 23:59:59.999 range for a given date.
  static WeeklyDateRange getWeekRange(DateTime date) {
    // In Dart DateTime, Monday is 1 and Sunday is 7.
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - DateTime.monday));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
    return WeeklyDateRange(start: monday, end: sunday);
  }

  /// Returns This Week range (Monday to Sunday containing today).
  static WeeklyDateRange getThisWeekRange() {
    return getWeekRange(DateTime.now());
  }

  /// Returns Previous Week range (Monday to Sunday 7 days prior).
  static WeeklyDateRange getPreviousWeekRange() {
    final thisWeekMonday = getThisWeekRange().start;
    final prevWeekDate = thisWeekMonday.subtract(const Duration(days: 1));
    return getWeekRange(prevWeekDate);
  }

  /// Returns Next Week range (Monday to Sunday 7 days ahead).
  static WeeklyDateRange getNextWeekRange() {
    final thisWeekSunday = getThisWeekRange().end;
    final nextWeekDate = thisWeekSunday.add(const Duration(days: 1));
    return getWeekRange(nextWeekDate);
  }
}
