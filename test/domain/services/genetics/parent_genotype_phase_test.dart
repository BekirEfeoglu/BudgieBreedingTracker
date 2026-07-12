import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_phase.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  group('ParentGenotype.phaseOverrides', () {
    test('empty genotype has no phase overrides', () {
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      expect(genotype.phaseOverrides, isEmpty);
      expect(genotype.phaseFor('ino', 'cinnamon'), LinkagePhase.auto);
    });

    test('withPhaseOverride sets coupling and phaseFor reads it back', () {
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      final updated = genotype.withPhaseOverride(
        'ino',
        'cinnamon',
        LinkagePhase.coupling,
      );

      expect(updated.phaseFor('ino', 'cinnamon'), LinkagePhase.coupling);
    });

    test('withPhaseOverride sets repulsion and phaseFor reads it back', () {
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      final updated = genotype.withPhaseOverride(
        'ino',
        'cinnamon',
        LinkagePhase.repulsion,
      );

      expect(updated.phaseFor('ino', 'cinnamon'), LinkagePhase.repulsion);
    });

    test('phaseFor is order-independent', () {
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      final updated = genotype.withPhaseOverride(
        'ino',
        'cinnamon',
        LinkagePhase.coupling,
      );

      expect(updated.phaseFor('cinnamon', 'ino'), LinkagePhase.coupling);
    });

    test('withPhaseOverride(auto) removes the override key', () {
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      final withOverride = genotype.withPhaseOverride(
        'ino',
        'cinnamon',
        LinkagePhase.coupling,
      );
      final cleared = withOverride.withPhaseOverride(
        'ino',
        'cinnamon',
        LinkagePhase.auto,
      );

      expect(cleared.phaseFor('ino', 'cinnamon'), LinkagePhase.auto);
      expect(cleared.phaseOverrides, isEmpty);
    });

    test('withMutation preserves existing phase overrides', () {
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      final withOverride = genotype.withPhaseOverride(
        'ino',
        'cinnamon',
        LinkagePhase.coupling,
      );
      final updated = withOverride.withMutation('slate', AlleleState.carrier);

      expect(updated.phaseFor('ino', 'cinnamon'), LinkagePhase.coupling);
      expect(updated.hasCarrier('slate'), isTrue);
    });

    test('toggleState preserves existing phase overrides', () {
      final genotype = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.visual, 'cinnamon': AlleleState.visual},
      ).withPhaseOverride('ino', 'cinnamon', LinkagePhase.repulsion);

      final toggled = genotype.toggleState('ino', isSexLinked: true);

      expect(toggled.phaseFor('ino', 'cinnamon'), LinkagePhase.repulsion);
    });

    test(
      'withoutMutation drops overrides referencing the removed id but keeps unrelated ones',
      () {
        const genotype = ParentGenotype.empty(gender: BirdGender.male);
        final withOverrides = genotype
            .withPhaseOverride('ino', 'cinnamon', LinkagePhase.coupling)
            .withPhaseOverride('pallid', 'slate', LinkagePhase.repulsion);

        final updated = withOverrides.withoutMutation('ino');

        expect(updated.phaseFor('ino', 'cinnamon'), LinkagePhase.auto);
        expect(updated.phaseFor('pallid', 'slate'), LinkagePhase.repulsion);
        expect(updated.phaseOverrides.length, 1);
      },
    );

    test('clear() returns empty phase overrides', () {
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      final withOverride = genotype.withPhaseOverride(
        'ino',
        'cinnamon',
        LinkagePhase.coupling,
      );

      final cleared = withOverride.clear();

      expect(cleared.phaseOverrides, isEmpty);
    });
  });
}
