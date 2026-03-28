import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/stats_period_selector.dart';

void main() {
  group('StatsPeriodSelector', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: StatsPeriodSelector())),
        ),
      );
      await tester.pump();

      expect(find.byType(StatsPeriodSelector), findsOneWidget);
    });

    testWidgets('renders SegmentedButton', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: StatsPeriodSelector())),
        ),
      );
      await tester.pump();

      expect(find.byType(SegmentedButton<StatsPeriod>), findsOneWidget);
    });

    testWidgets('shows period label for 3 months', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: StatsPeriodSelector())),
        ),
      );
      await tester.pump();

      // L10n keys appear as literal strings in test environment
      expect(find.text('statistics.period_3_months'), findsOneWidget);
    });

    testWidgets('shows period label for 6 months', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: StatsPeriodSelector())),
        ),
      );
      await tester.pump();

      expect(find.text('statistics.period_6_months'), findsOneWidget);
    });

    testWidgets('shows period label for 12 months', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: StatsPeriodSelector())),
        ),
      );
      await tester.pump();

      expect(find.text('statistics.period_12_months'), findsOneWidget);
    });

    testWidgets('tapping 12-month segment updates provider', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(body: StatsPeriodSelector()),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Tap the 12-month segment
      await tester.tap(find.text('statistics.period_12_months'));
      await tester.pump();

      expect(container.read(statsPeriodProvider), StatsPeriod.twelveMonths);
    });
  });

  group('StatsPeriodNotifier persistence', () {
    test('setPeriod saves to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(statsPeriodProvider.notifier).setPeriod(
        StatsPeriod.twelveMonths,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppPreferences.keyStatsPeriod),
        'twelveMonths',
      );
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
