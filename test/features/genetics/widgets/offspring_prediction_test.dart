import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

const _basicResult = OffspringResult(
  phenotype: 'Normal Green',
  probability: 0.5,
);

const _carrierResult = OffspringResult(
  phenotype: 'Normal Green (carrier)',
  probability: 0.25,
  isCarrier: true,
  carriedMutations: ['Blue'],
);

const _maleResult = OffspringResult(
  phenotype: 'Normal Blue',
  probability: 0.25,
  sex: OffspringSex.male,
);

const _femaleResult = OffspringResult(
  phenotype: 'Normal Blue',
  probability: 0.25,
  sex: OffspringSex.female,
);

const _lethalResult = OffspringResult(
  phenotype: 'DF Crested',
  probability: 0.25,
  lethalCombinationIds: ['df_crested'],
);

const _compoundResult = OffspringResult(
  phenotype: 'Opaline',
  probability: 0.5,
  compoundPhenotype: 'Opaline Blue',
);

void main() {
  group('OffspringPrediction', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      expect(find.byType(OffspringPrediction), findsOneWidget);
    });

    testWidgets('shows phenotype name', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      expect(
        find.textContaining('genetics.mutation_normal'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows probability percentage', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      expect(find.textContaining('%50.0'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows carrier badge when isCarrier is true', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _carrierResult)),
      );
      expect(find.text('genetics.carrier'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows lethal badge when lethalCombinationIds is not empty', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _lethalResult)),
      );
      expect(find.text('genetics.lethal_badge'), findsOneWidget);
    });

    testWidgets('shows Card widget', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator for probability', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows male sex icon for male offspring', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _maleResult)),
      );
      // AppIcon widget is present (sex icon uses SVG AppIcon)
      expect(find.byType(AppIcon), findsAtLeastNWidgets(1));
    });

    testWidgets('shows compound phenotype name when provided', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _compoundResult)),
      );
      expect(
        find.textContaining('genetics.mutation_opaline genetics.mutation_blue'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows carried mutations when not empty', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _carrierResult)),
      );
      expect(
        find.textContaining('genetics.mutation_blue'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows genotype text when showGenotype is true', (
      tester,
    ) async {
      const resultWithGenotype = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
        genotype: '+/+ bl/bl',
      );
      await pumpLocalizedApp(tester,
        _wrap(
          const OffspringPrediction(
            result: resultWithGenotype,
            showGenotype: true,
          ),
        ),
      );
      expect(find.textContaining('+/+ bl/bl'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with female sex correctly', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _femaleResult)),
      );
      expect(find.byType(OffspringPrediction), findsOneWidget);
    });

    testWidgets('has Semantics wrapper for accessibility', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });

    group('circular indicator minimum arc', () {
      testWidgets('low probability (<5%) uses minimum 0.05 visual value', (
        tester,
      ) async {
        const lowResult = OffspringResult(
          phenotype: 'Rare Phenotype',
          probability: 0.02,
        );
        await pumpLocalizedApp(tester,
          _wrap(const OffspringPrediction(result: lowResult)),
        );
        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.value, 0.05);
      });

      testWidgets('low probability still shows actual percentage text', (
        tester,
      ) async {
        const lowResult = OffspringResult(
          phenotype: 'Rare Phenotype',
          probability: 0.02,
        );
        await pumpLocalizedApp(tester,
          _wrap(const OffspringPrediction(result: lowResult)),
        );
        // Text shows actual 2.0%, not the clamped 5.0%
        expect(find.text('%2.0'), findsOneWidget);
      });

      testWidgets('zero probability stays at zero (no minimum)', (
        tester,
      ) async {
        const zeroResult = OffspringResult(
          phenotype: 'Zero Phenotype',
          probability: 0.0,
        );
        await pumpLocalizedApp(tester,
          _wrap(const OffspringPrediction(result: zeroResult)),
        );
        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.value, 0.0);
      });

      testWidgets('high probability (>=5%) uses exact value', (tester) async {
        await pumpLocalizedApp(tester,
          _wrap(const OffspringPrediction(result: _basicResult)),
        );
        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.value, 0.5);
      });
    });

    group('carrier mutations maxLines', () {
      testWidgets('carrier mutations text allows 2 lines', (tester) async {
        const multiCarrierResult = OffspringResult(
          phenotype: 'Normal Green',
          probability: 0.25,
          isCarrier: true,
          carriedMutations: [
            'Blue',
            'Opaline',
            'Cinnamon',
            'Ino',
            'Fallow',
          ],
        );
        await pumpLocalizedApp(tester,
          _wrap(const OffspringPrediction(result: multiCarrierResult)),
        );
        // Find the carrier mutations Text widget by style (italic + warning)
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        final carrierText = textWidgets.where(
          (t) => t.maxLines == 2 && t.style?.fontStyle == FontStyle.italic,
        );
        expect(carrierText, isNotEmpty);
      });
    });

    group('percentage display', () {
      testWidgets('percentage shown only in circular indicator', (
        tester,
      ) async {
        await pumpLocalizedApp(tester,
          _wrap(const OffspringPrediction(result: _basicResult)),
        );
        // Percentage text appears exactly once (inside circular indicator)
        expect(find.text('%50.0'), findsOneWidget);
      });
    });
  });
}
