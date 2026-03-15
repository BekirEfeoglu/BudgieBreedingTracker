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

    test(
      'pearly x ino at ino locus resolves as Pearly (ino carried)',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'pearly': AlleleState.visual},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.visual},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        // Males: pearly/ino compound het → Pearly phenotype (ino carried)
        final males = results
            .where((r) => r.sex == OffspringSex.male)
            .toList();
        expect(males, isNotEmpty);
        // At least one male should express pearly with ino carried
        expect(
          males.any((r) =>
              r.visualMutations.contains('pearly') &&
              r.carriedMutations.contains('ino')),
          isTrue,
        );
      },
    );

    test(
      'tcb x pearly at ino locus resolves as Texas Clearbody (pearly carried)',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'texas_clearbody': AlleleState.visual},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'pearly': AlleleState.visual},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final males = results
            .where((r) => r.sex == OffspringSex.male)
            .toList();
        expect(males, isNotEmpty);
        expect(
          males.any((r) =>
              r.visualMutations.contains('texas_clearbody') &&
              r.carriedMutations.contains('pearly')),
          isTrue,
        );
      },
    );

    test(
      'pearly x pallid at ino locus resolves as Pallid Pearly (both expressed)',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'pearly': AlleleState.visual},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'pallid': AlleleState.visual},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final males = results
            .where((r) => r.sex == OffspringSex.male)
            .toList();
        expect(males, isNotEmpty);
        expect(
          males.any((r) =>
              r.visualMutations.contains('pearly') &&
              r.visualMutations.contains('pallid')),
          isTrue,
        );
      },
    );
  });
}
