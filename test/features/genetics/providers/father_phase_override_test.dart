import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_phase.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

void main() {
  group('FatherGenotypeNotifier.setPhaseOverride', () {
    test('sets an explicit coupling override for a linked pair', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      );

      container
          .read(fatherGenotypeProvider.notifier)
          .setPhaseOverride('cinnamon', 'ino', LinkagePhase.coupling);

      final father = container.read(fatherGenotypeProvider);
      expect(father.phaseFor('cinnamon', 'ino'), LinkagePhase.coupling);
      // Order-independent lookup.
      expect(father.phaseFor('ino', 'cinnamon'), LinkagePhase.coupling);
    });

    test('sets an explicit repulsion override for a linked pair', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.split,
          'ino': AlleleState.split,
        },
      );

      container
          .read(fatherGenotypeProvider.notifier)
          .setPhaseOverride('cinnamon', 'ino', LinkagePhase.repulsion);

      final father = container.read(fatherGenotypeProvider);
      expect(father.phaseFor('cinnamon', 'ino'), LinkagePhase.repulsion);
    });

    test('setting auto removes a previously set override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fatherGenotypeProvider.notifier);
      notifier.state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      );

      notifier.setPhaseOverride('cinnamon', 'ino', LinkagePhase.coupling);
      expect(
        container.read(fatherGenotypeProvider).phaseFor('cinnamon', 'ino'),
        LinkagePhase.coupling,
      );

      notifier.setPhaseOverride('cinnamon', 'ino', LinkagePhase.auto);
      expect(
        container.read(fatherGenotypeProvider).phaseFor('cinnamon', 'ino'),
        LinkagePhase.auto,
      );
    });

    test('does not affect other providers or state fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fatherGenotypeProvider.notifier);
      notifier.state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      );

      notifier.setPhaseOverride('cinnamon', 'ino', LinkagePhase.coupling);

      final father = container.read(fatherGenotypeProvider);
      expect(father.gender, BirdGender.male);
      expect(father.mutations, {
        'cinnamon': AlleleState.carrier,
        'ino': AlleleState.carrier,
      });
    });
  });
}
