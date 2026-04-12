import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

void main() {
  test('breeding workflow runs end-to-end from pair to bird conversion', () {
    // 1) Create breeding pair
    final pair = BreedingPair(
      id: 'pair-1',
      userId: 'user-1',
      maleId: 'bird-male',
      femaleId: 'bird-female',
      status: BreedingStatus.active,
      pairingDate: DateTime(2024, 1, 1),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
    expect(pair.status, BreedingStatus.active);

    // 2) Start incubation
    final incubation = Incubation(
      id: 'inc-1',
      userId: 'user-1',
      breedingPairId: pair.id,
      status: IncubationStatus.active,
      startDate: DateTime(2024, 1, 3),
      createdAt: DateTime(2024, 1, 3),
      updatedAt: DateTime(2024, 1, 3),
    );
    expect(incubation.breedingPairId, pair.id);

    // 3) Add egg
    var egg = Egg(
      id: 'egg-1',
      userId: 'user-1',
      incubationId: incubation.id,
      layDate: DateTime(2024, 1, 4),
      eggNumber: 1,
      status: EggStatus.laid,
      createdAt: DateTime(2024, 1, 4),
      updatedAt: DateTime(2024, 1, 4),
    );
    expect(egg.status, EggStatus.laid);

    // 4) Egg status transitions: laid -> fertile -> incubating -> hatched
    egg = egg.copyWith(
      status: EggStatus.fertile,
      fertileCheckDate: DateTime(2024, 1, 10),
      updatedAt: DateTime(2024, 1, 10),
    );
    expect(egg.status, EggStatus.fertile);
    expect(egg.fertileCheckDate, isNotNull);

    egg = egg.copyWith(
      status: EggStatus.incubating,
      updatedAt: DateTime(2024, 1, 11),
    );
    expect(egg.status, EggStatus.incubating);

    egg = egg.copyWith(
      status: EggStatus.hatched,
      hatchDate: DateTime(2024, 1, 22),
      updatedAt: DateTime(2024, 1, 22),
    );
    expect(egg.status, EggStatus.hatched);
    expect(egg.hatchDate, isNotNull);

    // 5) Create chick from hatched egg
    var chick = Chick(
      id: 'chick-1',
      userId: 'user-1',
      eggId: egg.id,
      clutchId: egg.clutchId,
      hatchDate: egg.hatchDate,
      gender: BirdGender.unknown,
      healthStatus: ChickHealthStatus.healthy,
      createdAt: DateTime(2024, 1, 22),
      updatedAt: DateTime(2024, 1, 22),
    );
    expect(chick.eggId, egg.id);
    expect(chick.healthStatus, ChickHealthStatus.healthy);

    // 6) Add growth measurements
    final measurements = <GrowthMeasurement>[
      GrowthMeasurement(
        id: 'gm-1',
        chickId: chick.id,
        userId: chick.userId,
        weight: 8.5,
        measurementDate: DateTime(2024, 1, 24),
        createdAt: DateTime(2024, 1, 24),
        updatedAt: DateTime(2024, 1, 24),
      ),
      GrowthMeasurement(
        id: 'gm-2',
        chickId: chick.id,
        userId: chick.userId,
        weight: 14.2,
        measurementDate: DateTime(2024, 2, 5),
        createdAt: DateTime(2024, 2, 5),
        updatedAt: DateTime(2024, 2, 5),
      ),
    ];
    expect(measurements, hasLength(2));
    expect(measurements.last.weight, greaterThan(measurements.first.weight));

    // 7) Convert chick to bird
    final bird = Bird(
      id: 'bird-new-1',
      userId: chick.userId,
      name: 'New Bird',
      gender: BirdGender.male,
      status: BirdStatus.alive,
      birthDate: chick.hatchDate,
      createdAt: DateTime(2024, 3, 30),
      updatedAt: DateTime(2024, 3, 30),
    );
    chick = chick.copyWith(
      birdId: bird.id,
      ringNumber: 'TR-2024-001',
      weanDate: DateTime(2024, 3, 30),
      updatedAt: DateTime(2024, 3, 30),
    );

    expect(chick.birdId, bird.id);
    expect(chick.isWeaned, isTrue);
    expect(bird.birthDate, chick.hatchDate);
    expect(bird.status, BirdStatus.alive);
  });
}
