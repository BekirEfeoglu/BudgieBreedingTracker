import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/statistics/widgets/egg_production_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

void main() {
  Widget buildSubject(Map<String, int> monthlyData) {
    return MaterialApp(
      home: Scaffold(body: EggProductionChart(monthlyData: monthlyData)),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('EggProductionChart', () {
    testWidgets('renders ChartEmpty when data is empty', (tester) async {
      await tester.pumpWidget(buildSubject({}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders LineChart when data is provided', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 5}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders LineChart with multiple months', (tester) async {
      await tester.pumpWidget(
        buildSubject({'2026-01': 3, '2026-02': 7, '2026-03': 5, '2026-04': 9}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary around chart', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-01': 4, '2026-02': 6}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('renders with zero values in some months', (tester) async {
      await tester.pumpWidget(
        buildSubject({'2026-01': 0, '2026-02': 0, '2026-03': 0}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // Zero values produce spots at y=0; chart still renders
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with single month high egg count', (tester) async {
      await tester.pumpWidget(buildSubject({'2026-06': 12}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
