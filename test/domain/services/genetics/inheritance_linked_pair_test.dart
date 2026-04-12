import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Sex-linked linkage pairs', () {
    test(
      'opaline-cinnamon linkage keeps parental compound more frequent than recombinants',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'opaline': AlleleState.carrier,
            'cinnamon': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );
        final females = results.where((r) => r.sex == OffspringSex.female);

        final compound = females.firstWhere(
          (r) =>
              r.phenotype.contains('Opaline') &&
              r.phenotype.contains('Cinnamon'),
        );
        final opalineOnly = females.firstWhere((r) => r.phenotype == 'Opaline');
        final cinnamonOnly = females.firstWhere(
          (r) => r.phenotype == 'Cinnamon',
        );

        expect(compound.probability, greaterThan(opalineOnly.probability));
        expect(compound.probability, greaterThan(cinnamonOnly.probability));
      },
    );

    test(
      'cinnamon-ino linkage yields Lacewing phenotype in female outcomes',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'cinnamon': AlleleState.carrier,
            'ino': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final females = results.where((r) => r.sex == OffspringSex.female);
        final lacewing = females.where((r) => r.phenotype.contains('Lacewing'));

        expect(lacewing, isNotEmpty);
      },
    );

    test(
      'split phase (repulsion) makes single-mutation daughters more frequent than Lacewing',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'cinnamon': AlleleState.split, 'ino': AlleleState.split},
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final females = results.where((r) => r.sex == OffspringSex.female);
        final cinnamon = females.firstWhere((r) => r.phenotype == 'Cinnamon');
        final ino = females.firstWhere((r) => r.phenotype == 'Ino');
        final lacewing = females.firstWhere(
          (r) => r.phenotype.contains('Lacewing'),
        );

        expect(cinnamon.probability, greaterThan(lacewing.probability));
        expect(ino.probability, greaterThan(lacewing.probability));
      },
    );
  });
}
