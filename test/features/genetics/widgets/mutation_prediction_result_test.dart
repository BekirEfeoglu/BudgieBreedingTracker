import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('OffspringPrediction - prediction results display', () {
    testWidgets('renders without error for basic result', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.byType(OffspringPrediction), findsOneWidget);
    });

    testWidgets('shows prediction result phenotype name', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Blue',
        probability: 0.25,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      // PhenotypeLocalizer converts 'Normal Blue' to localization keys
      expect(find.textContaining('genetics.mutation'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows probability percentage for 50%', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.textContaining('%50.0'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows probability percentage for 25%', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Blue',
        probability: 0.25,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.textContaining('%25.0'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows probability percentage for 100%', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 1.0,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.textContaining('%100.0'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows CircularProgressIndicator for probability', (
      tester,
    ) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.75,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Card widget wrapping content', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows carrier badge for carrier result', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green (carrier)',
        probability: 0.25,
        isCarrier: true,
        carriedMutations: ['Blue'],
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.text('genetics.carrier'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show carrier badge for non-carrier', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      // Carrier text appears only inside carrier badge and semantics
      final carrierFinder = find.text('genetics.carrier');
      expect(carrierFinder, findsNothing);
    });

    testWidgets('shows lethal badge for lethal combination', (tester) async {
      const result = OffspringResult(
        phenotype: 'DF Crested',
        probability: 0.25,
        lethalCombinationIds: ['df_crested'],
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.text('genetics.lethal_badge'), findsOneWidget);
    });

    testWidgets('does not show lethal badge when no lethal combinations', (
      tester,
    ) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.text('genetics.lethal_badge'), findsNothing);
    });

    testWidgets('shows genotype text when showGenotype is true', (
      tester,
    ) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
        genotype: '+/+ bl/bl',
      );

      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: result, showGenotype: true)),
      );
      // Collapsed view shows hint label
      expect(
        find.text('genetics.genotype_detail_label'),
        findsAtLeastNWidgets(1),
      );

      // Tap to expand - full genotype visible
      await tester.tap(find.byType(OffspringPrediction));
      await tester.pumpAndSettle();
      expect(find.textContaining('+/+ bl/bl'), findsAtLeastNWidgets(1));
    });

    testWidgets('hides genotype text when showGenotype is false', (
      tester,
    ) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
        genotype: '+/+ bl/bl',
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.textContaining('+/+ bl/bl'), findsNothing);
    });

    testWidgets('shows carried mutation names in italic text', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.25,
        isCarrier: true,
        carriedMutations: ['Blue'],
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(
        find.textContaining('genetics.mutation_blue'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows masked mutations text when present', (tester) async {
      const result = OffspringResult(
        phenotype: 'Lutino',
        probability: 0.25,
        maskedMutations: ['Opaline'],
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.text('genetics.masked_mutations'), findsAtLeastNWidgets(1));
    });

    testWidgets('has Semantics wrapper for accessibility', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with compound phenotype name', (tester) async {
      const result = OffspringResult(
        phenotype: 'Opaline',
        probability: 0.5,
        compoundPhenotype: 'Opaline Blue',
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(
        find.textContaining('genetics.mutation_opaline'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('renders with male sex indicator', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Blue',
        probability: 0.25,
        sex: OffspringSex.male,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.byType(OffspringPrediction), findsOneWidget);
    });

    testWidgets('renders with female sex indicator', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Blue',
        probability: 0.25,
        sex: OffspringSex.female,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.byType(OffspringPrediction), findsOneWidget);
    });

    testWidgets('renders with zero probability', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.0,
      );

      await pumpLocalizedApp(tester,_wrap(const OffspringPrediction(result: result)));
      expect(find.textContaining('%0.0'), findsAtLeastNWidgets(1));
    });
  });
}
