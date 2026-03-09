import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';

void main() {
  group('OffspringResult', () {
    test('uses defaults for optional fields', () {
      const result = OffspringResult(phenotype: 'Normal', probability: 1.0);

      expect(result.sex, OffspringSex.both);
      expect(result.isCarrier, isFalse);
      expect(result.genotype, isNull);
      expect(result.visualMutations, isEmpty);
      expect(result.compoundPhenotype, isNull);
      expect(result.carriedMutations, isEmpty);
      expect(result.maskedMutations, isEmpty);
      expect(result.lethalCombinationIds, isEmpty);
    });

    test('stores all extended genetics fields', () {
      const result = OffspringResult(
        phenotype: 'Albino',
        probability: 0.25,
        sex: OffspringSex.female,
        isCarrier: true,
        genotype: 'Zino/W',
        visualMutations: ['ino', 'blue'],
        compoundPhenotype: 'Albino',
        carriedMutations: ['opaline'],
        maskedMutations: ['opaline'],
        lethalCombinationIds: ['crested'],
      );

      expect(result.phenotype, 'Albino');
      expect(result.probability, 0.25);
      expect(result.sex, OffspringSex.female);
      expect(result.isCarrier, isTrue);
      expect(result.genotype, 'Zino/W');
      expect(result.visualMutations, ['ino', 'blue']);
      expect(result.compoundPhenotype, 'Albino');
      expect(result.carriedMutations, ['opaline']);
      expect(result.maskedMutations, ['opaline']);
      expect(result.lethalCombinationIds, ['crested']);
    });
  });

  group('PunnettSquareData', () {
    test('keeps headers and matrix values', () {
      const square = PunnettSquareData(
        mutationName: 'Blue',
        fatherAlleles: ['bl', '+'],
        motherAlleles: ['bl', '+'],
        cells: [
          ['bl/bl', 'bl/+'],
          ['+/bl', '+/+'],
        ],
        isSexLinked: false,
      );

      expect(square.mutationName, 'Blue');
      expect(square.fatherAlleles, ['bl', '+']);
      expect(square.motherAlleles, ['bl', '+']);
      expect(square.cells[0][0], 'bl/bl');
      expect(square.cells[1][1], '+/+');
      expect(square.isSexLinked, isFalse);
    });
  });
}
