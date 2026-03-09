import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetic_charts.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetics_results_step.dart';

Widget _wrap({required List<dynamic> overrides}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: const MaterialApp(home: Scaffold(body: GeneticsResultsStep())),
  );
}

List<dynamic> _emptyOverrides() => [
  offspringResultsProvider.overrideWithValue(null),
  enrichedOffspringResultsProvider.overrideWithValue(null),
  punnettSquareProvider.overrideWithValue(null),
  offspringChartDataProvider.overrideWithValue(const []),
  showSexSpecificProvider.overrideWith(ShowSexSpecificNotifier.new),
  showGenotypeProvider.overrideWith(ShowGenotypeNotifier.new),
  availablePunnettLociProvider.overrideWithValue(const []),
  lethalAnalysisProvider.overrideWithValue(null),
];

const _results = [
  OffspringResult(phenotype: 'Normal Green', probability: 0.5),
  OffspringResult(phenotype: 'Blue', probability: 0.5),
];

List<dynamic> _dataOverrides() {
  return [
    offspringResultsProvider.overrideWithValue(_results),
    enrichedOffspringResultsProvider.overrideWithValue(_results),
    punnettSquareProvider.overrideWithValue(null),
    offspringChartDataProvider.overrideWithValue(
      _results
          .map(
            (r) => GeneticChartItem(
              label: r.phenotype,
              value: r.probability * 100,
              color: Colors.blue,
            ),
          )
          .toList(),
    ),
    showSexSpecificProvider.overrideWith(ShowSexSpecificNotifier.new),
    showGenotypeProvider.overrideWith(ShowGenotypeNotifier.new),
    availablePunnettLociProvider.overrideWithValue(const []),
    lethalAnalysisProvider.overrideWithValue(null),
  ];
}

void main() {
  group('GeneticsResultsStep', () {
    testWidgets('shows no_results icon and text when results are null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(overrides: _emptyOverrides()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.no_results'), findsOneWidget);
    });

    testWidgets('shows results when offspringResults is not null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(overrides: _dataOverrides()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.results_title'), findsOneWidget);
    });

    testWidgets('shows show_sex_specific toggle label', (tester) async {
      await tester.pumpWidget(_wrap(overrides: _dataOverrides()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.show_sex_specific'), findsOneWidget);
    });

    testWidgets('shows show_genotype toggle label', (tester) async {
      await tester.pumpWidget(_wrap(overrides: _dataOverrides()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.show_genotype'), findsOneWidget);
    });

    testWidgets('shows two Switch widgets for toggles', (tester) async {
      await tester.pumpWidget(_wrap(overrides: _dataOverrides()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('shows OffspringProbabilityBarChart when chart data exists', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(overrides: _dataOverrides()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(OffspringProbabilityBarChart), findsOneWidget);
    });

    testWidgets('shows phenotype names in results', (tester) async {
      await tester.pumpWidget(_wrap(overrides: _dataOverrides()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(
        find.textContaining('genetics.mutation_normal'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows no PunnettSquare when punnett is null', (tester) async {
      await tester.pumpWidget(_wrap(overrides: _dataOverrides()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // No punnett data => no PunnettSquareWidget
      expect(find.byKey(const ValueKey('punnett_square')), findsNothing);
    });

    testWidgets('shows LethalWarning when lethalAnalysis has warnings', (
      tester,
    ) async {
      const combo = LethalCombination(
        id: 'df_crested',
        nameKey: 'genetics.lethal_df_crested_name',
        descriptionKey: 'genetics.lethal_df_crested_desc',
        severity: LethalSeverity.lethal,
        affectedRate: 0.25,
        requiredMutationIds: {'crested'},
      );
      const offspring = OffspringResult(
        phenotype: 'DF Crested',
        probability: 0.25,
      );
      const warning = ViabilityWarning(
        combination: combo,
        offspring: offspring,
      );
      const lethalAnalysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.lethal,
        totalAffectedProbability: 0.25,
      );

      await tester.pumpWidget(
        _wrap(
          overrides: [
            offspringResultsProvider.overrideWithValue(_results),
            enrichedOffspringResultsProvider.overrideWithValue(_results),
            punnettSquareProvider.overrideWithValue(null),
            offspringChartDataProvider.overrideWithValue(const []),
            showSexSpecificProvider.overrideWith(ShowSexSpecificNotifier.new),
            showGenotypeProvider.overrideWith(ShowGenotypeNotifier.new),
            availablePunnettLociProvider.overrideWithValue(const []),
            lethalAnalysisProvider.overrideWithValue(lethalAnalysis),
          ],
        ),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.lethal_warning_title'), findsOneWidget);
    });

    testWidgets('shows epistasis interaction card when interactions exist', (
      tester,
    ) async {
      const interactionResults = [
        OffspringResult(
          phenotype: 'Albino',
          probability: 1.0,
          visualMutations: ['ino', 'blue'],
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          overrides: [
            offspringResultsProvider.overrideWithValue(interactionResults),
            enrichedOffspringResultsProvider.overrideWithValue(
              interactionResults,
            ),
            punnettSquareProvider.overrideWithValue(null),
            offspringChartDataProvider.overrideWithValue(const []),
            showSexSpecificProvider.overrideWith(ShowSexSpecificNotifier.new),
            showGenotypeProvider.overrideWith(ShowGenotypeNotifier.new),
            availablePunnettLociProvider.overrideWithValue(const []),
            lethalAnalysisProvider.overrideWithValue(null),
          ],
        ),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.interaction_info'), findsOneWidget);
    });
  });
}
