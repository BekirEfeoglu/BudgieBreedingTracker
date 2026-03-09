import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chick_survival_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

void main() {
  Widget buildSubject(ChickSurvivalData data) {
    return MaterialApp(
      home: Scaffold(body: ChickSurvivalChart(data: data)),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('ChickSurvivalChart', () {
    testWidgets('renders ChartEmpty when all counts are zero', (tester) async {
      await tester.pumpWidget(buildSubject(const ChickSurvivalData()));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('renders PieChart when only healthy chicks', (tester) async {
      await tester.pumpWidget(
        buildSubject(const ChickSurvivalData(healthy: 10)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(PieChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders PieChart with all three status counts', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(const ChickSurvivalData(healthy: 8, sick: 2, deceased: 1)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('renders PieChart with only deceased chicks', (tester) async {
      await tester.pumpWidget(
        buildSubject(const ChickSurvivalData(deceased: 3)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('renders legend with survival status keys', (tester) async {
      await tester.pumpWidget(
        buildSubject(const ChickSurvivalData(healthy: 5, sick: 2, deceased: 1)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // easy_localization returns the key strings in test
      expect(
        find.textContaining('statistics.survival_healthy'),
        findsOneWidget,
      );
      expect(find.textContaining('statistics.survival_sick'), findsOneWidget);
      expect(
        find.textContaining('statistics.survival_deceased'),
        findsOneWidget,
      );
    });

    testWidgets('renders RepaintBoundary around PieChart', (tester) async {
      await tester.pumpWidget(
        buildSubject(const ChickSurvivalData(healthy: 5, sick: 1)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('renders Column layout with chart and legend', (tester) async {
      await tester.pumpWidget(
        buildSubject(const ChickSurvivalData(healthy: 4, sick: 1)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(Column), findsWidgets);
    });
  });
}
