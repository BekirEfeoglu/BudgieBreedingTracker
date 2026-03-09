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
      'clear removes all mutations and toLegacySet returns visuals only',
      () {
        final genotype = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'blue': AlleleState.visual,
            'opaline': AlleleState.carrier,
          },
        );

        expect(genotype.toLegacySet(), {'blue'});
        expect(genotype.clear().isEmpty, isTrue);
      },
    );
  });
}
