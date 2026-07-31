import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/breeding_pair_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/incubation_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_creation_persistence.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';

class _MockBreedingPairRemoteSource extends Mock
    implements BreedingPairRemoteSource {}

class _MockIncubationRemoteSource extends Mock
    implements IncubationRemoteSource {}

void main() {
  late AppDatabase database;
  late _MockBreedingPairRemoteSource pairRemote;
  late _MockIncubationRemoteSource incubationRemote;
  late DriftBreedingCreationPersistence persistence;

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

  setUpAll(() {
    registerFallbackValue(pair());
    registerFallbackValue(incubation());
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    pairRemote = _MockBreedingPairRemoteSource();
    incubationRemote = _MockIncubationRemoteSource();

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
    persistence = DriftBreedingCreationPersistence(
      database: database,
      pairRepository: pairRepository,
      incubationRepository: incubationRepository,
    );

    // Simulate offline mode. Immediate push failures are intentionally
    // swallowed after the local transaction and metadata stays pending.
    when(() => pairRemote.upsert(any())).thenThrow(Exception('offline'));
    when(() => incubationRemote.upsert(any())).thenThrow(Exception('offline'));
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
}
