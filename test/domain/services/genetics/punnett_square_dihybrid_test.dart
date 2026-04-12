import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Dihybrid Punnett square', () {
    test('produces 4x4 grid for two independent autosomal loci', () {
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
      expect(square!.fatherAlleles, hasLength(4));
      expect(square.motherAlleles, hasLength(4));
      expect(square.cells, hasLength(4));
      for (final row in square.cells) {
        expect(row, hasLength(4));
      }
    });

    test('mutation name contains both loci names separated by ×', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'dominant_pied': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'dominant_pied': AlleleState.visual,
        },
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'dominant_pied',
      );

      expect(square, isNotNull);
      expect(square!.mutationName, contains('\u00d7'));
    });

    test('cells contain genotype notation with slash separators', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'recessive_pied': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'recessive_pied': AlleleState.carrier,
        },
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'recessive_pied',
      );

      expect(square, isNotNull);
      for (final row in square!.cells) {
        for (final cell in row) {
          expect(cell, contains('/'),
              reason: 'Each cell should contain genotype with /');
          expect(cell, contains(','),
              reason: 'Each cell should show both loci separated by comma');
        }
      }
    });

    test('gamete labels contain semicolon separating both loci', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'dark_factor': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'dark_factor': AlleleState.carrier,
        },
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'dark_factor',
      );

      expect(square, isNotNull);
      for (final gamete in square!.fatherAlleles) {
        expect(gamete, contains('; '),
            reason: 'Gamete should show both loci: $gamete');
      }
      for (final gamete in square.motherAlleles) {
        expect(gamete, contains('; '),
            reason: 'Gamete should show both loci: $gamete');
      }
    });

    test('sex-linked + autosomal combination marks isSexLinked true', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'ino': AlleleState.carrier,
          'blue': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'ino': AlleleState.visual,
          'blue': AlleleState.carrier,
        },
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'ino',
        locusId2: 'blue',
      );

      expect(square, isNotNull);
      expect(square!.isSexLinked, isTrue,
          reason: 'Ino is sex-linked, so dihybrid should be marked');
    });

    test('two autosomal loci marks isSexLinked false', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'recessive_pied': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'recessive_pied': AlleleState.carrier,
        },
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'recessive_pied',
      );

      expect(square, isNotNull);
      expect(square!.isSexLinked, isFalse);
    });
  });

  group('Locus allele resolution', () {
    test('wild type parent produces wild-type alleles', () {
      const parent = ParentGenotype.empty(gender: BirdGender.male);

      final square = calculator.buildDihybridPunnettSquare(
        father: parent,
        mother: ParentGenotype(
          gender: BirdGender.female,
          mutations: {
            'blue': AlleleState.carrier,
            'spangle': AlleleState.carrier,
          },
        ),
        locusId1: 'blue',
        locusId2: 'spangle',
      );

      expect(square, isNotNull);
      expect(square!.fatherAlleles, hasLength(4));
    });
  });
}
