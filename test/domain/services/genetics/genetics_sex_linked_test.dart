import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import 'genetics_test_helpers.dart';

void main() {
  const calculator = MendelianCalculator();

  // =====================================================================
  // 4. SEX-LINKED RECESSIVE (Ino)
  // =====================================================================
  group('Sex-linked recessive (Ino)', () {
    test('carrier male x normal female → sex-specific results', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);

      // Males: 50% Normal (carrier+pure merged, allelic series behavior)
      final maleNormal = sumProbability(results, 'Normal', sex: OffspringSex.male);
      expect(maleNormal, closeTo(0.50, 0.01));

      // Females: 25% visual Ino, 25% normal
      final femaleResults = results.where((r) => r.sex == OffspringSex.female);
      expect(femaleResults.length, greaterThanOrEqualTo(1));
      final femaleNormal = sumProbability(results, 'Normal', sex: OffspringSex.female);
      expect(femaleNormal, closeTo(0.25, 0.01));
    });

    test('visual male x visual female → 100% Ino', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.visual},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(
        results.every(
          (r) => r.visualMutations.contains('ino') || r.phenotype.contains('Ino'),
        ),
        isTrue,
      );
    });

    test('female cannot be carrier for sex-linked → treated as visual', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.carrier}, // invalid, treated as visual
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      // All males should be carriers (Z+/Zino from mother)
      final maleResults = results.where((r) => r.sex == OffspringSex.male);
      expect(maleResults.every((r) => r.isCarrier), isTrue);
    });
  });
}
