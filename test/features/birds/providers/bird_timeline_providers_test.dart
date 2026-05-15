import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_timeline_providers.dart';

void main() {
  group('buildBirdTimelineEvents', () {
    test('combines bird, chick, breeding, egg, and health history by date', () {
      final bird = Bird(
        id: 'bird-1',
        userId: 'user-1',
        name: 'Mavi',
        gender: BirdGender.female,
        species: Species.budgie,
        birthDate: DateTime(2024),
        createdAt: DateTime(2024, 2),
      );
      final pair = BreedingPair(
        id: 'pair-1',
        userId: 'user-1',
        femaleId: 'bird-1',
        maleId: 'male-1',
        pairingDate: DateTime(2024, 5),
      );
      final incubation = Incubation(
        id: 'inc-1',
        userId: 'user-1',
        breedingPairId: 'pair-1',
        startDate: DateTime(2024, 5, 3),
      );
      final eggs = [
        Egg(
          id: 'egg-1',
          userId: 'user-1',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 5, 4),
        ),
        Egg(
          id: 'egg-2',
          userId: 'user-1',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 5, 5),
          status: EggStatus.hatched,
          hatchDate: DateTime(2024, 5, 23),
        ),
      ];
      final chick = Chick(
        id: 'chick-1',
        userId: 'user-1',
        birdId: 'bird-1',
        hatchDate: DateTime(2024, 5, 23),
      );
      final health = HealthRecord(
        id: 'health-1',
        userId: 'user-1',
        birdId: 'bird-1',
        date: DateTime(2024, 6),
        type: HealthRecordType.checkup,
        title: 'Routine check',
      );

      final events = buildBirdTimelineEvents(
        bird: bird,
        breedingPairs: [pair],
        incubations: [incubation],
        eggs: eggs,
        chicks: [chick],
        healthRecords: [health],
      );

      expect(events.map((event) => event.type), [
        BirdTimelineEventType.birth,
        BirdTimelineEventType.registered,
        BirdTimelineEventType.breeding,
        BirdTimelineEventType.egg,
        BirdTimelineEventType.chick,
        BirdTimelineEventType.health,
      ]);
      expect(events[3].namedArgs['count'], '2');
      expect(events[3].titleKey, 'birds.timeline_eggs_laid');
      expect(events[5].title, 'Routine check');
    });

    test('adds status transfer event for gifted birds', () {
      final bird = Bird(
        id: 'bird-1',
        userId: 'user-1',
        name: 'Mavi',
        gender: BirdGender.female,
        status: BirdStatus.gifted,
        soldDate: DateTime(2024, 7),
      );

      final events = buildBirdTimelineEvents(bird: bird);

      expect(events.single.type, BirdTimelineEventType.status);
      expect(events.single.titleKey, 'birds.timeline_gifted');
    });
  });
}
