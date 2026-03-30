import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/color_mutation_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

import '../../../helpers/test_localization.dart';

void main() {
  Widget buildSubject(Map<BirdColor, int> data) {
    return MaterialApp(
      home: Scaffold(body: ColorMutationChart(data: data)),
    );
  }
  group('ColorMutationChart', () {
    testWidgets('renders ChartEmpty when data map is empty', (tester) async {
      await pumpLocalizedApp(tester, buildSubject({}), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('renders ChartEmpty when all counts are zero', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject({
          BirdColor.green: 0,
          BirdColor.blue: 0,
          BirdColor.yellow: 0,
        }),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ChartEmpty), findsOneWidget);
    });

    testWidgets('renders BarChart with single color mutation', (tester) async {
      await pumpLocalizedApp(tester, buildSubject({BirdColor.green: 5}), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders BarChart with multiple color mutations', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        buildSubject({
          BirdColor.green: 8,
          BirdColor.blue: 5,
          BirdColor.yellow: 3,
          BirdColor.white: 2,
          BirdColor.lutino: 1,
        }),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders BarChart filtering out zero-count mutations', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        buildSubject({
          BirdColor.green: 4,
          BirdColor.blue: 0,
          BirdColor.yellow: 2,
          BirdColor.white: 0,
        }),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Only green and yellow have non-zero counts
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary around BarChart', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject({BirdColor.blue: 3, BirdColor.green: 7}),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('chart is wrapped in SizedBox with height 200', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject({BirdColor.green: 4, BirdColor.blue: 6}),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
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
      await pumpLocalizedApp(tester,
        buildSubject({
          BirdColor.green: 5,
          BirdColor.blue: 3,
          BirdColor.lutino: 2,
        }),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      // easy_localization returns key strings in test env
      expect(find.text(l10n('statistics.color_short_green')), findsOneWidget);
      expect(find.text(l10n('statistics.color_short_blue')), findsOneWidget);
      expect(find.text(l10n('statistics.color_short_lutino')), findsOneWidget);
    });

    testWidgets('renders with all BirdColor values populated', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject({for (final c in BirdColor.values) c: 1}),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders with large count values', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject({
          BirdColor.green: 150,
          BirdColor.blue: 200,
          BirdColor.yellow: 75,
          BirdColor.cinnamon: 100,
          BirdColor.opaline: 50,
        }),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}
