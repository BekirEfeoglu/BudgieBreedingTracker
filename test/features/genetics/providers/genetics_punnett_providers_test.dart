import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

void main() {
  group('SelectedPunnettLocusNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedPunnettLocusProvider), isNull);
    });

    test('can be set to a locus ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedPunnettLocusProvider.notifier).state =
          'blue_series';
      expect(container.read(selectedPunnettLocusProvider), 'blue_series');
    });

    test('can be cleared back to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedPunnettLocusProvider.notifier).state =
          'blue_series';
      container.read(selectedPunnettLocusProvider.notifier).state = null;
      expect(container.read(selectedPunnettLocusProvider), isNull);
    });
  });

  group('availablePunnettLociProvider', () {
    test('returns empty when both parents have no mutations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(availablePunnettLociProvider), isEmpty);
    });

    test('returns union of father and mother mutation loci', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'opaline': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      expect(loci, containsAll(['blue_series', 'opaline']));
    });

    test('deduplicates allelic series mutations to single locus', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // greywing and clearwing share the 'dilution' locus
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'greywing': AlleleState.visual},
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'clearwing': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      // Both map to 'dilution' locus, should appear only once
      final dilutionCount = loci.where((l) => l == 'dilution').length;
      expect(dilutionCount, 1);
    });

    test('returns sorted loci list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.visual},
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      // blue_series sorts before opaline alphabetically
      expect(loci, ['blue_series', 'opaline']);
    });

    test('handles mutation with no locusId by using its own ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // recessive_pied has no locusId, uses its own mutation ID
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'recessive_pied': AlleleState.visual},
      );

      final loci = container.read(availablePunnettLociProvider);
      expect(loci, contains('recessive_pied'));
    });
  });

  group('effectivePunnettLocusProvider', () {
    test('returns null when no loci are available', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(effectivePunnettLocusProvider), isNull);
    });

    test('returns selected locus when it is in available list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual, 'opaline': AlleleState.visual},
      );
      container.read(selectedPunnettLocusProvider.notifier).state = 'opaline';

      expect(container.read(effectivePunnettLocusProvider), 'opaline');
    });

    test(
      'falls back to first available locus when selected is not in list',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'blue': AlleleState.visual},
        );
        container.read(selectedPunnettLocusProvider.notifier).state =
            'nonexistent';

        expect(container.read(effectivePunnettLocusProvider), 'blue_series');
      },
    );

    test('falls back to first when selected locus is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );

      // selectedPunnettLocusProvider defaults to null
      expect(container.read(effectivePunnettLocusProvider), 'blue_series');
    });

    test(
      'updates when parent genotype changes and selected becomes invalid',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'blue': AlleleState.visual,
            'opaline': AlleleState.visual,
          },
        );
        container.read(selectedPunnettLocusProvider.notifier).state = 'opaline';
        expect(container.read(effectivePunnettLocusProvider), 'opaline');

        // Remove opaline from father — now only blue is available
        container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'blue': AlleleState.visual},
        );

        // Should fall back since opaline is no longer available
        expect(container.read(effectivePunnettLocusProvider), 'blue_series');
      },
    );
  });

  group('punnettSquareProvider', () {
    test('returns null when both parents are empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(punnettSquareProvider), isNull);
    });

    test('returns null when no effective locus is selected', () {
      // Empty parents means no available loci, so effectivePunnettLocus is null
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(punnettSquareProvider), isNull);
    });

    test('builds punnett square for selected locus', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );

      final square = container.read(punnettSquareProvider)!;
      expect(square.cells, isNotEmpty);
      expect(square.mutationName, isNotEmpty);
      expect(square.fatherAlleles, isNotEmpty);
      expect(square.motherAlleles, isNotEmpty);
    });

    test('punnett square changes when effective locus changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual, 'opaline': AlleleState.visual},
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier, 'opaline': AlleleState.visual},
      );

      container.read(selectedPunnettLocusProvider.notifier).state =
          'blue_series';
      final squareBlue = container.read(punnettSquareProvider)!;

      container.read(selectedPunnettLocusProvider.notifier).state = 'opaline';
      final squareOpaline = container.read(punnettSquareProvider)!;

      expect(squareBlue.mutationName, isNot(squareOpaline.mutationName));
    });
  });

  group('SelectedPunnettLocus2Notifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedPunnettLocus2Provider), isNull);
    });

    test('can be set to a locus ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedPunnettLocus2Provider.notifier).state = 'opaline';
      expect(container.read(selectedPunnettLocus2Provider), 'opaline');
    });
  });

  group('dihybridPunnettSquareProvider', () {
    test('returns null when both parents are empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(dihybridPunnettSquareProvider), isNull);
    });

    test('returns null when only one locus is selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual, 'opaline': AlleleState.visual},
      );
      // locus2 is null by default
      expect(container.read(dihybridPunnettSquareProvider), isNull);
    });

    test('returns null when both loci are the same', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      // effectivePunnettLocus will be blue_series
      container.read(selectedPunnettLocus2Provider.notifier).state =
          'blue_series';

      expect(container.read(dihybridPunnettSquareProvider), isNull);
    });

    test('returns null when locus2 is not in available loci', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container.read(selectedPunnettLocus2Provider.notifier).state =
          'nonexistent_locus';

      expect(container.read(dihybridPunnettSquareProvider), isNull);
    });

    test(
      'builds dihybrid square when two valid distinct loci are selected',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'blue': AlleleState.visual,
            'opaline': AlleleState.visual,
          },
        );
        container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
          gender: BirdGender.female,
          mutations: {
            'blue': AlleleState.carrier,
            'opaline': AlleleState.visual,
          },
        );

        // effectivePunnettLocus will be blue_series (first sorted)
        container.read(selectedPunnettLocus2Provider.notifier).state =
            'opaline';

        final dihybrid = container.read(dihybridPunnettSquareProvider)!;
        expect(dihybrid.cells, isNotEmpty);
      },
    );
  });
}
