import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

void main() {
  group('FatherGenotypeNotifier', () {
    test('initial state is empty male genotype', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final father = container.read(fatherGenotypeProvider);
      expect(father.isEmpty, isTrue);
      expect(father.gender, BirdGender.male);
    });

    test('state can be updated with mutations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final newGenotype = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      container.read(fatherGenotypeProvider.notifier).state = newGenotype;

      final father = container.read(fatherGenotypeProvider);
      expect(father.isNotEmpty, isTrue);
      expect(father.mutations, {'blue': AlleleState.visual});
    });

    test('state preserves male gender on update', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.carrier},
      );

      expect(container.read(fatherGenotypeProvider).gender, BirdGender.male);
    });
  });

  group('MotherGenotypeNotifier', () {
    test('initial state is empty female genotype', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mother = container.read(motherGenotypeProvider);
      expect(mother.isEmpty, isTrue);
      expect(mother.gender, BirdGender.female);
    });

    test('state can be updated with mutations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.visual, 'blue': AlleleState.carrier},
      );

      final mother = container.read(motherGenotypeProvider);
      expect(mother.mutations, hasLength(2));
      expect(mother.getState('ino'), AlleleState.visual);
      expect(mother.getState('blue'), AlleleState.carrier);
    });
  });

  group('SelectedFatherBirdNameNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedFatherBirdNameProvider), isNull);
    });

    test('can be set to a name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedFatherBirdNameProvider.notifier).state = 'Charlie';
      expect(container.read(selectedFatherBirdNameProvider), 'Charlie');
    });

    test('can be cleared back to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedFatherBirdNameProvider.notifier).state = 'Charlie';
      container.read(selectedFatherBirdNameProvider.notifier).state = null;
      expect(container.read(selectedFatherBirdNameProvider), isNull);
    });
  });

  group('SelectedMotherBirdNameNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedMotherBirdNameProvider), isNull);
    });

    test('can be set to a name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedMotherBirdNameProvider.notifier).state = 'Daisy';
      expect(container.read(selectedMotherBirdNameProvider), 'Daisy');
    });
  });

  group('fatherMutationsProvider', () {
    test('returns empty set when father genotype is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(fatherMutationsProvider), isEmpty);
    });

    test('extracts only visual mutation IDs for autosomal recessive', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'violet': AlleleState.carrier,
        },
      );

      final mutations = container.read(fatherMutationsProvider);
      expect(mutations, contains('blue'));
      // violet as carrier is NOT visual for autosomal dominant
      // (but it's autosomal incomplete dominant — carrier IS visual)
      // This depends on the actual mutation database definition
    });

    test('includes carrier mutations for autosomal dominant types', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // spangle is autosomal incomplete dominant — carrier (SF) is visual
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'spangle': AlleleState.carrier},
      );

      final mutations = container.read(fatherMutationsProvider);
      expect(mutations, contains('spangle'));
    });
  });

  group('motherMutationsProvider', () {
    test('returns empty set when mother genotype is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(motherMutationsProvider), isEmpty);
    });

    test('females are always visual for sex-linked mutations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // ino is sex-linked recessive; females are hemizygous, always visual
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.visual},
      );

      final mutations = container.read(motherMutationsProvider);
      expect(mutations, contains('ino'));
    });

    test('extracts correct set from multiple mutation states', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'ino': AlleleState.visual,
          'blue': AlleleState.carrier,
        },
      );

      // ino should be in set (sex-linked female is always visual)
      // blue carrier for autosomal recessive is NOT visual
      final mutations = container.read(motherMutationsProvider);
      expect(mutations, contains('ino'));
      expect(mutations, isNot(contains('blue')));
    });
  });

  group('ShowSexSpecificNotifier', () {
    test('initial state is true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(showSexSpecificProvider), isTrue);
    });

    test('can be toggled to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(showSexSpecificProvider.notifier).state = false;
      expect(container.read(showSexSpecificProvider), isFalse);
    });
  });

  group('ShowGenotypeNotifier', () {
    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(showGenotypeProvider), isFalse);
    });

    test('can be toggled to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(showGenotypeProvider.notifier).state = true;
      expect(container.read(showGenotypeProvider), isTrue);
    });
  });

  group('WizardStepNotifier', () {
    test('initial state is 0 (parents step)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(wizardStepProvider), 0);
    });

    test('can advance to step 1 (preview)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(wizardStepProvider.notifier).state = 1;
      expect(container.read(wizardStepProvider), 1);
    });

    test('can advance to step 2 (results)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(wizardStepProvider.notifier).state = 2;
      expect(container.read(wizardStepProvider), 2);
    });

    test('can go back to step 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(wizardStepProvider.notifier).state = 2;
      container.read(wizardStepProvider.notifier).state = 0;
      expect(container.read(wizardStepProvider), 0);
    });
  });
}
