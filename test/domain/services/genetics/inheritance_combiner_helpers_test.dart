import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Normalize and sort behavior', () {
    test('results are sorted by descending probability', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'opaline': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'opaline': AlleleState.visual,
        },
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      for (int i = 1; i < results.length; i++) {
        expect(
          results[i].probability,
          lessThanOrEqualTo(results[i - 1].probability),
          reason: 'Results should be sorted by descending probability',
        );
      }
    });

    test('probabilities sum to 1.0 after normalization', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'recessive_pied': AlleleState.carrier,
          'spangle': AlleleState.visual,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'recessive_pied': AlleleState.carrier,
        },
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      final total = results.fold<double>(0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.01));
    });

    test('very low probability results are filtered out', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'dark_factor': AlleleState.carrier,
          'spangle': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'dark_factor': AlleleState.carrier,
          'opaline': AlleleState.visual,
        },
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      for (final r in results) {
        expect(
          r.probability,
          greaterThan(0.001),
          reason:
              'Results below 0.1% threshold should be filtered: ${r.phenotype} (${r.probability})',
        );
      }
    });
  });

  group('Mutation ID extraction', () {
    test('visual mutations have non-empty visualMutations list', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      for (final r in results) {
        if (r.phenotype != 'Normal' && !r.isCarrier) {
          expect(
            r.visualMutations,
            isNotEmpty,
            reason:
                '${r.phenotype} should have visual mutations listed',
          );
        }
      }
    });

    test('carrier results have carriedMutations populated', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      final carriers = results.where((r) => r.isCarrier);
      for (final r in carriers) {
        expect(
          r.carriedMutations,
          isNotEmpty,
          reason: '${r.phenotype} carrier should list carried mutations',
        );
      }
    });

    test('carrier mutations never contain duplicates', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'opaline': AlleleState.carrier,
          'spangle': AlleleState.visual,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'cinnamon': AlleleState.visual,
        },
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      for (final r in results) {
        expect(
          r.carriedMutations.toSet().length,
          r.carriedMutations.length,
          reason:
              '${r.phenotype} has duplicate carriedMutations: ${r.carriedMutations}',
        );
      }
    });
  });

  group('Phenotype label builder', () {
    test('carrier offspring have carriedMutations set', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.carrier},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      final carriers = results.where((r) => r.isCarrier);
      expect(carriers, isNotEmpty, reason: 'Should have carrier offspring');
      for (final r in carriers) {
        expect(
          r.carriedMutations,
          isNotEmpty,
          reason: '${r.phenotype} carrier should have carriedMutations',
        );
      }
    });
  });
}
