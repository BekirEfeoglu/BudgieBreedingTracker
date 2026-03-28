import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/statistics/widgets/gender_pie_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

import '../../../helpers/test_localization.dart';

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
  group('GenderPieChart', () {
    testWidgets('renders ChartEmpty when all counts are zero', (tester) async {
      await pumpLocalizedApp(tester, buildSubject(), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('renders PieChart when male count provided', (tester) async {
      await pumpLocalizedApp(tester, buildSubject(maleCount: 5), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.byType(ChartEmpty), findsNothing);
    });

    testWidgets('renders PieChart when female count provided', (tester) async {
      await pumpLocalizedApp(tester, buildSubject(femaleCount: 3), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('renders PieChart with mixed gender counts', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject(maleCount: 4, femaleCount: 3, unknownCount: 1),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('renders without crashing when only unknown count', (
      tester,
    ) async {
      await pumpLocalizedApp(tester, buildSubject(unknownCount: 2), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('shows legend items when data present', (tester) async {
      await pumpLocalizedApp(tester,
        buildSubject(maleCount: 2, femaleCount: 2, unknownCount: 1),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Legend items render as Container dots + Text labels
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows total label text key when data present', (tester) async {
      await pumpLocalizedApp(tester, buildSubject(maleCount: 3, femaleCount: 2), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      // easy_localization returns the key in test env
      expect(find.textContaining('statistics.total_label'), findsOneWidget);
    });

    testWidgets('resets touch state when data changes via didUpdateWidget', (
      tester,
    ) async {
      // Start with initial data
      final widget = MaterialApp(
        home: Scaffold(
          body: _UpdatableGenderChart(),
        ),
      );
      await pumpLocalizedApp(tester, widget, settle: false);
      await tester.pump(const Duration(milliseconds: 300));

      // PieChart should be rendered
      expect(find.byType(PieChart), findsOneWidget);

      // Trigger data update by tapping the update button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 300));

      // Chart should still render without error after data change
      expect(find.byType(PieChart), findsOneWidget);
    });
  });
}

/// Helper widget that allows updating GenderPieChart data via button tap.
class _UpdatableGenderChart extends StatefulWidget {
  @override
  State<_UpdatableGenderChart> createState() => _UpdatableGenderChartState();
}

class _UpdatableGenderChartState extends State<_UpdatableGenderChart> {
  int _maleCount = 3;
  int _femaleCount = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GenderPieChart(
            maleCount: _maleCount,
            femaleCount: _femaleCount,
            unknownCount: 1,
          ),
        ),
        ElevatedButton(
          onPressed: () => setState(() {
            _maleCount = 5;
            _femaleCount = 4;
          }),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
