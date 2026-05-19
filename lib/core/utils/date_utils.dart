/// Date math utilities that normalize across DST and timezone boundaries.
///
/// All day-count math (incubation day, age, "overdue by N days") MUST go
/// through these helpers — naive `DateTime.difference(...).inDays` returns 0
/// when the difference is 23h59m across a DST boundary, breaking critical
/// breeding milestone math.
abstract final class DateUtils {
  /// Returns the integer day difference between two dates, normalized to UTC
  /// midnight so DST transitions and time-of-day variance do not affect the
  /// result.
  ///
  /// Example: a lay date at 23:30 local and "now" at 00:30 the next day
  /// produces 1, not 0.
  static int dayDiff(DateTime start, DateTime end) {
    final s = DateTime.utc(start.year, start.month, start.day);
    final e = DateTime.utc(end.year, end.month, end.day);
    return e.difference(s).inDays;
  }
}
