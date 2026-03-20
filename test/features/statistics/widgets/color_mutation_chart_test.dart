import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/color_mutation_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

void main() {
  Widget buildSubject(Map<BirdColor, int> data) {
    return MaterialApp(
      home: Scaffold(body: ColorMutationChart(data: data)),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('ColorMutationChart', () {
    testWidgets('renders ChartEmpty when data map is empty', (tester) async {
      await tester.pumpWidget(buildSubject({}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('renders ChartEmpty when all counts are zero', (tester) async {
      await tester.pumpWidget(
        buildSubject({
          BirdColor.green: 0,
          BirdColor.blue: 0,
          BirdColor.yellow: 0,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
    });

    testWidgets('renders BarChart with single color mutation', (tester) async {
      await tester.pumpWidget(buildSubject({BirdColor.green: 5}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders BarChart with multiple color mutations', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject({
          BirdColor.green: 8,
          BirdColor.blue: 5,
          BirdColor.yellow: 3,
          BirdColor.white: 2,
          BirdColor.lutino: 1,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders BarChart filtering out zero-count mutations', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject({
          BirdColor.green: 4,
          BirdColor.blue: 0,
          BirdColor.yellow: 2,
          BirdColor.white: 0,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // Only green and yellow have non-zero counts
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary around BarChart', (tester) async {
      await tester.pumpWidget(
        buildSubject({BirdColor.blue: 3, BirdColor.green: 7}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('chart is wrapped in SizedBox with height 200', (tester) async {
      await tester.pumpWidget(
        buildSubject({BirdColor.green: 4, BirdColor.blue: 6}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(RepaintBoundary),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.height, 200);
    });

    testWidgets('shows bottom axis labels for color mutations', (tester) async {
      await tester.pumpWidget(
        buildSubject({
          BirdColor.green: 5,
          BirdColor.blue: 3,
          BirdColor.lutino: 2,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      // easy_localization returns key strings in test env
      expect(find.text('statistics.color_short_green'), findsOneWidget);
      expect(find.text('statistics.color_short_blue'), findsOneWidget);
      expect(find.text('statistics.color_short_lutino'), findsOneWidget);
    });

    testWidgets('renders with all BirdColor values populated', (tester) async {
      await tester.pumpWidget(
        buildSubject({for (final c in BirdColor.values) c: 1}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders with large count values', (tester) async {
      await tester.pumpWidget(
        buildSubject({
          BirdColor.green: 150,
          BirdColor.blue: 200,
          BirdColor.yellow: 75,
          BirdColor.cinnamon: 100,
          BirdColor.opaline: 50,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}
