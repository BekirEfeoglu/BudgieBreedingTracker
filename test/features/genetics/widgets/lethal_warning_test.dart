import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/lethal_warning.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

ViabilityWarning _createWarning() {
  const combo = LethalCombination(
    id: 'test_combo',
    nameKey: 'genetics.lethal_df_crested_name',
    descriptionKey: 'genetics.lethal_df_crested_desc',
    severity: LethalSeverity.lethal,
    affectedRate: 0.25,
    requiredMutationIds: {'mut1'},
  );
  const offspring = OffspringResult(
    phenotype: 'Test Phenotype',
    probability: 0.25,
  );
  return const ViabilityWarning(combination: combo, offspring: offspring);
}

ViabilityWarning _createWarningWithSeverity(LethalSeverity severity) {
  final combo = LethalCombination(
    id: 'test_combo_$severity',
    nameKey: 'genetics.lethal_test_name',
    descriptionKey: 'genetics.lethal_test_desc',
    severity: severity,
    affectedRate: 0.25,
    requiredMutationIds: const {'mut1'},
  );
  const offspring = OffspringResult(phenotype: 'Test', probability: 0.25);
  return ViabilityWarning(combination: combo, offspring: offspring);
}

void main() {
  group('LethalWarning', () {
    testWidgets(
      'returns nothing (no Container) when analysis has no warnings',
      (tester) async {
        const analysis = LethalAnalysisResult(
          warnings: [],
          highestSeverity: null,
          totalAffectedProbability: 0.0,
        );
        await tester.pumpWidget(_wrap(const LethalWarning(analysis: analysis)));
        await tester.pump();

        expect(find.byType(Container), findsNothing);
      },
    );

    testWidgets('renders without crashing when analysis has warnings', (
      tester,
    ) async {
      final warning = _createWarning();
      final analysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.lethal,
        totalAffectedProbability: 0.25,
      );
      await tester.pumpWidget(_wrap(LethalWarning(analysis: analysis)));
      await tester.pump();

      expect(find.byType(LethalWarning), findsOneWidget);
    });

    testWidgets('shows lethal_warning_title text when has warnings', (
      tester,
    ) async {
      final warning = _createWarning();
      final analysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.lethal,
        totalAffectedProbability: 0.25,
      );
      await tester.pumpWidget(_wrap(LethalWarning(analysis: analysis)));
      await tester.pump();

      expect(find.text(l10n('genetics.lethal_warning_title')), findsOneWidget);
    });

    testWidgets('shows Container for lethal severity', (tester) async {
      final warning = _createWarning();
      final analysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.lethal,
        totalAffectedProbability: 0.25,
      );
      await tester.pumpWidget(_wrap(LethalWarning(analysis: analysis)));
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('shows LinearProgressIndicator when has warnings', (
      tester,
    ) async {
      final warning = _createWarning();
      final analysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.lethal,
        totalAffectedProbability: 0.25,
      );
      await tester.pumpWidget(_wrap(LethalWarning(analysis: analysis)));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows severity labelKey for lethal severity', (tester) async {
      final warning = _createWarningWithSeverity(LethalSeverity.lethal);
      final analysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.lethal,
        totalAffectedProbability: 0.25,
      );
      await tester.pumpWidget(_wrap(LethalWarning(analysis: analysis)));
      await tester.pump();

      // severity.labelKey.tr() returns key string in test environment
      expect(find.text(l10n('genetics.lethal_severity_lethal')), findsOneWidget);
    });

    testWidgets('shows severity labelKey for semiLethal severity', (
      tester,
    ) async {
      final warning = _createWarningWithSeverity(LethalSeverity.semiLethal);
      final analysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.semiLethal,
        totalAffectedProbability: 0.25,
      );
      await tester.pumpWidget(_wrap(LethalWarning(analysis: analysis)));
      await tester.pump();

      expect(find.text(l10n('genetics.lethal_severity_semi_lethal')), findsOneWidget);
    });

    testWidgets('renders without crashing for subVital severity', (
      tester,
    ) async {
      final warning = _createWarningWithSeverity(LethalSeverity.subVital);
      final analysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.subVital,
        totalAffectedProbability: 0.1,
      );
      await tester.pumpWidget(_wrap(LethalWarning(analysis: analysis)));
      await tester.pump();

      expect(find.byType(LethalWarning), findsOneWidget);
    });

    testWidgets('shows combination name key text', (tester) async {
      final warning = _createWarning();
      final analysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.lethal,
        totalAffectedProbability: 0.25,
      );
      await tester.pumpWidget(_wrap(LethalWarning(analysis: analysis)));
      await tester.pump();

      // combo.nameKey.tr() returns the key in test environment
      expect(find.text(l10n('genetics.lethal_df_crested_name')), findsOneWidget);
    });

    testWidgets('shows affected ratio text', (tester) async {
      final warning = _createWarning();
      final analysis = LethalAnalysisResult(
        warnings: [warning],
        highestSeverity: LethalSeverity.lethal,
        totalAffectedProbability: 0.25,
      );
      await tester.pumpWidget(_wrap(LethalWarning(analysis: analysis)));
      await tester.pump();

      expect(find.text(l10n('genetics.lethal_affected_ratio')), findsOneWidget);
    });
  });
}
