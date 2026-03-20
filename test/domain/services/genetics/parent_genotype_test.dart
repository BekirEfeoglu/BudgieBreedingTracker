import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  group('AlleleState', () {
    test('abbreviation values are stable', () {
      expect(AlleleState.visual.abbreviation, 'V');
      expect(AlleleState.carrier.abbreviation, 'T');
      expect(AlleleState.split.abbreviation, 'S');
    });
  });

  group('ParentGenotype', () {
    test('empty constructor has no mutations', () {
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      expect(genotype.isEmpty, isTrue);
      expect(genotype.isNotEmpty, isFalse);
      expect(genotype.allMutationIds, isEmpty);
    });

    test('withMutation adds mutation immutably', () {
      const base = ParentGenotype.empty(gender: BirdGender.male);
      final updated = base.withMutation('blue', AlleleState.visual);

      expect(base.isEmpty, isTrue);
      expect(updated.isNotEmpty, isTrue);
      expect(updated.hasVisual('blue'), isTrue);
    });

    test('withoutMutation removes existing mutation', () {
      final genotype = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      final updated = genotype.withoutMutation('blue');

      expect(updated.isEmpty, isTrue);
      expect(genotype.isNotEmpty, isTrue);
    });

    test('visualMutations and carrierMutations split correctly', () {
      final genotype = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'opaline': AlleleState.carrier,
          'cinnamon': AlleleState.split,
        },
      );

      expect(genotype.visualMutations, {'blue'});
      expect(genotype.carrierMutations, {'opaline'});
      expect(genotype.allMutationIds, {'blue', 'opaline', 'cinnamon'});
      expect(genotype.getState('cinnamon'), AlleleState.split);
    });

    test('toggleState toggles visual/carrier for autosomal mutations', () {
      final genotype = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );

      final first = genotype.toggleState('blue');
      final second = first.toggleState('blue');

      expect(first.getState('blue'), AlleleState.carrier);
      expect(second.getState('blue'), AlleleState.visual);
    });

    test(
      'toggleState cycles visual->carrier->split->visual for sex-linked male',
      () {
        final genotype = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'opaline': AlleleState.visual},
        );

        final first = genotype.toggleState('opaline', isSexLinked: true);
        final second = first.toggleState('opaline', isSexLinked: true);
        final third = second.toggleState('opaline', isSexLinked: true);

        expect(first.getState('opaline'), AlleleState.carrier);
        expect(second.getState('opaline'), AlleleState.split);
        expect(third.getState('opaline'), AlleleState.visual);
      },
    );

    test('toggleState keeps sex-linked female as visual', () {
      final genotype = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'lutino': AlleleState.carrier},
      );

      final toggled = genotype.toggleState('lutino', isSexLinked: true);
      expect(toggled.getState('lutino'), AlleleState.visual);
    });

    test('toggleState on unknown mutation returns unchanged genotype', () {
      final genotype = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );

      final toggled = genotype.toggleState('nonexistent');
      expect(toggled, same(genotype));
    });

    test(
      'clear removes all mutations and visualMutations returns visuals only',
      () {
        final genotype = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'blue': AlleleState.visual,
            'opaline': AlleleState.carrier,
          },
        );

        expect(genotype.visualMutations, {'blue'});
        expect(genotype.clear().isEmpty, isTrue);
      },
    );

    test(
      'toggleState with unknown gender falls back to autosomal toggle for sex-linked',
      () {
        final genotype = ParentGenotype(
          gender: BirdGender.unknown,
          mutations: {'opaline': AlleleState.visual},
        );

        // Unknown gender should NOT enter the male 3-state cycle
        final toggled = genotype.toggleState('opaline', isSexLinked: true);
        expect(toggled.getState('opaline'), AlleleState.carrier);

        // Second toggle goes back to visual (autosomal 2-state cycle)
        final toggled2 = toggled.toggleState('opaline', isSexLinked: true);
        expect(toggled2.getState('opaline'), AlleleState.visual);
      },
    );

    group('canAddMutation', () {
      test('allows adding independent mutation without limit', () {
        final genotype = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'blue': AlleleState.visual,
            'opaline': AlleleState.visual,
            'cinnamon': AlleleState.visual,
          },
        );
        // 'grey' has no locusId (independent) → always allowed
        expect(genotype.canAddMutation('grey'), isTrue);
      });

      test('allows updating existing mutation at same locus', () {
        final genotype = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'greywing': AlleleState.visual,
            'clearwing': AlleleState.visual,
          },
        );
        // greywing is already selected → updating is allowed
        expect(genotype.canAddMutation('greywing'), isTrue);
      });

      test('blocks third mutation at same allelic locus', () {
        final genotype = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'greywing': AlleleState.visual,
            'clearwing': AlleleState.visual,
          },
        );
        // dilute is at 'dilution' locus, same as greywing/clearwing → blocked
        expect(genotype.canAddMutation('dilute'), isFalse);
      });

      test('female limited to 1 allele at sex-linked locus', () {
        final genotype = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.visual},
        );
        // pallid is at 'ino_locus' (sex-linked), female already has ino → blocked
        expect(genotype.canAddMutation('pallid'), isFalse);
      });

      test('male allows 2 alleles at sex-linked locus', () {
        final genotype = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'ino': AlleleState.visual},
        );
        // pallid is at 'ino_locus' (sex-linked), male can have 2 → allowed
        expect(genotype.canAddMutation('pallid'), isTrue);
      });
    });

    group('withMutationIfValid', () {
      test('adds mutation when valid', () {
        const genotype = ParentGenotype.empty(gender: BirdGender.male);
        final updated = genotype.withMutationIfValid(
          'blue',
          AlleleState.visual,
        );
        expect(updated.hasVisual('blue'), isTrue);
      });

      test('returns same instance when locus limit exceeded', () {
        final genotype = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'greywing': AlleleState.visual,
            'clearwing': AlleleState.visual,
          },
        );
        final result = genotype.withMutationIfValid(
          'dilute',
          AlleleState.visual,
        );
        // Should return unchanged genotype
        expect(result.mutations.containsKey('dilute'), isFalse);
        expect(result.mutations.length, 2);
      });
    });
  });
}
