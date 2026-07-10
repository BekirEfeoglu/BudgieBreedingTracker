import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/bird_genotype_mapper.dart';

void main() {
  group('BirdGenotypeMapper.birdToGenotype', () {
    test('resolves legacy mutation IDs to canonical IDs', () {
      const bird = Bird(
        id: 'bird-1',
        name: 'Legacy',
        gender: BirdGender.male,
        userId: 'user-1',
        mutations: ['lutino'],
        genotypeInfo: {'lutino': 'carrier'},
      );

      final genotype = BirdGenotypeMapper.birdToGenotype(bird);

      expect(genotype.mutations.containsKey('lutino'), isFalse);
      expect(genotype.getState('ino'), AlleleState.carrier);
    });

    test(
      'uses canonical genotypeInfo key when mutation list has legacy key',
      () {
        const bird = Bird(
          id: 'bird-1',
          name: 'Legacy',
          gender: BirdGender.male,
          userId: 'user-1',
          mutations: ['lutino'],
          genotypeInfo: {'ino': 'split'},
        );

        final genotype = BirdGenotypeMapper.birdToGenotype(bird);

        expect(genotype.getState('ino'), AlleleState.split);
      },
    );

    test('prefers canonical key when canonical and legacy collide', () {
      const bird = Bird(
        id: 'bird-1',
        name: 'Legacy',
        gender: BirdGender.male,
        userId: 'user-1',
        mutations: ['lutino', 'ino'],
        genotypeInfo: {'lutino': 'carrier', 'ino': 'visual'},
      );

      final genotype = BirdGenotypeMapper.birdToGenotype(bird);

      expect(
        genotype.mutations.keys.where((key) => key == 'ino'),
        hasLength(1),
      );
      expect(genotype.getState('ino'), AlleleState.visual);
    });
  });

  group('BirdGenotypeMapper serialization', () {
    test('mutationIdsFromGenotype returns canonical unique IDs', () {
      final genotype = ParentGenotype(
        mutations: const {
          'lutino': AlleleState.visual,
          'ino': AlleleState.carrier,
        },
        gender: BirdGender.female,
      );

      final mutationIds = BirdGenotypeMapper.mutationIdsFromGenotype(genotype)!;

      expect(mutationIds, hasLength(1));
      expect(mutationIds.single, 'ino');
    });

    test('genotypeInfoFromGenotype returns canonical unique map', () {
      final genotype = ParentGenotype(
        mutations: const {
          'lutino': AlleleState.visual,
          'ino': AlleleState.carrier,
        },
        gender: BirdGender.female,
      );

      final genotypeInfo = BirdGenotypeMapper.genotypeInfoFromGenotype(
        genotype,
      )!;

      expect(genotypeInfo, hasLength(1));
      expect(genotypeInfo['ino'], 'carrier');
    });
  });

  group('BirdGenotypeMapper.birdToGenotypeMapping (I1)', () {
    test('reports unknown mutation IDs and excludes them from the genotype', () {
      const bird = Bird(
        id: 'bird-9',
        name: 'Mystery',
        gender: BirdGender.male,
        userId: 'user-1',
        mutations: ['ino', 'not_a_real_mutation'],
        genotypeInfo: {'ino': 'visual', 'not_a_real_mutation': 'visual'},
      );

      final mapping = BirdGenotypeMapper.birdToGenotypeMapping(bird);

      // Known mutation kept; unknown excluded (never reaches the engine).
      expect(mapping.genotype.getState('ino'), AlleleState.visual);
      expect(
        mapping.genotype.mutations.containsKey('not_a_real_mutation'),
        isFalse,
      );
      // Unknown reported so the UI can warn the user.
      expect(mapping.unmappedMutationIds, ['not_a_real_mutation']);
    });

    test('all-known mutations produce no unmapped report', () {
      const bird = Bird(
        id: 'bird-10',
        name: 'Known',
        gender: BirdGender.female,
        userId: 'user-1',
        mutations: ['blue'],
        genotypeInfo: {'blue': 'visual'},
      );

      final mapping = BirdGenotypeMapper.birdToGenotypeMapping(bird);

      expect(mapping.unmappedMutationIds, isEmpty);
      expect(mapping.genotype.getState('blue'), AlleleState.visual);
    });

    test('legacy IDs resolve (not reported as unmapped)', () {
      const bird = Bird(
        id: 'bird-11',
        name: 'Legacy',
        gender: BirdGender.male,
        userId: 'user-1',
        mutations: ['lutino'],
        genotypeInfo: {'lutino': 'carrier'},
      );

      final mapping = BirdGenotypeMapper.birdToGenotypeMapping(bird);

      expect(mapping.unmappedMutationIds, isEmpty);
      expect(mapping.genotype.getState('ino'), AlleleState.carrier);
    });
  });
}
