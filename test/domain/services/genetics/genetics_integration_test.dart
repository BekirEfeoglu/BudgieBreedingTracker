import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();
  const epistasis = EpistasisEngine();

  group('Genetics integration', () {
    test(
      'full flow: parent mutations -> offspring predictions -> compound phenotype',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'blue': AlleleState.visual, 'ino': AlleleState.visual},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'blue': AlleleState.visual, 'ino': AlleleState.visual},
        );

        final predictions = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(predictions, isNotEmpty);
        expect(predictions.any((r) => r.compoundPhenotype == 'Albino'), isTrue);

        final resolved = epistasis.resolveCompoundPhenotype({'blue', 'ino'});
        expect(resolved, 'Albino');
      },
    );

    test(
      'handles multi-mutation combinations with normalized probabilities',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'blue': AlleleState.visual,
            'opaline': AlleleState.visual,
            'dark_factor': AlleleState.carrier,
          },
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {
            'blue': AlleleState.carrier,
            'opaline': AlleleState.visual,
            'dark_factor': AlleleState.visual,
          },
        );

        final predictions = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(predictions, isNotEmpty);
        final total = predictions.fold<double>(
          0,
          (sum, item) => sum + item.probability,
        );
        expect(total, closeTo(1.0, 0.001));

        final hasCompound = predictions.any(
          (r) => (r.compoundPhenotype ?? '').isNotEmpty,
        );
        expect(hasCompound, isTrue);
      },
    );

    test('epistasis detail includes masked mutations when ino is present', () {
      final result = epistasis.resolveCompoundPhenotypeDetailed({
        'blue',
        'ino',
        'opaline',
      });

      expect(result.name, 'Albino');
      expect(result.maskedMutations, contains('Opaline'));
    });
  });
}
