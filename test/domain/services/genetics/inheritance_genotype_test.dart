import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Genotype inheritance flow', () {
    test(
      'autosomal incomplete dominant visual x carrier gives 50 double / 50 single',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'dark_factor': AlleleState.visual},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'dark_factor': AlleleState.carrier},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final doubleFactor = results.firstWhere(
          (r) => r.phenotype == 'Dark Factor (double)',
        );
        final singleFactor = results.firstWhere(
          (r) => r.phenotype == 'Dark Factor (single)',
        );

        expect(doubleFactor.probability, closeTo(0.5, 0.0001));
        expect(singleFactor.probability, closeTo(0.5, 0.0001));
      },
    );

    test(
      'sex-linked female carrier state is treated as visual (hemizygous)',
      () {
        const father = ParentGenotype.empty(gender: BirdGender.male);
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'opaline': AlleleState.carrier},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final maleCarrier = results.firstWhere(
          (r) => r.sex == OffspringSex.male && r.isCarrier,
        );
        final femaleNormal = results.firstWhere(
          (r) => r.sex == OffspringSex.female && r.phenotype == 'Normal',
        );

        expect(maleCarrier.phenotype, 'Opaline (carrier)');
        expect(maleCarrier.probability, closeTo(0.5, 0.0001));
        expect(femaleNormal.probability, closeTo(0.5, 0.0001));
      },
    );
  });
}
