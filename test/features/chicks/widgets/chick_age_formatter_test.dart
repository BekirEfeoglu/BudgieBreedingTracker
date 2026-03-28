import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_age_formatter.dart';

void main() {
  // Initialize EasyLocalization with a dummy loader so .tr() returns raw keys.
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  group('formatChickAge', () {
    test('returns days-only key when weeks is 0', () {
      final result = formatChickAge((weeks: 0, days: 5, totalDays: 5));

      // With no asset loader in pure unit test, .tr() returns the raw key.
      // The function uses 'chicks.age_days_only' key with args.
      expect(result, contains('chicks.age_days_only'));
    });

    test('returns weeks-and-days key when weeks > 0', () {
      final result = formatChickAge((weeks: 2, days: 3, totalDays: 17));

      expect(result, contains('chicks.age_weeks_days'));
    });

    test('returns short days-only key when short is true and weeks is 0', () {
      final result = formatChickAge(
        (weeks: 0, days: 3, totalDays: 3),
        short: true,
      );

      expect(result, contains('chicks.age_days_only_short'));
    });

    test('returns short weeks-days key when short is true and weeks > 0', () {
      final result = formatChickAge(
        (weeks: 1, days: 2, totalDays: 9),
        short: true,
      );

      expect(result, contains('chicks.age_weeks_days_short'));
    });

    test('handles zero total days', () {
      final result = formatChickAge((weeks: 0, days: 0, totalDays: 0));

      expect(result, contains('chicks.age_days_only'));
    });

    test('handles exact week boundary (e.g. 2 weeks, 0 days)', () {
      final result = formatChickAge((weeks: 2, days: 0, totalDays: 14));

      expect(result, contains('chicks.age_weeks_days'));
    });
  });
}
