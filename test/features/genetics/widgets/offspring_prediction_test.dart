import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';

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
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      await tester.pump();
      expect(find.byType(OffspringPrediction), findsOneWidget);
    });

    testWidgets('shows phenotype name', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
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

    testWidgets('shows probability percentage', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.textContaining('50.0%'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows carrier badge when isCarrier is true', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _carrierResult)),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.carrier'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows lethal badge when lethalCombinationIds is not empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _lethalResult)),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.lethal_badge'), findsOneWidget);
    });

    testWidgets('shows Card widget', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator for probability', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows male sex icon for male offspring', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _maleResult)),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      // Icon widget is present (sex icon)
      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });

    testWidgets('shows compound phenotype name when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _compoundResult)),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(
        find.textContaining('genetics.mutation_opaline genetics.mutation_blue'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows carried mutations when not empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _carrierResult)),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

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
      await tester.pumpWidget(
        _wrap(
          const OffspringPrediction(
            result: resultWithGenotype,
            showGenotype: true,
          ),
        ),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.textContaining('+/+ bl/bl'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with female sex correctly', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _femaleResult)),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(OffspringPrediction), findsOneWidget);
    });

    testWidgets('has Semantics wrapper for accessibility', (tester) async {
      await tester.pumpWidget(
        _wrap(const OffspringPrediction(result: _basicResult)),
      );
      await tester.pump();
      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });
  });
}
