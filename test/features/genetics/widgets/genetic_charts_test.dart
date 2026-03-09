import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/widgets/genetic_charts.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void _consumeExceptions(WidgetTester tester) {
  var ex = tester.takeException();
  while (ex != null) {
    ex = tester.takeException();
  }
}

final _singleItem = [
  const GeneticChartItem(label: 'Normal', value: 50.0, color: Colors.green),
];

final _multipleItems = [
  const GeneticChartItem(label: 'Normal', value: 50.0, color: Colors.green),
  const GeneticChartItem(label: 'Blue', value: 25.0, color: Colors.blue),
  const GeneticChartItem(label: 'Opaline', value: 25.0, color: Colors.orange),
];

void main() {
  group('GeneticChartItem', () {
    test('stores label, value, and color', () {
      const item = GeneticChartItem(
        label: 'Test',
        value: 42.0,
        color: Colors.red,
      );
      expect(item.label, 'Test');
      expect(item.value, 42.0);
      expect(item.color, Colors.red);
    });
  });

  group('MutationDistributionPieChart', () {
    testWidgets('renders without crashing with empty data', (tester) async {
      await tester.pumpWidget(
        _wrap(const MutationDistributionPieChart(data: [])),
      );
      await tester.pump();
      expect(find.byType(MutationDistributionPieChart), findsOneWidget);
    });

    testWidgets('shows no_data text when data is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const MutationDistributionPieChart(data: [])),
      );
      await tester.pump();
      expect(find.text('genetics.no_data'), findsOneWidget);
    });

    testWidgets('shows title when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MutationDistributionPieChart(data: [], title: 'My Chart Title'),
        ),
      );
      await tester.pump();
      expect(find.text('My Chart Title'), findsOneWidget);
    });

    testWidgets('renders PieChart when data is not empty', (tester) async {
      await tester.pumpWidget(
        _wrap(MutationDistributionPieChart(data: _singleItem)),
      );
      await tester.pump();

      _consumeExceptions(tester);

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('shows legend labels for each item', (tester) async {
      await tester.pumpWidget(
        _wrap(MutationDistributionPieChart(data: _multipleItems)),
      );
      await tester.pump();

      _consumeExceptions(tester);

      expect(find.text('Normal'), findsAtLeastNWidgets(1));
      expect(find.text('Blue'), findsAtLeastNWidgets(1));
      expect(find.text('Opaline'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Card wrapper', (tester) async {
      await tester.pumpWidget(
        _wrap(MutationDistributionPieChart(data: _singleItem)),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows no_data text when total value is zero', (tester) async {
      final zeroData = [
        const GeneticChartItem(label: 'Zero', value: 0.0, color: Colors.grey),
      ];
      await tester.pumpWidget(
        _wrap(MutationDistributionPieChart(data: zeroData)),
      );
      await tester.pump();
      expect(find.text('genetics.no_data'), findsOneWidget);
    });

    testWidgets('shows RepaintBoundary for PieChart', (tester) async {
      await tester.pumpWidget(
        _wrap(MutationDistributionPieChart(data: _singleItem)),
      );
      await tester.pump();

      _consumeExceptions(tester);

      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });
  });

  group('OffspringProbabilityBarChart', () {
    testWidgets('renders without crashing with empty data', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringProbabilityBarChart(data: [])),
      );
      await tester.pump();
      expect(find.byType(OffspringProbabilityBarChart), findsOneWidget);
    });

    testWidgets('shows no_data text when data is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringProbabilityBarChart(data: [])),
      );
      await tester.pump();
      expect(find.text('genetics.no_data'), findsOneWidget);
    });

    testWidgets('shows title when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const OffspringProbabilityBarChart(
            data: [],
            title: 'Probability Chart',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Probability Chart'), findsOneWidget);
    });

    testWidgets('renders BarChart when data is not empty', (tester) async {
      await tester.pumpWidget(
        _wrap(OffspringProbabilityBarChart(data: _singleItem)),
      );
      await tester.pump();

      _consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('shows Card wrapper', (tester) async {
      await tester.pumpWidget(
        _wrap(OffspringProbabilityBarChart(data: _singleItem)),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows RepaintBoundary around BarChart', (tester) async {
      await tester.pumpWidget(
        _wrap(OffspringProbabilityBarChart(data: _singleItem)),
      );
      await tester.pump();

      _consumeExceptions(tester);

      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });

    testWidgets('renders multiple bar items without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(OffspringProbabilityBarChart(data: _multipleItems)),
      );
      await tester.pump();

      _consumeExceptions(tester);

      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}
