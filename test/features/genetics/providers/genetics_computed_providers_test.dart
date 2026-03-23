import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

void main() {
  group('availablePunnettLociProvider — sort ordering', () {
    test('allelic series locusIds are used instead of individual mutation IDs',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 'blue' belongs to 'blue_series' locus; 'clearwing' belongs to 'dilution'
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'clearwing': AlleleState.visual,
        },
      );

      final loci = container.read(availablePunnettLociProvider);
      expect(loci, contains('blue_series'));
      expect(loci, contains('dilution'));
      // Individual mutation IDs should NOT appear
      expect(loci, isNot(contains('blue')));
      expect(loci, isNot(contains('clearwing')));
    });

    test('independent mutation IDs are used as-is when no locusId exists', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 'opaline' has no locusId; 'recessive_pied' has no locusId
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.visual},
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'recessive_pied': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      expect(loci, contains('opaline'));
      expect(loci, contains('recessive_pied'));
    });

    test(
        'allelic loci sort before independent mutations, '
        'alphabetical within groups', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set up mutations from different sort categories:
      // 'blue' -> blue_series (sort key '00')
      // 'clearwing' -> dilution (sort key '01')
      // 'opaline' -> independent (sort key 'opaline')
      // 'spangle' -> independent (sort key 'spangle')
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'spangle': AlleleState.visual,
          'blue': AlleleState.visual,
        },
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'opaline': AlleleState.visual,
          'clearwing': AlleleState.visual,
        },
      );

      final loci = container.read(availablePunnettLociProvider);

      // blue_series (00) and dilution (01) should come first
      // then opaline and spangle alphabetically
      expect(loci.length, 4);
      expect(loci[0], 'blue_series');
      expect(loci[1], 'dilution');
      // Independent mutations sorted alphabetically after allelic loci
      expect(loci.indexOf('opaline'), lessThan(loci.indexOf('spangle')));
    });

    test('empty case — both parents empty returns empty list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Both parents default to empty genotypes
      final loci = container.read(availablePunnettLociProvider);
      expect(loci, isEmpty);
    });

    test('deduplicates mutations sharing the same locus across parents', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Both parents have mutations at the 'dilution' locus
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'greywing': AlleleState.visual},
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'clearwing': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      final dilutionCount = loci.where((l) => l == 'dilution').length;
      expect(dilutionCount, 1);
    });
  });

  group('effectivePunnettLocusProvider — fallback behavior', () {
    test('returns selected locus when it is in the available list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'opaline': AlleleState.visual,
        },
      );

      // Manually select 'opaline'
      container.read(selectedPunnettLocusProvider.notifier).state = 'opaline';
      expect(container.read(effectivePunnettLocusProvider), 'opaline');
    });

    test('falls back to first available when selected is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );

      // selectedPunnettLocusProvider defaults to null
      expect(container.read(effectivePunnettLocusProvider), 'blue_series');
    });

    test('falls back to first available when selected is NOT in the list '
        '(stale selection)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.visual},
      );

      // Set a stale selection that does not match available loci
      container.read(selectedPunnettLocusProvider.notifier).state =
          'blue_series';

      // Should fall back to first available since 'blue_series' is not there
      expect(container.read(effectivePunnettLocusProvider), 'opaline');
    });

    test('returns null when no loci are available', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Both parents empty — no loci available
      expect(container.read(effectivePunnettLocusProvider), isNull);
    });

    test('tracks parent genotype changes and recovers from stale selection',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Start with two mutations
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'opaline': AlleleState.visual,
        },
      );
      container.read(selectedPunnettLocusProvider.notifier).state = 'opaline';
      expect(container.read(effectivePunnettLocusProvider), 'opaline');

      // Remove opaline — selection becomes stale
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );

      // Should auto-fallback to first available
      expect(container.read(effectivePunnettLocusProvider), 'blue_series');
    });
  });

  group('epistasisInteractionsProvider — deduplication', () {
    test('duplicate interaction names keep the one with highest probability',
        () {
      // Create two offspring results that both trigger 'Albino' interaction
      // but with different probabilities.
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Albino',
              probability: 0.25,
              visualMutations: ['ino', 'blue'],
            ),
            OffspringResult(
              phenotype: 'Albino (carrier)',
              probability: 0.50,
              visualMutations: ['ino', 'blue'],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      final interactions = container.read(epistasisInteractionsProvider);

      // 'Albino' should appear only once (deduplicated by resultName)
      final albinoInteractions =
          interactions.where((i) => i.resultName == 'Albino').toList();
      expect(albinoInteractions, hasLength(1));

      // Since both results trigger 'Albino', the one with prob 0.50 wins.
      // The list is also sorted by probability descending, so Albino is first.
      expect(interactions.first.resultName, 'Albino');
    });

    test('empty results produce empty interactions list', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const []),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(epistasisInteractionsProvider), isEmpty);
    });

    test('null results produce empty interactions list', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(epistasisInteractionsProvider), isEmpty);
    });

    test('results with no visual mutations produce no interactions', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Normal',
              probability: 1.0,
              visualMutations: [],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(epistasisInteractionsProvider), isEmpty);
    });

    test('multiple distinct interactions are all returned and sorted by '
        'highest probability', () {
      // ino + blue => Albino interaction
      // ino + cinnamon => Lacewing interaction
      // Both should appear independently.
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Lacewing Albino',
              probability: 0.10,
              visualMutations: ['ino', 'blue', 'cinnamon'],
            ),
            OffspringResult(
              phenotype: 'Albino',
              probability: 0.40,
              visualMutations: ['ino', 'blue'],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      final interactions = container.read(epistasisInteractionsProvider);

      // Should have Albino and Lacewing at minimum
      expect(interactions.length, greaterThanOrEqualTo(2));

      // Albino interaction appears in both results; highest prob is 0.40
      final albinoList =
          interactions.where((i) => i.resultName == 'Albino').toList();
      expect(albinoList, hasLength(1));

      // Verify descending probability order: Albino (0.40) before Lacewing (0.10)
      final idxAlbino =
          interactions.indexWhere((i) => i.resultName == 'Albino');
      final idxLacewing =
          interactions.indexWhere((i) => i.resultName == 'Lacewing');
      if (idxAlbino >= 0 && idxLacewing >= 0) {
        expect(idxAlbino, lessThan(idxLacewing));
      }
    });

    test('interactions from live parent genotypes with ino + blue produce '
        'Albino interaction', () {
      // Use real parent genotypes instead of overriding offspringResults
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'ino': AlleleState.visual,
          'blue': AlleleState.visual,
        },
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'ino': AlleleState.visual,
          'blue': AlleleState.visual,
        },
      );

      final interactions = container.read(epistasisInteractionsProvider);
      expect(interactions, isNotEmpty);
      expect(interactions.any((i) => i.resultName == 'Albino'), isTrue);
    });

    test('ino without blue produces Lutino interaction, not Albino', () {
      final container = ProviderContainer(
        overrides: [
          offspringResultsProvider.overrideWithValue(const [
            OffspringResult(
              phenotype: 'Lutino',
              probability: 1.0,
              visualMutations: ['ino'],
            ),
          ]),
        ],
      );
      addTearDown(container.dispose);

      final interactions = container.read(epistasisInteractionsProvider);
      expect(interactions.any((i) => i.resultName == 'Lutino'), isTrue);
      expect(interactions.any((i) => i.resultName == 'Albino'), isFalse);
    });
  });
}
