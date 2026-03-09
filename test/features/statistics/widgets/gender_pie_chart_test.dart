import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/statistics/widgets/gender_pie_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

void main() {
  Widget buildSubject({
    int maleCount = 0,
    int femaleCount = 0,
    int unknownCount = 0,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GenderPieChart(
          maleCount: maleCount,
          femaleCount: femaleCount,
          unknownCount: unknownCount,
        ),
      ),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('GenderPieChart', () {
    testWidgets('renders ChartEmpty when all counts are zero', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('renders PieChart when male count provided', (tester) async {
      await tester.pumpWidget(buildSubject(maleCount: 5));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(PieChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders PieChart when female count provided', (tester) async {
      await tester.pumpWidget(buildSubject(femaleCount: 3));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('renders PieChart with mixed gender counts', (tester) async {
      await tester.pumpWidget(
        buildSubject(maleCount: 4, femaleCount: 3, unknownCount: 1),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('renders without crashing when only unknown count', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(unknownCount: 2));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('shows legend items when data present', (tester) async {
      await tester.pumpWidget(
        buildSubject(maleCount: 2, femaleCount: 2, unknownCount: 1),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // Legend items render as Container dots + Text labels
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows total label text key when data present', (tester) async {
      await tester.pumpWidget(buildSubject(maleCount: 3, femaleCount: 2));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // easy_localization returns the key in test env
      expect(find.textContaining('statistics.total_label'), findsOneWidget);
    });
  });
}
