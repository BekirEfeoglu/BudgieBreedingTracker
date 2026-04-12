import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/stats_period_selector.dart';

import '../../../helpers/test_localization.dart';

Future<void> _pumpSelector(WidgetTester tester, {Widget? child}) {
  return pumpTranslatedApp(
    tester,
    ProviderScope(
      child:
          child ??
          const MaterialApp(home: Scaffold(body: StatsPeriodSelector())),
    ),
  );
}

SegmentedButton<StatsPeriod> _selector(WidgetTester tester) {
  return tester.widget<SegmentedButton<StatsPeriod>>(
    find.byType(SegmentedButton<StatsPeriod>),
  );
}

void main() {
  group('StatsPeriodSelector', () {
    testWidgets('renders selector shell', (tester) async {
      await _pumpSelector(tester);

      expect(find.byType(StatsPeriodSelector), findsOneWidget);
      expect(find.byType(SegmentedButton<StatsPeriod>), findsOneWidget);
    });

    testWidgets('tapping 12-month segment updates provider', (tester) async {
      late ProviderContainer container;

      await _pumpSelector(
        tester,
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(
              home: Scaffold(body: StatsPeriodSelector()),
            );
          },
        ),
      );

      final selector = _selector(tester);
      selector.onSelectionChanged!({StatsPeriod.twelveMonths});

      expect(container.read(statsPeriodProvider), StatsPeriod.twelveMonths);
    });
  });

  group('StatsPeriodNotifier persistence', () {
    test('setPeriod saves to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(statsPeriodProvider.notifier)
          .setPeriod(StatsPeriod.twelveMonths);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppPreferences.keyStatsPeriod), 'twelveMonths');
    });

    test('build loads saved period from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyStatsPeriod: 'threeMonths',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default is sixMonths, but after async load it should be threeMonths
      expect(container.read(statsPeriodProvider), StatsPeriod.sixMonths);

      // Wait for _loadFromPrefs to complete
      await Future<void>.delayed(Duration.zero);

      expect(container.read(statsPeriodProvider), StatsPeriod.threeMonths);
    });

    test('build falls back to sixMonths for invalid saved value', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyStatsPeriod: 'invalidValue',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(statsPeriodProvider), StatsPeriod.sixMonths);
    });

    test('build falls back to sixMonths when no saved value', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(statsPeriodProvider), StatsPeriod.sixMonths);
    });
  });

  group('StatsPeriod enum', () {
    test('threeMonths has monthCount of 3', () {
      expect(StatsPeriod.threeMonths.monthCount, 3);
    });

    test('sixMonths has monthCount of 6', () {
      expect(StatsPeriod.sixMonths.monthCount, 6);
    });

    test('twelveMonths has monthCount of 12', () {
      expect(StatsPeriod.twelveMonths.monthCount, 12);
    });
  });
}
