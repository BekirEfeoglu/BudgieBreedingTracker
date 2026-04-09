import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import 'genetics_test_helpers.dart';

void main() {
  const calculator = MendelianCalculator();

  // =====================================================================
  // 5. Z CHROMOSOME LINKAGE (Cinnamon + Ino)
  // =====================================================================
  group('Z chromosome linkage (Cinnamon-Ino)', () {
    test('coupling: carrier male x normal female → Lacewing daughters from parental gametes', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);

      // Lacewing females from parental gametes (~24.25%)
      final lacewingFemale = findResult(
        results,
        'Lacewing',
        sex: OffspringSex.female,
      );
      expect(lacewingFemale, isNotNull);
      expect(lacewingFemale!.probability, greaterThan(0.20));

      // Recombinant daughters should be rare (Cin-Ino ~3%)
      final cinOnlyFemale = findResult(
        results,
        'Cinnamon',
        sex: OffspringSex.female,
      );
      if (cinOnlyFemale != null) {
        expect(cinOnlyFemale.probability, lessThan(0.05));
      }
    });

    test('repulsion: split male x normal female → recombinant Lacewings rare', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.split,
          'ino': AlleleState.split,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);

      // In repulsion, Lacewing females are RECOMBINANT (rare ~1.5%)
      final lacewingFemale = findResult(
        results,
        'Lacewing',
        sex: OffspringSex.female,
      );
      if (lacewingFemale != null) {
        expect(lacewingFemale.probability, lessThan(0.05));
      }

      // Parental types: Cinnamon-only and Ino-only females should be common
      final cinFemale = results.where(
        (r) =>
            r.sex == OffspringSex.female &&
            r.phenotype == 'Cinnamon',
      );
      final inoFemale = results.where(
        (r) =>
            r.sex == OffspringSex.female &&
            r.phenotype == 'Ino',
      );
      expect(cinFemale.isNotEmpty || inoFemale.isNotEmpty, isTrue);
    });
  });

  // =====================================================================
  // 20. OPALINE-SLATE LINKAGE (wider recombination)
  // =====================================================================
  group('Opaline-Slate linkage', () {
    test('carrier male produces both parental and recombinant daughters', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'opaline': AlleleState.carrier,
          'slate': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);

      final femaleResults = results.where(
        (r) => r.sex == OffspringSex.female,
      );
      expect(femaleResults.length, greaterThanOrEqualTo(2));
    });
  });

  // =====================================================================
  // 22. CIN-INO EXPLICIT LINKAGE (3 cM)
  // Wider tolerance (0.02) due to recombination frequency approximation.
  // =====================================================================
  group('Cin-Ino explicit linkage (3 cM)', () {
    test('coupling: parental gametes ~48.5% each, recombinant ~1.5% each', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);

      // Parental Lacewing females: ~(1-0.03)/2 * 0.5 = ~24.25%
      final lacewingFemale = findResult(
        results,
        'Lacewing',
        sex: OffspringSex.female,
      );
      expect(lacewingFemale, isNotNull);
      expect(lacewingFemale!.probability, closeTo(0.2425, 0.02));

      // Recombinant Cinnamon-only females: ~0.03/2 * 0.5 = ~0.75%
      final cinOnlyFemale = findResult(
        results,
        'Cinnamon',
        sex: OffspringSex.female,
      );
      if (cinOnlyFemale != null) {
        expect(cinOnlyFemale.probability, closeTo(0.0075, 0.005));
      }

      // Recombinant Ino-only females: ~0.03/2 * 0.5 = ~0.75%
      final inoOnlyFemale = results
          .where(
            (r) =>
                r.sex == OffspringSex.female &&
                r.phenotype == 'Ino' &&
                !r.visualMutations.contains('cinnamon'),
          )
          .toList();
      if (inoOnlyFemale.isNotEmpty) {
        expect(inoOnlyFemale.first.probability, closeTo(0.0075, 0.005));
      }

      // Normal females (parental wildtype): ~24.25%
      final normalFemale = sumProbability(
        results,
        'Normal',
        sex: OffspringSex.female,
      );
      expect(normalFemale, closeTo(0.2425, 0.02));
    });

    test('repulsion: recombinant Lacewing rare, parental singles common', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.split,
          'ino': AlleleState.split,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);

      // Recombinant Lacewing females: ~0.03/2 * 0.5 = ~0.75%
      final lacewingFemale = findResult(
        results,
        'Lacewing',
        sex: OffspringSex.female,
      );
      if (lacewingFemale != null) {
        expect(lacewingFemale.probability, closeTo(0.0075, 0.005));
      }

      // Parental Cinnamon-only females: ~24.25%
      final cinFemale = sumProbability(
        results,
        'Cinnamon',
        sex: OffspringSex.female,
      );
      expect(cinFemale, closeTo(0.2425, 0.02));

      // Parental Ino-only females: ~24.25%
      final inoFemaleProb = results
          .where(
            (r) =>
                r.sex == OffspringSex.female &&
                r.phenotype == 'Ino' &&
                !r.visualMutations.contains('cinnamon'),
          )
          .fold<double>(0, (s, r) => s + r.probability);
      expect(inoFemaleProb, closeTo(0.2425, 0.02));
    });
  });

  // =====================================================================
  // 23. INO-SLATE EXPLICIT LINKAGE (2 cM)
  // Wider tolerance (0.02) due to recombination frequency approximation.
  // =====================================================================
  group('Ino-Slate explicit linkage (2 cM)', () {
    test('coupling: parental compound daughters dominate, recombinant rare', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'ino': AlleleState.carrier,
          'slate': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);

      // Parental compound (Ino+Slate) females: ~(1-0.02)/2 * 0.5 = ~24.5%
      final compoundFemale = results.where(
        (r) =>
            r.sex == OffspringSex.female &&
            r.visualMutations.contains('ino') &&
            r.visualMutations.contains('slate'),
      );
      expect(compoundFemale, isNotEmpty);
      final compoundProb = compoundFemale.fold<double>(
        0,
        (s, r) => s + r.probability,
      );
      expect(compoundProb, closeTo(0.245, 0.02));

      // Parental Normal females: ~24.5%
      final normalFemale = sumProbability(
        results,
        'Normal',
        sex: OffspringSex.female,
      );
      expect(normalFemale, closeTo(0.245, 0.02));

      // Recombinant single-mutation females: each ~0.5%
      final inoOnlyFemale = results.where(
        (r) =>
            r.sex == OffspringSex.female &&
            r.visualMutations.contains('ino') &&
            !r.visualMutations.contains('slate'),
      );
      final slateOnlyFemale = results.where(
        (r) =>
            r.sex == OffspringSex.female &&
            r.visualMutations.contains('slate') &&
            !r.visualMutations.contains('ino'),
      );
      final recombProb = inoOnlyFemale.fold<double>(
            0,
            (s, r) => s + r.probability,
          ) +
          slateOnlyFemale.fold<double>(0, (s, r) => s + r.probability);
      // Total recombinant females: ~0.02 * 0.5 = ~1%
      expect(recombProb, closeTo(0.01, 0.008));
    });

    test('repulsion: singles common, compound rare', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'ino': AlleleState.split,
          'slate': AlleleState.split,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);

      // Parental Ino-only females: ~24.5%
      final inoOnlyFemale = results
          .where(
            (r) =>
                r.sex == OffspringSex.female &&
                r.visualMutations.contains('ino') &&
                !r.visualMutations.contains('slate'),
          )
          .fold<double>(0, (s, r) => s + r.probability);
      expect(inoOnlyFemale, closeTo(0.245, 0.02));

      // Parental Slate-only females: ~24.5%
      final slateOnlyFemale = results
          .where(
            (r) =>
                r.sex == OffspringSex.female &&
                r.visualMutations.contains('slate') &&
                !r.visualMutations.contains('ino'),
          )
          .fold<double>(0, (s, r) => s + r.probability);
      expect(slateOnlyFemale, closeTo(0.245, 0.02));

      // Recombinant compound (Ino+Slate) females: ~0.5%
      final compoundFemale = results
          .where(
            (r) =>
                r.sex == OffspringSex.female &&
                r.visualMutations.contains('ino') &&
                r.visualMutations.contains('slate'),
          )
          .fold<double>(0, (s, r) => s + r.probability);
      expect(compoundFemale, closeTo(0.005, 0.005));
    });
  });
}
