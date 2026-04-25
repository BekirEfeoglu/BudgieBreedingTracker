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

  // =====================================================================
  // 24. INO-LOCUS ALLELE LINKAGE GENERALISATION
  //
  // Pallid, Pearly and Texas Clearbody all share the ino_locus physical
  // position on Z, so their linkage distance to cinnamon/slate/opaline is
  // the same as the canonical Ino distances. These tests lock in the
  // generalised linkage behaviour.
  // =====================================================================
  group('Ino-locus allele linkage generalisation', () {
    test(
      'pallid+cinnamon (coupling): compound daughters dominate, singles rare',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'pallid': AlleleState.carrier,
            'cinnamon': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expectNormalizedProbabilities(results);

        // Parental compound (Pallid+Cinnamon) females ≈ (1-0.03)/2 * 0.5
        final compoundFemale = results
            .where(
              (r) =>
                  r.sex == OffspringSex.female &&
                  r.visualMutations.contains('pallid') &&
                  r.visualMutations.contains('cinnamon'),
            )
            .fold<double>(0, (s, r) => s + r.probability);
        expect(compoundFemale, closeTo(0.2425, 0.02));

        // Recombinant Pallid-only and Cinnamon-only daughters ≈ 0.75% each.
        final pallidOnlyFemale = results
            .where(
              (r) =>
                  r.sex == OffspringSex.female &&
                  r.visualMutations.contains('pallid') &&
                  !r.visualMutations.contains('cinnamon'),
            )
            .fold<double>(0, (s, r) => s + r.probability);
        expect(pallidOnlyFemale, lessThan(0.03));

        final cinnamonOnlyFemale = results
            .where(
              (r) =>
                  r.sex == OffspringSex.female &&
                  r.visualMutations.contains('cinnamon') &&
                  !r.visualMutations.contains('pallid'),
            )
            .fold<double>(0, (s, r) => s + r.probability);
        expect(cinnamonOnlyFemale, lessThan(0.03));
      },
    );

    test(
      'pallid+cinnamon (repulsion): single-mutation daughters dominate',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'pallid': AlleleState.split,
            'cinnamon': AlleleState.split,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expectNormalizedProbabilities(results);

        final pallidOnlyFemale = results
            .where(
              (r) =>
                  r.sex == OffspringSex.female &&
                  r.visualMutations.contains('pallid') &&
                  !r.visualMutations.contains('cinnamon'),
            )
            .fold<double>(0, (s, r) => s + r.probability);
        expect(pallidOnlyFemale, closeTo(0.2425, 0.02));

        final cinnamonOnlyFemale = results
            .where(
              (r) =>
                  r.sex == OffspringSex.female &&
                  r.visualMutations.contains('cinnamon') &&
                  !r.visualMutations.contains('pallid'),
            )
            .fold<double>(0, (s, r) => s + r.probability);
        expect(cinnamonOnlyFemale, closeTo(0.2425, 0.02));

        final compoundFemale = results
            .where(
              (r) =>
                  r.sex == OffspringSex.female &&
                  r.visualMutations.contains('pallid') &&
                  r.visualMutations.contains('cinnamon'),
            )
            .fold<double>(0, (s, r) => s + r.probability);
        expect(compoundFemale, lessThan(0.03));
      },
    );

    test(
      'pearly+slate (coupling): compound daughters ≈ (1-0.02)/2 * 0.5',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'pearly': AlleleState.carrier,
            'slate': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expectNormalizedProbabilities(results);

        final compoundFemale = results
            .where(
              (r) =>
                  r.sex == OffspringSex.female &&
                  r.visualMutations.contains('pearly') &&
                  r.visualMutations.contains('slate'),
            )
            .fold<double>(0, (s, r) => s + r.probability);
        expect(compoundFemale, closeTo(0.245, 0.02));
      },
    );

    test(
      'texas_clearbody+cinnamon (coupling): compound daughters dominate',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'texas_clearbody': AlleleState.carrier,
            'cinnamon': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expectNormalizedProbabilities(results);

        final compoundFemale = results
            .where(
              (r) =>
                  r.sex == OffspringSex.female &&
                  r.visualMutations.contains('texas_clearbody') &&
                  r.visualMutations.contains('cinnamon'),
            )
            .fold<double>(0, (s, r) => s + r.probability);
        expect(compoundFemale, closeTo(0.2425, 0.02));
      },
    );

    test(
      'ino + pallid compound het in father: linkage skipped, allelic series '
      'handles ino_locus, cinnamon remains independent',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'ino': AlleleState.carrier,
            'pallid': AlleleState.carrier,
            'cinnamon': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expectNormalizedProbabilities(results);
        expect(results, isNotEmpty);

        // Both ino and pallid should remain expressible in offspring because
        // neither is silently dropped by the linkage branch.
        final hasInoDaughter = results.any(
          (r) =>
              r.sex == OffspringSex.female &&
              r.visualMutations.contains('ino'),
        );
        final hasPallidDaughter = results.any(
          (r) =>
              r.sex == OffspringSex.female &&
              r.visualMutations.contains('pallid'),
        );
        expect(hasInoDaughter, isTrue);
        expect(hasPallidDaughter, isTrue);
      },
    );
  });
}
