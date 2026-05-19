import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart';

void main() {
  group('DateUtils.dayDiff', () {
    test('returns 0 for the same calendar day at different times', () {
      final start = DateTime(2024, 1, 10, 8, 0);
      final end = DateTime(2024, 1, 10, 22, 0);
      expect(DateUtils.dayDiff(start, end), 0);
    });

    test('returns 1 across midnight even when wall clock < 24h apart', () {
      final start = DateTime(2024, 1, 10, 23, 30);
      final end = DateTime(2024, 1, 11, 0, 30);
      expect(DateUtils.dayDiff(start, end), 1);
    });

    test('returns 1 across spring-forward DST boundary (23h wall clock)', () {
      // US spring-forward 2024: March 10, 02:00 -> 03:00
      // Naive .difference().inDays would return 0 because the wall-clock
      // diff is only 23h00m, but two calendar days have elapsed.
      final start = DateTime(2024, 3, 9, 12, 0);
      final end = DateTime(2024, 3, 10, 12, 0);
      expect(DateUtils.dayDiff(start, end), 1);
    });

    test('returns 18 for a standard 18-day incubation period', () {
      final layDate = DateTime(2024, 5, 1, 9, 0);
      final hatchDate = DateTime(2024, 5, 19, 14, 0);
      expect(DateUtils.dayDiff(layDate, hatchDate), 18);
    });

    test('returns negative when end precedes start', () {
      final start = DateTime(2024, 5, 19);
      final end = DateTime(2024, 5, 17);
      expect(DateUtils.dayDiff(start, end), -2);
    });

    test('ignores time component on both sides', () {
      final start = DateTime(2024, 5, 1, 23, 59, 59);
      final end = DateTime(2024, 5, 4, 0, 0, 1);
      expect(DateUtils.dayDiff(start, end), 3);
    });
  });
}
