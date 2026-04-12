import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_legend_item.dart';

void main() {
  group('ChartLegendItem', () {
    testWidgets('renders color indicator and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartLegendItem(color: Colors.blue, label: 'Male'),
          ),
        ),
      );

      expect(find.text('Male'), findsOneWidget);
      // Color indicator is a Container with decoration
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders label with count when count is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartLegendItem(color: Colors.red, label: 'Female', count: 5),
          ),
        ),
      );

      expect(find.text('Female (5)'), findsOneWidget);
    });

    testWidgets('renders label without count when count is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartLegendItem(color: Colors.green, label: 'Active'),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.textContaining('('), findsNothing);
    });

    testWidgets('uses circle shape by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartLegendItem(color: Colors.blue, label: 'Test'),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final indicator = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).shape == BoxShape.circle,
        orElse: () => throw StateError('No circle container found'),
      );
      final decoration = indicator.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('uses rectangle shape when useCircle is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartLegendItem(
              color: Colors.blue,
              label: 'Test',
              useCircle: false,
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final indicator = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).shape == BoxShape.rectangle &&
            (c.decoration! as BoxDecoration).borderRadius != null,
        orElse: () => throw StateError('No rectangle container found'),
      );
      final decoration = indicator.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.rectangle);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(AppSpacing.radiusSm),
      );
    });

    testWidgets('applies the correct color to indicator', (tester) async {
      const testColor = Colors.orange;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartLegendItem(color: testColor, label: 'Orange'),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final indicator = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color == testColor,
        orElse: () => throw StateError('No matching color container'),
      );
      final decoration = indicator.decoration! as BoxDecoration;
      expect(decoration.color, testColor);
    });
  });
}
