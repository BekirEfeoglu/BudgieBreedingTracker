import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Result combiner behavior', () {
    test('simple API normalizes duplicate phenotype buckets across loci', () {
      final results = calculator.calculateOffspring(
        fatherMutations: {'blue', 'recessive_pied'},
        motherMutations: {'blue', 'recessive_pied'},
      );

      expect(results, hasLength(2));
      expect(results.map((r) => r.phenotype).toSet(), {
        'Blue',
        'Recessive Pied',
      });
      expect(results.first.probability, closeTo(0.5, 0.0001));
      expect(results.last.probability, closeTo(0.5, 0.0001));
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
