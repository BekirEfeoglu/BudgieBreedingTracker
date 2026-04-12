import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/statistics/widgets/fertility_trend_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

import '../../../helpers/test_localization.dart';

void main() {
  Widget buildSubject(Map<String, double> monthlyData) {
    return MaterialApp(
      home: Scaffold(body: FertilityTrendChart(monthlyData: monthlyData)),
    );
  }
  group('FertilityTrendChart', () {
    testWidgets('renders ChartEmpty when data is empty', (tester) async {
      await pumpLocalizedApp(tester, buildSubject({}), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders LineChart with single month', (tester) async {
      await pumpLocalizedApp(tester, buildSubject({'2026-01': 75.0}), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders LineChart with multiple months', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject({
          '2026-01': 60.0,
          '2026-02': 72.5,
          '2026-03': 80.0,
          '2026-04': 65.0,
        }),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary around chart', (tester) async {
      await pumpLocalizedApp(tester, buildSubject({'2026-01': 50.0, '2026-02': 60.0}), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('renders with zero fertility rate', (tester) async {
      await pumpLocalizedApp(tester, buildSubject({'2026-01': 0.0}), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders with 100% fertility rate', (tester) async {
      await pumpLocalizedApp(tester, buildSubject({'2026-01': 100.0}), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders SizedBox with height constraint', (tester) async {
      await pumpLocalizedApp(tester, buildSubject({'2026-01': 55.0, '2026-02': 70.0}), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      // Chart is wrapped in a SizedBox(height:200)
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
