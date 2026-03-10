import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/bird_genotype_mapper.dart';

void main() {
  group('BirdGenotypeMapper.birdToGenotype', () {
    test('resolves legacy mutation IDs to canonical IDs', () {
      final bird = Bird(
        id: 'bird-1',
        name: 'Legacy',
        gender: BirdGender.male,
        userId: 'user-1',
        mutations: const ['lutino'],
        genotypeInfo: const {'lutino': 'carrier'},
      );

      final genotype = BirdGenotypeMapper.birdToGenotype(bird);

      expect(genotype.mutations.containsKey('lutino'), isFalse);
      expect(genotype.getState('ino'), AlleleState.carrier);
    });

    test(
      'uses canonical genotypeInfo key when mutation list has legacy key',
      () {
        final bird = Bird(
          id: 'bird-1',
          name: 'Legacy',
          gender: BirdGender.male,
          userId: 'user-1',
          mutations: const ['lutino'],
          genotypeInfo: const {'ino': 'split'},
        );

        final genotype = BirdGenotypeMapper.birdToGenotype(bird);

        expect(genotype.getState('ino'), AlleleState.split);
      },
    );

    test('prefers canonical key when canonical and legacy collide', () {
      final bird = Bird(
        id: 'bird-1',
        name: 'Legacy',
        gender: BirdGender.male,
        userId: 'user-1',
        mutations: const ['lutino', 'ino'],
        genotypeInfo: const {'lutino': 'carrier', 'ino': 'visual'},
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

      final mutationIds = BirdGenotypeMapper.mutationIdsFromGenotype(genotype);

      expect(mutationIds, isNotNull);
      expect(mutationIds, hasLength(1));
      expect(mutationIds!.single, 'ino');
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
      );

      expect(genotypeInfo, isNotNull);
      expect(genotypeInfo, hasLength(1));
      expect(genotypeInfo!['ino'], 'carrier');
    });
  });
}
