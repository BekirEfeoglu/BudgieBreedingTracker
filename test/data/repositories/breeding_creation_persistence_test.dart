import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/breeding_pair_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/egg_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/incubation_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_creation_persistence.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';

class _MockBreedingPairRemoteSource extends Mock
    implements BreedingPairRemoteSource {}

class _MockIncubationRemoteSource extends Mock
    implements IncubationRemoteSource {}

class _MockEggRemoteSource extends Mock implements EggRemoteSource {}

void main() {
  late AppDatabase database;
  late _MockBreedingPairRemoteSource pairRemote;
  late _MockIncubationRemoteSource incubationRemote;
  late _MockEggRemoteSource eggRemote;
  late DriftBreedingCreationPersistence persistence;
  late DriftBreedingLifecyclePersistence lifecyclePersistence;
  late DriftEggCreationPersistence eggPersistence;

  BreedingPair pair() => BreedingPair(
    id: 'pair-1',
    userId: 'user-1',
    status: BreedingStatus.active,
    pairingDate: DateTime.utc(2026, 7, 1),
  );

  Incubation incubation({String pairId = 'pair-1'}) => Incubation(
    id: 'incubation-1',
    userId: 'user-1',
    status: IncubationStatus.active,
    breedingPairId: pairId,
    startDate: DateTime.utc(2026, 7, 1),
  );

  Egg egg() => Egg(
    id: 'egg-1',
    userId: 'user-1',
    incubationId: 'incubation-1',
    layDate: DateTime.utc(2026, 7, 2),
  );

  setUpAll(() {
    registerFallbackValue(pair());
    registerFallbackValue(incubation());
    registerFallbackValue(egg());
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    pairRemote = _MockBreedingPairRemoteSource();
    incubationRemote = _MockIncubationRemoteSource();
    eggRemote = _MockEggRemoteSource();

    final pairRepository = BreedingPairRepository(
      localDao: database.breedingPairsDao,
      remoteSource: pairRemote,
      syncDao: database.syncMetadataDao,
      birdsDao: BirdsDao(database),
    );
    final incubationRepository = IncubationRepository(
      localDao: database.incubationsDao,
      remoteSource: incubationRemote,
      syncDao: database.syncMetadataDao,
      breedingPairsDao: database.breedingPairsDao,
      clutchesDao: database.clutchesDao,
    );
    final eggRepository = EggRepository(
      localDao: database.eggsDao,
      remoteSource: eggRemote,
      syncDao: database.syncMetadataDao,
      incubationsDao: database.incubationsDao,
      clutchesDao: database.clutchesDao,
    );
    persistence = DriftBreedingCreationPersistence(
      database: database,
      pairRepository: pairRepository,
      incubationRepository: incubationRepository,
    );
    lifecyclePersistence = DriftBreedingLifecyclePersistence(
      database: database,
      pairRepository: pairRepository,
      incubationRepository: incubationRepository,
    );
    eggPersistence = DriftEggCreationPersistence(
      database: database,
      eggRepository: eggRepository,
      incubationRepository: incubationRepository,
    );

    // Simulate offline mode. Immediate push failures are intentionally
    // swallowed after the local transaction and metadata stays pending.
    when(() => pairRemote.upsert(any())).thenThrow(Exception('offline'));
    when(() => incubationRemote.upsert(any())).thenThrow(Exception('offline'));
    when(() => eggRemote.upsert(any())).thenThrow(Exception('offline'));
  });

  tearDown(() async {
    await database.close();
  });

  test('commits pair, incubation, and both pending rows together', () async {
    await persistence.save(pair(), incubation());

    expect(await database.breedingPairsDao.getById('pair-1'), isNotNull);
    expect(await database.incubationsDao.getById('incubation-1'), isNotNull);
    expect(
      await database.syncMetadataDao.getByRecord('breeding_pairs', 'pair-1'),
      isNotNull,
    );
    expect(
      await database.syncMetadataDao.getByRecord('incubations', 'incubation-1'),
      isNotNull,
    );
  });

  test('rolls back pair and metadata when incubation insert fails', () async {
    await expectLater(
      persistence.save(pair(), incubation(pairId: 'missing-pair')),
      throwsA(anything),
    );

    expect(await database.breedingPairsDao.getById('pair-1'), isNull);
    expect(await database.incubationsDao.getById('incubation-1'), isNull);
    expect(
      await database.syncMetadataDao.getByRecord('breeding_pairs', 'pair-1'),
      isNull,
    );
    expect(
      await database.syncMetadataDao.getByRecord('incubations', 'incubation-1'),
      isNull,
    );
    verifyNever(() => pairRemote.upsert(any()));
    verifyNever(() => incubationRemote.upsert(any()));
  });

  test('commits pair closure and active incubation updates together', () async {
    await persistence.save(pair(), incubation());

    await lifecyclePersistence.closePair(
      pair().copyWith(status: BreedingStatus.completed),
      [incubation().copyWith(status: IncubationStatus.completed)],
    );

    expect(
      (await database.breedingPairsDao.getById('pair-1'))?.status,
      BreedingStatus.completed,
    );
    expect(
      (await database.incubationsDao.getById('incubation-1'))?.status,
      IncubationStatus.completed,
    );
  });

  test('rolls back pair closure when an incubation update fails', () async {
    await persistence.save(pair(), incubation());

    await expectLater(
      lifecyclePersistence
          .closePair(pair().copyWith(status: BreedingStatus.completed), [
            incubation(
              pairId: 'missing-pair',
            ).copyWith(status: IncubationStatus.completed),
          ]),
      throwsA(anything),
    );

    expect(
      (await database.breedingPairsDao.getById('pair-1'))?.status,
      BreedingStatus.active,
    );
    expect(
      (await database.incubationsDao.getById('incubation-1'))?.status,
      IncubationStatus.active,
    );
  });

  test('commits first egg and incubation start update together', () async {
    await persistence.save(pair(), incubation());
    final started = incubation().copyWith(
      startDate: DateTime.utc(2026, 7, 2),
      expectedHatchDate: DateTime.utc(2026, 7, 20),
    );

    await eggPersistence.save(egg(), startedIncubation: started);

    expect(await database.eggsDao.getById('egg-1'), isNotNull);
    expect(
      (await database.incubationsDao.getById('incubation-1'))?.startDate,
      DateTime.utc(2026, 7, 2),
    );
    expect(
      await database.syncMetadataDao.getByRecord('eggs', 'egg-1'),
      isNotNull,
    );
  });

  test('rolls back first egg when incubation start update fails', () async {
    await persistence.save(pair(), incubation());
    final invalidStarted = incubation(
      pairId: 'missing-pair',
    ).copyWith(startDate: DateTime.utc(2026, 7, 2));

    await expectLater(
      eggPersistence.save(egg(), startedIncubation: invalidStarted),
      throwsA(anything),
    );

    expect(await database.eggsDao.getById('egg-1'), isNull);
    expect(
      (await database.incubationsDao.getById('incubation-1'))?.startDate,
      DateTime.utc(2026, 7, 1),
    );
    expect(await database.syncMetadataDao.getByRecord('eggs', 'egg-1'), isNull);
  });
}
