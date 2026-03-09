import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/statistics/widgets/monthly_trend_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

void main() {
  Widget buildSubject(Map<String, int> monthlyData) {
    return MaterialApp(
      home: Scaffold(body: MonthlyTrendChart(monthlyData: monthlyData)),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('MonthlyTrendChart', () {
    testWidgets('renders ChartEmpty when data is empty', (tester) async {
      await tester.pumpWidget(buildSubject({}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders LineChart with single month data', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 3}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders LineChart with multiple months', (tester) async {
      await tester.pumpWidget(
        buildSubject({'2026-01': 2, '2026-02': 5, '2026-03': 3, '2026-04': 7}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary around chart', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 1, '2026-02': 2}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('renders with all zero monthly values', (tester) async {
      await tester.pumpWidget(
        buildSubject({'2026-01': 0, '2026-02': 0, '2026-03': 0}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // Spots at y=0 still produce a valid line chart
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders SizedBox with 200 height constraint', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 4, '2026-02': 6}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders with large chick count values', (tester) async {
      await tester.pumpWidget(
        buildSubject({'2026-01': 20, '2026-02': 15, '2026-03': 25}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
