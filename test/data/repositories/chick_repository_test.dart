import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/chick_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';

import '../../helpers/test_fixtures.dart';

class MockChicksDao extends Mock implements ChicksDao {}

class MockChickRemoteSource extends Mock implements ChickRemoteSource {}

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

class MockEggsDao extends Mock implements EggsDao {}

class MockClutchesDao extends Mock implements ClutchesDao {}

Egg _sampleEgg({String id = 'egg-1', String userId = 'user-1'}) {
  return TestFixtures.sampleEgg(id: id, userId: userId);
}

Clutch _sampleClutch({String id = 'clutch-1', String userId = 'user-1'}) {
  return TestFixtures.sampleClutch(id: id, userId: userId);
}

void main() {
  late MockChicksDao localDao;
  late MockChickRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late MockEggsDao eggsDao;
  late MockClutchesDao clutchesDao;
  late ChickRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(TestFixtures.sampleChick());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockChicksDao();
    remoteSource = MockChickRemoteSource();
    syncDao = MockSyncMetadataDao();
    eggsDao = MockEggsDao();
    clutchesDao = MockClutchesDao();

    repository = ChickRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
      eggsDao: eggsDao,
      clutchesDao: clutchesDao,
    );

    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.insertAll(any())).thenAnswer((_) async {});
    when(() => localDao.softDelete(any())).thenAnswer((_) async {});
    when(() => localDao.hardDelete(any())).thenAnswer((_) async {});
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(() => localDao.getAll(any())).thenAnswer((_) async => []);
    when(
      () => localDao.watchAll(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => localDao.watchById(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => localDao.watchByClutch(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(() => localDao.getByEggId(any())).thenAnswer((_) async => null);
    when(() => localDao.getByEggIds(any())).thenAnswer((_) async => []);
    when(() => localDao.getUnweaned(any())).thenAnswer((_) async => []);

    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});
    when(() => remoteSource.fetchAll(any())).thenAnswer((_) async => []);
    when(
      () => remoteSource.fetchUpdatedSince(any(), any()),
    ).thenAnswer((_) async => []);

    when(() => syncDao.insertItem(any())).thenAnswer((_) async {});
    when(() => syncDao.insertAll(any())).thenAnswer((_) async {});
    when(() => syncDao.deleteByRecord(any(), any())).thenAnswer((_) async {});
    when(() => syncDao.updateItem(any())).thenAnswer((_) async {});
    when(() => syncDao.hardDelete(any())).thenAnswer((_) async {});
    when(() => syncDao.getByRecord(any(), any())).thenAnswer((_) async => null);
    when(
      () => syncDao.getPendingByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => syncDao.getErrorsByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => syncDao.getPendingRecordIds(any())).thenAnswer((_) async => {});

    when(() => eggsDao.getById(any())).thenAnswer((_) async => null);
    when(() => clutchesDao.getById(any())).thenAnswer((_) async => null);
  });

  group('ChickRepository basic sync', () {
    test(
      'save inserts local item creates pending metadata and pushes',
      () async {
        final chick = TestFixtures.sampleChick(id: 'chick-1', userId: userId);

        await repository.save(chick);

        verify(() => localDao.insertItem(chick)).called(1);
        verify(() => syncDao.insertItem(any())).called(1);
        verify(() => remoteSource.upsert(chick)).called(1);
      },
    );

    test(
      'pushAll cleans orphan metadata when local chick is missing',
      () async {
        final pending = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.chicksTable,
          userId: userId,
          recordId: 'missing-chick',
        );
        when(
          () =>
              syncDao.getPendingByTable(userId, SupabaseConstants.chicksTable),
        ).thenAnswer((_) async => [pending]);
        when(
          () => localDao.getById('missing-chick'),
        ).thenAnswer((_) async => null);

        await repository.pushAll(userId);

        verify(
          () => syncDao.deleteByRecord(
            SupabaseConstants.chicksTable,
            'missing-chick',
          ),
        ).called(1);
        verifyNever(() => remoteSource.upsert(any()));
      },
    );
  });

  group('ValidatedSyncMixin pushAll FK validation', () {
    test('marks sync error for true orphan egg FK', () async {
      final chick = TestFixtures.sampleChick(
        id: 'chick-1',
        userId: userId,
        eggId: 'missing-egg',
      );
      final pending = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.chicksTable,
        userId: userId,
        recordId: chick.id,
      );
      final existingMeta = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.chicksTable,
        userId: userId,
        recordId: chick.id,
      );
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.chicksTable),
      ).thenAnswer((_) async => [pending]);
      when(() => localDao.getById(chick.id)).thenAnswer((_) async => chick);
      when(() => eggsDao.getById('missing-egg')).thenAnswer((_) async => null);
      when(
        () => syncDao.getByRecord(SupabaseConstants.chicksTable, chick.id),
      ).thenAnswer((_) async => existingMeta);

      await repository.pushAll(userId);

      final updated =
          verify(() => syncDao.updateItem(captureAny())).captured.single
              as SyncMetadata;
      expect(updated.status, SyncStatus.error);
      expect(updated.errorMessage, contains('not found locally'));
      verifyNever(() => remoteSource.upsert(any()));
    });

    test(
      'skips dependency waiting records when parent egg not yet synced',
      () async {
        final chick = TestFixtures.sampleChick(
          id: 'chick-1',
          userId: userId,
          eggId: 'egg-1',
        );
        final pending = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.chicksTable,
          userId: userId,
          recordId: chick.id,
        );
        final eggPendingMeta = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.eggsTable,
          userId: userId,
          recordId: 'egg-1',
        );
        when(
          () =>
              syncDao.getPendingByTable(userId, SupabaseConstants.chicksTable),
        ).thenAnswer((_) async => [pending]);
        when(() => localDao.getById(chick.id)).thenAnswer((_) async => chick);
        when(
          () => eggsDao.getById('egg-1'),
        ).thenAnswer((_) async => _sampleEgg(id: 'egg-1'));
        when(
          () => syncDao.getByRecord(SupabaseConstants.eggsTable, 'egg-1'),
        ).thenAnswer((_) async => eggPendingMeta);

        await repository.pushAll(userId);

        verifyNever(() => syncDao.updateItem(any()));
        verifyNever(() => remoteSource.upsert(any()));
      },
    );

    test('pushes valid chick when egg and clutch FK are valid', () async {
      final chick = TestFixtures.sampleChick(
        id: 'chick-1',
        userId: userId,
        eggId: 'egg-1',
        clutchId: 'clutch-1',
      );
      final pending = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.chicksTable,
        userId: userId,
        recordId: chick.id,
      );
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.chicksTable),
      ).thenAnswer((_) async => [pending]);
      when(() => localDao.getById(chick.id)).thenAnswer((_) async => chick);
      when(
        () => eggsDao.getById('egg-1'),
      ).thenAnswer((_) async => _sampleEgg(id: 'egg-1'));
      when(
        () => clutchesDao.getById('clutch-1'),
      ).thenAnswer((_) async => _sampleClutch(id: 'clutch-1'));
      when(
        () => syncDao.getByRecord(SupabaseConstants.eggsTable, 'egg-1'),
      ).thenAnswer((_) async => null);
      when(
        () => syncDao.getByRecord(SupabaseConstants.clutchesTable, 'clutch-1'),
      ).thenAnswer((_) async => null);

      await repository.pushAll(userId);

      verify(() => remoteSource.upsert(chick)).called(1);
    });
  });

  group('validateForeignKeys', () {
    test('returns orphan reason when eggId is missing locally', () async {
      final chick = TestFixtures.sampleChick(eggId: 'missing-egg');
      when(() => eggsDao.getById('missing-egg')).thenAnswer((_) async => null);

      final result = await repository.validateForeignKeys(chick);
      expect(result, contains('not found locally'));
    });

    test('returns orphan reason when clutchId is missing locally', () async {
      final chick = TestFixtures.sampleChick(clutchId: 'missing-clutch');
      when(
        () => clutchesDao.getById('missing-clutch'),
      ).thenAnswer((_) async => null);

      final result = await repository.validateForeignKeys(chick);
      expect(result, contains('not found locally'));
    });

    test(
      'returns null when referenced egg and clutch exist and are synced',
      () async {
        final chick = TestFixtures.sampleChick(
          eggId: 'egg-1',
          clutchId: 'clutch-1',
        );
        when(
          () => eggsDao.getById('egg-1'),
        ).thenAnswer((_) async => _sampleEgg(id: 'egg-1'));
        when(
          () => clutchesDao.getById('clutch-1'),
        ).thenAnswer((_) async => _sampleClutch(id: 'clutch-1'));
        when(
          () => syncDao.getByRecord(SupabaseConstants.eggsTable, 'egg-1'),
        ).thenAnswer((_) async => null);
        when(
          () =>
              syncDao.getByRecord(SupabaseConstants.clutchesTable, 'clutch-1'),
        ).thenAnswer((_) async => null);

        final result = await repository.validateForeignKeys(chick);
        expect(result, isNull);
      },
    );
  });
}
