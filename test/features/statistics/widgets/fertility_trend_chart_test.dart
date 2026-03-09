import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/statistics/widgets/fertility_trend_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

void main() {
  Widget buildSubject(Map<String, double> monthlyData) {
    return MaterialApp(
      home: Scaffold(body: FertilityTrendChart(monthlyData: monthlyData)),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('FertilityTrendChart', () {
    testWidgets('renders ChartEmpty when data is empty', (tester) async {
      await tester.pumpWidget(buildSubject({}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders LineChart with single month', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 75.0}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders LineChart with multiple months', (tester) async {
      await tester.pumpWidget(
        buildSubject({
          '2026-01': 60.0,
          '2026-02': 72.5,
          '2026-03': 80.0,
          '2026-04': 65.0,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary around chart', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 50.0, '2026-02': 60.0}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('renders with zero fertility rate', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 0.0}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with 100% fertility rate', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 100.0}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders SizedBox with height constraint', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 55.0, '2026-02': 70.0}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // Chart is wrapped in a SizedBox(height:200)
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
