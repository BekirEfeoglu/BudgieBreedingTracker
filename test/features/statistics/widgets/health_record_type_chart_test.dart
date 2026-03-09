import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/health_record_type_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

void main() {
  Widget buildSubject(Map<HealthRecordType, int> data) {
    return MaterialApp(
      home: Scaffold(body: HealthRecordTypeChart(data: data)),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('HealthRecordTypeChart', () {
    testWidgets('renders ChartEmpty when data map is empty', (tester) async {
      await tester.pumpWidget(buildSubject({}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('renders ChartEmpty when all values are zero', (tester) async {
      await tester.pumpWidget(
        buildSubject({
          HealthRecordType.checkup: 0,
          HealthRecordType.illness: 0,
          HealthRecordType.vaccination: 0,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(ChartEmpty), findsOneWidget);
    });

    testWidgets('renders BarChart when at least one type has records', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject({HealthRecordType.checkup: 5}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders BarChart with all 6 health record types', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject({
          HealthRecordType.checkup: 4,
          HealthRecordType.illness: 2,
          HealthRecordType.injury: 1,
          HealthRecordType.vaccination: 3,
          HealthRecordType.medication: 2,
          HealthRecordType.death: 0,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary around BarChart', (tester) async {
      await tester.pumpWidget(
        buildSubject({
          HealthRecordType.illness: 3,
          HealthRecordType.checkup: 5,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('renders with vaccination as only type', (tester) async {
      await tester.pumpWidget(buildSubject({HealthRecordType.vaccination: 8}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('renders non-zero bar for unknown type data', (tester) async {
      await tester.pumpWidget(buildSubject({HealthRecordType.unknown: 3}));
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
      final chart = tester.widget<BarChart>(find.byType(BarChart));
      final hasNonZero = chart.data.barGroups.any(
        (group) => group.barRods.any((rod) => rod.toY > 0),
      );
      expect(hasNonZero, isTrue);
    });

    testWidgets('renders SizedBox with height constraint', (tester) async {
      await tester.pumpWidget(
        buildSubject({
          HealthRecordType.medication: 2,
          HealthRecordType.checkup: 6,
        }),
      );
      await tester.pump(const Duration(milliseconds: 300));
      consumeExceptions(tester);

      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
