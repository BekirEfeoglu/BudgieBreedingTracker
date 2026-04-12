import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

/// Targeted tests for allele_resolver_compounds.dart (part of mendelian_calculator).
///
/// These tests exercise _resolveDilutionCompound, _resolveBlueSeriesCompound,
/// and _resolveInoCompound through the public MendelianCalculator API by
/// creating compound heterozygote crosses at the respective allelic loci.
void main() {
  const calculator = MendelianCalculator();

  // Helper: cross father (visual allele1) x mother (visual allele2) to
  // produce compound heterozygote males at a sex-linked locus.
  List<OffspringResult> crossSexLinked(String allele1, String allele2) {
    final father = ParentGenotype(
      gender: BirdGender.male,
      mutations: {allele1: AlleleState.visual},
    );
    final mother = ParentGenotype(
      gender: BirdGender.female,
      mutations: {allele2: AlleleState.visual},
    );
    return calculator.calculateFromGenotypes(
      father: father,
      mother: mother,
    );
  }

  // Helper: cross father (visual allele1) x mother (visual allele2) for
  // autosomal allelic locus (both parents homozygous).
  List<OffspringResult> crossAutosomal(String allele1, String allele2) {
    final father = ParentGenotype(
      gender: BirdGender.male,
      mutations: {allele1: AlleleState.visual},
    );
    final mother = ParentGenotype(
      gender: BirdGender.female,
      mutations: {allele2: AlleleState.visual},
    );
    return calculator.calculateFromGenotypes(
      father: father,
      mother: mother,
    );
  }

  group('Dilution locus compound heterozygotes', () {
    test('greywing x clearwing produces Full-Body Greywing', () {
      final results = crossAutosomal('greywing', 'clearwing');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Full-Body Greywing'),
        isTrue,
        reason: 'Greywing/Clearwing compound = Full-Body Greywing',
      );
    });

    test('greywing x dilute produces Greywing phenotype (dilute carried)', () {
      final results = crossAutosomal('greywing', 'dilute');

      expect(results, isNotEmpty);
      final compoundResults = results.where(
        (r) => r.phenotype == 'Greywing',
      );
      expect(compoundResults, isNotEmpty);
      // The compound heterozygote should carry dilute
      expect(
        compoundResults.any((r) => r.carriedMutations.contains('dilute')),
        isTrue,
      );
    });

    test('clearwing x dilute produces Clearwing phenotype (dilute carried)', () {
      final results = crossAutosomal('clearwing', 'dilute');

      expect(results, isNotEmpty);
      final compoundResults = results.where(
        (r) => r.phenotype == 'Clearwing',
      );
      expect(compoundResults, isNotEmpty);
      expect(
        compoundResults.any((r) => r.carriedMutations.contains('dilute')),
        isTrue,
      );
    });

    test('clearwing x greywing also produces Full-Body Greywing (order independent)', () {
      final results = crossAutosomal('clearwing', 'greywing');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Full-Body Greywing'),
        isTrue,
      );
    });

    test('dilute x greywing produces Greywing (same as greywing x dilute)', () {
      final results = crossAutosomal('dilute', 'greywing');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Greywing'),
        isTrue,
      );
    });

    test('dilute x clearwing produces Clearwing (same as clearwing x dilute)', () {
      final results = crossAutosomal('dilute', 'clearwing');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Clearwing'),
        isTrue,
      );
    });
  });

  group('Blue series locus compound heterozygotes', () {
    test('yellowface_type2 x blue produces Yellowface Type II Blue', () {
      final results = crossAutosomal('yellowface_type2', 'blue');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Yellowface Type II Blue'),
        isTrue,
      );
    });

    test('yellowface_type1 x blue produces Yellowface Type I Blue', () {
      final results = crossAutosomal('yellowface_type1', 'blue');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Yellowface Type I Blue'),
        isTrue,
      );
    });

    test('yellowface_type2 x yellowface_type1 produces Yellowface Type II', () {
      final results = crossAutosomal('yellowface_type2', 'yellowface_type1');

      expect(results, isNotEmpty);
      // Yf2 dominates Yf1, Yf1 should be carried
      expect(
        results.any(
          (r) =>
              r.phenotype == 'Yellowface Type II' &&
              r.carriedMutations.contains('yellowface_type1'),
        ),
        isTrue,
      );
    });

    test('goldenface x blue produces Goldenface Blue', () {
      final results = crossAutosomal('goldenface', 'blue');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Goldenface Blue'),
        isTrue,
      );
    });

    test('turquoise x blue produces Turquoise Blue', () {
      final results = crossAutosomal('turquoise', 'blue');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Turquoise Blue'),
        isTrue,
      );
    });

    test('aqua x blue produces Aqua Blue', () {
      final results = crossAutosomal('aqua', 'blue');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Aqua Blue'),
        isTrue,
      );
    });

    test('turquoise x aqua produces Turquoise Aqua (co-expressed parblue)', () {
      final results = crossAutosomal('turquoise', 'aqua');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Turquoise Aqua'),
        isTrue,
      );
    });

    test('bluefactor_1 x blue produces Blue Factor I Blue', () {
      final results = crossAutosomal('bluefactor_1', 'blue');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Blue Factor I Blue'),
        isTrue,
      );
    });

    test('bluefactor_2 x blue produces Blue Factor II Blue', () {
      final results = crossAutosomal('bluefactor_2', 'blue');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Blue Factor II Blue'),
        isTrue,
      );
    });

    test('bluefactor_2 x bluefactor_1 produces Blue Factor II (bf1 carried)', () {
      final results = crossAutosomal('bluefactor_2', 'bluefactor_1');

      expect(results, isNotEmpty);
      expect(
        results.any(
          (r) =>
              r.phenotype == 'Blue Factor II' &&
              r.carriedMutations.contains('bluefactor_1'),
        ),
        isTrue,
      );
    });

    test('blue x yellowface_type2 is symmetric', () {
      final forward = crossAutosomal('yellowface_type2', 'blue');
      final reverse = crossAutosomal('blue', 'yellowface_type2');

      expect(forward.length, reverse.length);
      // Both should produce Yellowface Type II Blue
      expect(
        forward.any((r) => r.phenotype == 'Yellowface Type II Blue'),
        isTrue,
      );
      expect(
        reverse.any((r) => r.phenotype == 'Yellowface Type II Blue'),
        isTrue,
      );
    });
  });

  group('Ino locus compound heterozygotes', () {
    test('pallid x ino produces PallidIno (Lacewing)', () {
      final results = crossSexLinked('pallid', 'ino');

      expect(results, isNotEmpty);
      final males = results.where((r) => r.sex == OffspringSex.male).toList();
      expect(males, isNotEmpty);
      // Males should have both pallid and ino expressed
      expect(
        males.any(
          (r) =>
              r.visualMutations.contains('pallid') &&
              r.visualMutations.contains('ino'),
        ),
        isTrue,
      );
    });

    test('texas_clearbody x ino produces Texas Clearbody (ino carried)', () {
      final results = crossSexLinked('texas_clearbody', 'ino');

      expect(results, isNotEmpty);
      final males = results.where((r) => r.sex == OffspringSex.male).toList();
      expect(males, isNotEmpty);
      expect(
        males.any(
          (r) =>
              r.visualMutations.contains('texas_clearbody') &&
              r.carriedMutations.contains('ino'),
        ),
        isTrue,
      );
    });

    test('texas_clearbody x pallid produces Pallid Texas Clearbody', () {
      final results = crossSexLinked('texas_clearbody', 'pallid');

      expect(results, isNotEmpty);
      final males = results.where((r) => r.sex == OffspringSex.male).toList();
      expect(males, isNotEmpty);
      // Both expressed in compound heterozygote
      expect(
        males.any(
          (r) =>
              r.visualMutations.contains('pallid') &&
              r.visualMutations.contains('texas_clearbody'),
        ),
        isTrue,
      );
    });

    test('pearly x ino produces Pearly (ino carried)', () {
      final results = crossSexLinked('pearly', 'ino');

      expect(results, isNotEmpty);
      final males = results.where((r) => r.sex == OffspringSex.male).toList();
      expect(males, isNotEmpty);
      expect(
        males.any(
          (r) =>
              r.visualMutations.contains('pearly') &&
              r.carriedMutations.contains('ino'),
        ),
        isTrue,
      );
    });

    test('texas_clearbody x pearly produces Texas Clearbody (pearly carried)', () {
      final results = crossSexLinked('texas_clearbody', 'pearly');

      expect(results, isNotEmpty);
      final males = results.where((r) => r.sex == OffspringSex.male).toList();
      expect(males, isNotEmpty);
      expect(
        males.any(
          (r) =>
              r.visualMutations.contains('texas_clearbody') &&
              r.carriedMutations.contains('pearly'),
        ),
        isTrue,
      );
    });

    test('pearly x pallid produces Pallid Pearly (both expressed)', () {
      final results = crossSexLinked('pearly', 'pallid');

      expect(results, isNotEmpty);
      final males = results.where((r) => r.sex == OffspringSex.male).toList();
      expect(males, isNotEmpty);
      expect(
        males.any(
          (r) =>
              r.visualMutations.contains('pearly') &&
              r.visualMutations.contains('pallid'),
        ),
        isTrue,
      );
    });

    test('ino x pallid is symmetric to pallid x ino for male offspring', () {
      final forward = crossSexLinked('pallid', 'ino');
      final reverse = crossSexLinked('ino', 'pallid');

      // Both should produce compound het males
      final forwardMales = forward
          .where((r) => r.sex == OffspringSex.male)
          .toList();
      final reverseMales = reverse
          .where((r) => r.sex == OffspringSex.male)
          .toList();

      expect(forwardMales, isNotEmpty);
      expect(reverseMales, isNotEmpty);

      // Both should have pallid+ino expressed
      final forwardHasCompound = forwardMales.any(
        (r) =>
            r.visualMutations.contains('pallid') &&
            r.visualMutations.contains('ino'),
      );
      final reverseHasCompound = reverseMales.any(
        (r) =>
            r.visualMutations.contains('pallid') &&
            r.visualMutations.contains('ino'),
      );
      expect(forwardHasCompound, isTrue);
      expect(reverseHasCompound, isTrue);
    });
  });

  group('Compound heterozygote probability verification', () {
    test('greywing x clearwing produces 100% Full-Body Greywing', () {
      final results = crossAutosomal('greywing', 'clearwing');

      // Both parents homozygous at same locus → all offspring are compound het
      expect(results, hasLength(1));
      expect(results.single.phenotype, 'Full-Body Greywing');
      expect(results.single.probability, closeTo(1.0, 0.0001));
    });

    test('yellowface_type2 x blue produces 100% Yellowface Type II Blue', () {
      final results = crossAutosomal('yellowface_type2', 'blue');

      expect(results, hasLength(1));
      expect(results.single.phenotype, 'Yellowface Type II Blue');
      expect(results.single.probability, closeTo(1.0, 0.0001));
    });

    test('turquoise x aqua produces 100% Turquoise Aqua', () {
      final results = crossAutosomal('turquoise', 'aqua');

      expect(results, hasLength(1));
      expect(results.single.phenotype, 'Turquoise Aqua');
      expect(results.single.probability, closeTo(1.0, 0.0001));
    });
  });

  group('Compound heterozygote genotype strings', () {
    test('greywing x clearwing produces gw/cw genotype', () {
      final results = crossAutosomal('greywing', 'clearwing');

      expect(results, isNotEmpty);
      final compound = results.firstWhere(
        (r) => r.phenotype == 'Full-Body Greywing',
      );
      expect(compound.genotype, isNotNull);
      // Genotype should contain both symbols
      expect(compound.genotype, contains('gw'));
      expect(compound.genotype, contains('cw'));
    });

    test('yellowface_type2 x blue genotype contains Yf2 and bl', () {
      final results = crossAutosomal('yellowface_type2', 'blue');

      expect(results, isNotEmpty);
      final compound = results.firstWhere(
        (r) => r.phenotype == 'Yellowface Type II Blue',
      );
      expect(compound.genotype, isNotNull);
      expect(compound.genotype, contains('Yf2'));
      expect(compound.genotype, contains('bl'));
    });
  });

  group('Dilution locus fallback behavior', () {
    test('homozygous greywing x homozygous greywing produces Greywing', () {
      final results = crossAutosomal('greywing', 'greywing');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Greywing'),
        isTrue,
      );
    });

    test('homozygous dilute x homozygous dilute produces Dilute', () {
      final results = crossAutosomal('dilute', 'dilute');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Dilute'),
        isTrue,
      );
    });
  });

  group('Blue series locus fallback behavior', () {
    test('homozygous blue x homozygous blue produces Blue', () {
      final results = crossAutosomal('blue', 'blue');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Blue'),
        isTrue,
      );
    });

    test('homozygous goldenface x homozygous goldenface produces Goldenface', () {
      final results = crossAutosomal('goldenface', 'goldenface');

      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.phenotype == 'Goldenface'),
        isTrue,
      );
    });
  });

  group('Ino locus fallback behavior', () {
    test('homozygous ino x ino female produces Ino offspring', () {
      final results = crossSexLinked('ino', 'ino');

      expect(results, isNotEmpty);
      // All offspring should express ino
      for (final r in results) {
        expect(r.visualMutations, contains('ino'));
      }
    });

    test('homozygous pallid x pallid female produces Pallid offspring', () {
      final results = crossSexLinked('pallid', 'pallid');

      expect(results, isNotEmpty);
      // Both male and female offspring should express pallid
      for (final r in results) {
        expect(r.visualMutations, contains('pallid'));
      }
    });
  });
}
