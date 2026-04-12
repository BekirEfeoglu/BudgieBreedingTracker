import 'package:flutter_test/flutter_test.dart';

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

  group('Result combiner behavior', () {
    test('genotype API combines multi-locus results into normalized total', () {
      final results = calculator.calculateFromGenotypes(
        father: _toGenotype({'blue', 'recessive_pied'}, BirdGender.male),
        mother: _toGenotype({'blue', 'recessive_pied'}, BirdGender.female),
      );

      expect(results, isNotEmpty);
      final total = results.fold<double>(0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.0001));
    });

    test('genotype multi-locus combination keeps normalized total', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'dominant_pied': AlleleState.visual,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'dominant_pied': AlleleState.carrier,
        },
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );
      final total = results.fold<double>(0, (sum, r) => sum + r.probability);

      expect(results, isNotEmpty);
      expect(total, closeTo(1.0, 0.0001));
      for (final r in results) {
        expect(
          r.carriedMutations.toSet().length,
          r.carriedMutations.length,
          reason:
              '${r.phenotype} has duplicate carriedMutations: '
              '${r.carriedMutations}',
        );
      }
    });

    test('multi-locus carrier mutations never contain duplicates', () {
      // Sex-linked carrier (pearly) + autosomal carrier (blue) + spangle
      // This combination previously caused Pearly to appear twice:
      // once from phenotype name and once from mutation ID.
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'pearly': AlleleState.carrier,
          'blue': AlleleState.carrier,
          'spangle': AlleleState.visual,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'pearly': AlleleState.visual, 'blue': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);

      for (final r in results) {
        expect(
          r.carriedMutations.toSet().length,
          r.carriedMutations.length,
          reason:
              '${r.compoundPhenotype ?? r.phenotype} has duplicate '
              'carriedMutations: ${r.carriedMutations}',
        );
      }
    });
  });
}
