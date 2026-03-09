import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/statistics/widgets/age_distribution_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

void main() {
  Widget buildSubject(Map<String, int> data) {
    return MaterialApp(
      home: Scaffold(body: AgeDistributionChart(data: data)),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('AgeDistributionChart', () {
    testWidgets('renders ChartEmpty when all counts are zero', (tester) async {
      await tester.pumpWidget(
        buildSubject({'0-6m': 0, '6-12m': 0, '1-2y': 0, '2-3y': 0, '3+y': 0}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('renders ChartEmpty when data map is empty', (tester) async {
      await tester.pumpWidget(buildSubject({}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
    });

    testWidgets('renders BarChart when at least one age group has data', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject({'0-6m': 5, '6-12m': 0, '1-2y': 0, '2-3y': 0, '3+y': 0}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders BarChart with full age distribution', (tester) async {
      await tester.pumpWidget(
        buildSubject({'0-6m': 3, '6-12m': 5, '1-2y': 4, '2-3y': 2, '3+y': 1}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders with only oldest age group populated', (tester) async {
      await tester.pumpWidget(
        buildSubject({'0-6m': 0, '6-12m': 0, '1-2y': 0, '2-3y': 0, '3+y': 7}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary around chart', (tester) async {
      await tester.pumpWidget(
        buildSubject({'0-6m': 2, '6-12m': 3, '1-2y': 1, '2-3y': 0, '3+y': 0}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(RepaintBoundary), findsWidgets);
    });
  });
}
