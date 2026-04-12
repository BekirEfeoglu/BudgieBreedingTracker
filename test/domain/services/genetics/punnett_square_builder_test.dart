import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Punnett square builder', () {
    test('builds dilution allelic-series square with expected headers', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'greywing': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'clearwing': AlleleState.carrier},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: GeneticsConstants.locusDilution,
      );

      expect(square, isNotNull);
      expect(square!.mutationName, 'Dilution');
      expect(square.isSexLinked, isFalse);
      expect(square.fatherAlleles, containsAll(['gw', '+']));
      expect(square.motherAlleles, containsAll(['cw', '+']));
      expect(square.cells, hasLength(2));
      expect(square.cells.first, hasLength(2));
      expect(
        square.cells.expand((r) => r).every((c) => c.contains('/')),
        isTrue,
      );
    });

    test('builds ino-locus sex-linked square with Z/W notation', () {
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
      expect(square!.isSexLinked, isTrue);
      expect(square.fatherAlleles.every((a) => a.startsWith('Z')), isTrue);
      expect(square.motherAlleles, contains('W'));
      expect(
        square.cells.expand((r) => r).any((c) => c.endsWith('/W')),
        isTrue,
      );
    });
  });
}
