import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('buildPunnettSquareFromGenotypes', () {
    test('returns null for empty parents', () {
      const father = ParentGenotype.empty(gender: BirdGender.male);
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(square, isNull);
    });

    test('builds autosomal recessive 2x2 square', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'blue',
      );

      expect(square, isNotNull);
      expect(square!.fatherAlleles, hasLength(2));
      expect(square.motherAlleles, hasLength(2));
      expect(square.cells, hasLength(2));
      expect(square.isSexLinked, isFalse);
    });

    test('builds sex-linked square with Z/W notation', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'opaline': AlleleState.visual},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'opaline',
      );

      expect(square, isNotNull);
      expect(square!.isSexLinked, isTrue);
      expect(
        square.motherAlleles.any((a) => a == 'W'),
        isTrue,
        reason: 'Mother alleles should contain W chromosome',
      );
    });

    test('defaults to first mutation when mutationId is null', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(square, isNotNull);
    });

    test('returns null for unknown mutation ID', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'nonexistent_mutation_xyz',
      );

      expect(square, isNull);
    });

    test('allelic series locus builds correct square', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'greywing': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'clearwing': AlleleState.visual},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: GeneticsConstants.locusDilution,
      );

      expect(square, isNotNull);
      expect(square!.mutationName, isNotEmpty);
      expect(square.cells, isNotEmpty);
    });

    test('visual x visual autosomal recessive produces all homozygous', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'blue',
      );

      expect(square, isNotNull);
      for (final row in square!.cells) {
        for (final cell in row) {
          expect(cell, contains('/'));
        }
      }
    });

    test('autosomal dominant square has correct allele count', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'dominant_pied': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'dominant_pied': AlleleState.carrier},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'dominant_pied',
      );

      expect(square, isNotNull);
      expect(square!.fatherAlleles, hasLength(2));
      expect(square.motherAlleles, hasLength(2));
    });
  });

  group('buildDihybridPunnettSquare delegation', () {
    test('delegates correctly and returns valid 4x4 grid', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'spangle': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'spangle': AlleleState.carrier,
        },
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'spangle',
      );

      expect(square, isNotNull);
      expect(square!.cells, hasLength(4));
    });
  });
}
