import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/grouped_results_list.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('GroupedResultsList', () {
    testWidgets('shows no results message when list is empty', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const GroupedResultsList(results: [])),
      );

      expect(find.text('genetics.no_results'), findsOneWidget);
    });

    testWidgets('renders flat list when no grouping needed', (tester) async {
      const results = [
        OffspringResult(phenotype: 'Normal Green', probability: 0.5),
        OffspringResult(phenotype: 'Blue', probability: 0.25),
        OffspringResult(phenotype: 'Opaline', probability: 0.125),
      ];

      await pumpLocalizedApp(
        tester,
        _wrap(const GroupedResultsList(results: results)),
      );

      // Each result is unique probability, so flat list is used
      expect(
        find.byType(OffspringPrediction),
        findsNWidgets(3),
      );
    });

    testWidgets('groups results with same probability', (tester) async {
      const results = [
        OffspringResult(phenotype: 'Normal Green', probability: 0.25),
        OffspringResult(phenotype: 'Blue', probability: 0.25),
        OffspringResult(phenotype: 'Opaline', probability: 0.5),
      ];

      await pumpLocalizedApp(
        tester,
        _wrap(const GroupedResultsList(results: results)),
      );

      // Two Normal Green and Blue share 25.0%, so grouped
      expect(find.text('%25.0'), findsOneWidget);
      expect(
        find.byType(OffspringPrediction),
        findsNWidgets(3),
      );
    });

    testWidgets('shows group header with count', (tester) async {
      const results = [
        OffspringResult(phenotype: 'A', probability: 0.25),
        OffspringResult(phenotype: 'B', probability: 0.25),
        OffspringResult(phenotype: 'C', probability: 0.25),
        OffspringResult(phenotype: 'D', probability: 0.25),
      ];

      await pumpLocalizedApp(
        tester,
        _wrap(const GroupedResultsList(results: results)),
      );

      // All have same probability, so one group header
      expect(find.text('%25.0'), findsOneWidget);
      // Group header shows count
      expect(
        find.textContaining('genetics.probability_group_header'),
        findsOneWidget,
      );
    });

    testWidgets('renders single result without group headers', (tester) async {
      const results = [
        OffspringResult(phenotype: 'Normal Green', probability: 1.0),
      ];

      await pumpLocalizedApp(
        tester,
        _wrap(const GroupedResultsList(results: results)),
      );

      expect(find.byType(OffspringPrediction), findsOneWidget);
      // No group headers for single result (no duplicate probabilities)
      expect(
        find.textContaining('genetics.probability_group_header'),
        findsNothing,
      );
    });

    testWidgets('passes showGenotype through to OffspringPrediction', (
      tester,
    ) async {
      const results = [
        OffspringResult(
          phenotype: 'Normal Green',
          probability: 0.5,
          genotype: '+/+ bl/bl',
        ),
      ];

      await pumpLocalizedApp(
        tester,
        _wrap(const GroupedResultsList(
          results: results,
          showGenotype: true,
        )),
      );

      // Genotype is shown as a hint label in collapsed view
      expect(
        find.text('genetics.genotype_detail_label'),
        findsAtLeastNWidgets(1),
      );

      // Tap to expand and verify full genotype is visible
      await tester.tap(find.byType(OffspringPrediction));
      await tester.pumpAndSettle();
      expect(find.textContaining('+/+ bl/bl'), findsAtLeastNWidgets(1));
    });

    testWidgets('updates groups when results change', (tester) async {
      const initialResults = [
        OffspringResult(phenotype: 'A', probability: 0.5),
      ];

      const updatedResults = [
        OffspringResult(phenotype: 'A', probability: 0.25),
        OffspringResult(phenotype: 'B', probability: 0.25),
      ];

      await pumpLocalizedApp(
        tester,
        _wrap(const GroupedResultsList(results: initialResults)),
      );

      expect(find.byType(OffspringPrediction), findsOneWidget);

      // Rebuild with different results
      await pumpLocalizedApp(
        tester,
        _wrap(const GroupedResultsList(results: updatedResults)),
      );

      expect(find.byType(OffspringPrediction), findsNWidgets(2));
    });

    testWidgets('multiple groups each get their own header', (tester) async {
      const results = [
        OffspringResult(phenotype: 'A', probability: 0.25),
        OffspringResult(phenotype: 'B', probability: 0.25),
        OffspringResult(phenotype: 'C', probability: 0.125),
        OffspringResult(phenotype: 'D', probability: 0.125),
      ];

      await pumpLocalizedApp(
        tester,
        _wrap(const GroupedResultsList(results: results)),
      );

      // Two group headers (25.0% and 12.5%)
      expect(find.text('%25.0'), findsOneWidget);
      expect(find.text('%12.5'), findsOneWidget);
      expect(
        find.textContaining('genetics.probability_group_header'),
        findsNWidgets(2),
      );
    });
  });
}
