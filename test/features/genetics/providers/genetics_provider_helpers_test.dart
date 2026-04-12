import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

void main() {
  group('_extractVisualMutationIds (via fatherMutationsProvider)', () {
    test('returns empty set for empty genotype', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(fatherMutationsProvider), isEmpty);
    });

    test('includes visual autosomal recessive mutations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );

      expect(container.read(fatherMutationsProvider), contains('blue'));
    });

    test('excludes carrier autosomal recessive mutations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.carrier},
      );

      expect(container.read(fatherMutationsProvider), isNot(contains('blue')));
    });

    test('includes carrier/split for autosomal dominant mutations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // spangle is autosomal incomplete dominant — SF (carrier) is still visual
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'spangle': AlleleState.carrier},
      );

      expect(container.read(fatherMutationsProvider), contains('spangle'));
    });

    test('all sex-linked mutations are visual for female', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // For female, sex-linked mutations are always visual (hemizygous)
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.visual, 'opaline': AlleleState.visual},
      );

      final mutations = container.read(motherMutationsProvider);
      expect(mutations, containsAll(['ino', 'opaline']));
    });

    test('sex-linked carrier in male is not visual', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // For male, sex-linked carrier is NOT visual (heterozygous)
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.carrier},
      );

      expect(container.read(fatherMutationsProvider), isNot(contains('ino')));
    });

    test('sex-linked visual in male IS visual', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.visual},
      );

      expect(container.read(fatherMutationsProvider), contains('ino'));
    });

    test('handles mixed mutation types correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual, // autosomal recessive, visual -> yes
          'violet': AlleleState
              .carrier, // autosomal incomplete dominant carrier -> yes
          'ino': AlleleState
              .carrier, // sex-linked recessive, carrier in male -> no
          'spangle':
              AlleleState.visual, // autosomal incomplete dominant visual -> yes
        },
      );

      final mutations = container.read(fatherMutationsProvider);
      expect(mutations, contains('blue'));
      expect(mutations, contains('spangle'));
      expect(mutations, isNot(contains('ino')));
      // violet as autosomal incomplete dominant carrier should be visual
      expect(mutations, contains('violet'));
    });

    test('unknown mutations in database are skipped', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'nonexistent_mutation': AlleleState.visual},
      );

      // Unknown mutation should be skipped (MutationDatabase returns null)
      expect(
        container.read(fatherMutationsProvider),
        isNot(contains('nonexistent_mutation')),
      );
    });
  });

  group('_punnettLocusSortKey (via availablePunnettLociProvider sorting)', () {
    test('sorts loci alphabetically by mutation name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.visual, 'blue': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      expect(loci, isNotEmpty);
      expect(loci, containsAll(['blue_series', 'opaline']));
      final indexBlue = loci.indexOf('blue_series');
      final indexOpaline = loci.indexOf('opaline');
      expect(indexBlue, greaterThanOrEqualTo(0));
      expect(indexOpaline, greaterThanOrEqualTo(0));
      expect(indexBlue, lessThan(indexOpaline));
    });

    test('uses known locus display names for sorting', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 'blue' maps to 'blue_series' locus which has display name 'Blue Series'
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      expect(loci, contains('blue_series'));
    });
  });
}
