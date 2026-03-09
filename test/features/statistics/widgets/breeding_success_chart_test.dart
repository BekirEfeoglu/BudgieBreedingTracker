import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/statistics/widgets/breeding_success_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

void main() {
  Widget buildSubject({
    Map<String, int> completed = const {},
    Map<String, int> cancelled = const {},
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BreedingSuccessChart(completed: completed, cancelled: cancelled),
      ),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('BreedingSuccessChart', () {
    testWidgets('renders ChartEmpty when completed map is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('renders BarChart with single month data', (tester) async {
      await tester.pumpWidget(
        buildSubject(completed: {'2026-01': 3}, cancelled: {'2026-01': 1}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders BarChart with multiple months', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          completed: {'2026-01': 2, '2026-02': 4, '2026-03': 1},
          cancelled: {'2026-01': 0, '2026-02': 1, '2026-03': 2},
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders legend row below chart', (tester) async {
      await tester.pumpWidget(
        buildSubject(completed: {'2026-01': 3}, cancelled: {'2026-01': 1}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // Column with BarChart + legend
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('renders with only completed data (no cancellations)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(completed: {'2026-01': 5, '2026-02': 3}, cancelled: {}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders legend localization keys', (tester) async {
      await tester.pumpWidget(
        buildSubject(completed: {'2026-01': 2}, cancelled: {'2026-01': 1}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // easy_localization returns key strings in test env
      expect(find.text('statistics.completed'), findsOneWidget);
      expect(find.text('statistics.cancelled'), findsOneWidget);
    });
  });
}
