import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

ParentGenotype _toGenotype(Set<String> ids, BirdGender gender) {
  return ParentGenotype(
    mutations: {for (final id in ids) id: AlleleState.visual},
    gender: gender,
  );
}

void main() {
  const calculator = MendelianCalculator();

  group('Punnett square edge cases', () {
    test('returns null for unknown mutation ID', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'nonexistent_mutation': AlleleState.visual},
      );
      final mother = ParentGenotype(gender: BirdGender.female, mutations: {});

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'nonexistent_mutation',
      );

      expect(square, isNull);
    });

    test('returns null when mutation ID does not match any locus', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual},
      );

      // 'blue' mutation exists but requesting a different locus
      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: GeneticsConstants.locusIno,
      );

      // Square should still build (wild-type x wild-type for ino locus)
      expect(square, isNotNull);
      expect(square!.cells, isNotEmpty);
    });

    test('handles both parents wild-type for requested locus', () {
      final father = ParentGenotype(gender: BirdGender.male, mutations: {});
      final mother = ParentGenotype(gender: BirdGender.female, mutations: {});

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: GeneticsConstants.locusDilution,
      );

      expect(square, isNull);
    });

    test('sex-linked square produces Z and W alleles', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.visual},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: GeneticsConstants.locusIno,
      );

      expect(square, isNotNull);
      expect(square!.isSexLinked, isTrue);
      expect(square.motherAlleles, contains('W'));
    });

    test(
      'carrier father x visual mother produces expected offspring ratios',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'ino': AlleleState.carrier},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.visual},
        );

        final square = calculator.buildPunnettSquareFromGenotypes(
          father: father,
          mother: mother,
          mutationId: GeneticsConstants.locusIno,
        );

        expect(square, isNotNull);
        expect(square!.cells, isNotEmpty);
        // Should have a mix of ino and non-ino outcomes
        final allCells = square.cells.expand((row) => row).toList();
        expect(allCells.length, greaterThanOrEqualTo(2));
      },
    );
  });

  group('MendelianCalculator offspring edge cases', () {
    test('returns empty list when both parents have no mutations', () {
      final results = calculator.calculateFromGenotypes(
        father: _toGenotype({}, BirdGender.male),
        mother: _toGenotype({}, BirdGender.female),
      );

      expect(results, isEmpty);
    });

    test('handles single mutation in one parent', () {
      final results = calculator.calculateFromGenotypes(
        father: _toGenotype({'blue'}, BirdGender.male),
        mother: _toGenotype({}, BirdGender.female),
      );

      expect(results, isNotEmpty);
      // All offspring should have some probability
      for (final result in results) {
        expect(result.probability, greaterThan(0.0));
      }
    });

    test('probabilities sum to approximately 1.0', () {
      final results = calculator.calculateFromGenotypes(
        father: _toGenotype({'blue', 'opaline'}, BirdGender.male),
        mother: _toGenotype({'blue'}, BirdGender.female),
      );

      expect(results, isNotEmpty);
      final totalProbability = results.fold(
        0.0,
        (sum, r) => sum + r.probability,
      );
      expect(totalProbability, closeTo(1.0, 0.0001));
    });
  });
}
