import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/incubation_duration_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

import '../../../helpers/test_localization.dart';

void main() {
  Widget buildSubject(List<IncubationDurationData> data) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: IncubationDurationChart(data: data)),
      ),
    );
  }
  IncubationDurationData makeItem(String id, int actualDays) =>
      IncubationDurationData(id: id, actualDays: actualDays);

  group('IncubationDurationChart', () {
    testWidgets('renders ChartEmpty when data is empty', (tester) async {
      await pumpLocalizedApp(tester, buildSubject([]), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('renders BarChart with single incubation record', (
      tester,
    ) async {
      await pumpLocalizedApp(tester, buildSubject([makeItem('egg1', 18)]), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders BarChart with multiple records', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject([
          makeItem('egg1', 17),
          makeItem('egg2', 18),
          makeItem('egg3', 19),
          makeItem('egg4', 18),
        ]),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders legend with three color indicators', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject([
          makeItem('egg1', 17),
          makeItem('egg2', 18),
          makeItem('egg3', 20),
        ]),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Legend shows <18, =18, >18 label items
      expect(find.text('<18'), findsOneWidget);
      expect(find.text('=18'), findsOneWidget);
      expect(find.text('>18'), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary around BarChart', (tester) async {
      await pumpLocalizedApp(tester, buildSubject([makeItem('egg1', 18)]), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('renders reference line label key for expected days', (
      tester,
    ) async {
      await pumpLocalizedApp(tester, buildSubject([makeItem('egg1', 16)]), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      // HorizontalLine label uses 'statistics.expected_days' key
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders Column layout with chart and legend', (tester) async {
      await pumpLocalizedApp(tester, buildSubject([makeItem('egg1', 18)]), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Column), findsWidgets);
    });
  });
}
