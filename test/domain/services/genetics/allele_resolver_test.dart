import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Allele resolver behavior', () {
    test(
      'greywing x clearwing at dilution locus resolves to Full-Body Greywing',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'greywing': AlleleState.visual},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'clearwing': AlleleState.visual},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(results, hasLength(1));
        expect(results.single.phenotype, 'Full-Body Greywing');
        expect(results.single.probability, closeTo(1.0, 0.0001));
      },
    );

    test(
      'yellowface type II x blue at blue-series locus resolves correctly',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'yellowface_type2': AlleleState.visual},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'blue': AlleleState.visual},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(results, hasLength(1));
        expect(results.single.phenotype, 'Yellowface Type II Blue');
        expect(results.single.probability, closeTo(1.0, 0.0001));
      },
    );
  });
}
