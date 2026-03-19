import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/egg_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_fixtures.dart';

class MockEggRemoteSource extends Mock implements EggRemoteSource {}

Incubation _sampleIncubation({String id = 'inc-1', String userId = 'user-1'}) {
  return Incubation(id: id, userId: userId);
}

Clutch _sampleClutch({String id = 'clutch-1', String userId = 'user-1'}) {
  return Clutch(id: id, userId: userId);
}

void main() {
  late MockEggsDao localDao;
  late MockEggRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late MockIncubationsDao incubationsDao;
  late MockClutchesDao clutchesDao;
  late EggRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(TestFixtures.sampleEgg());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockEggsDao();
    remoteSource = MockEggRemoteSource();
    syncDao = MockSyncMetadataDao();
    incubationsDao = MockIncubationsDao();
    clutchesDao = MockClutchesDao();

    repository = EggRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
      incubationsDao: incubationsDao,
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
    when(
      () => localDao.watchByIncubation(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(() => localDao.getByIncubation(any())).thenAnswer((_) async => []);
    when(() => localDao.getByIncubationIds(any())).thenAnswer((_) async => []);
    when(() => localDao.getIncubating(any())).thenAnswer((_) async => []);

    when(() => remoteSource.fetchAll(any())).thenAnswer((_) async => []);
    when(
      () => remoteSource.fetchUpdatedSince(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});

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

    when(() => incubationsDao.getById(any())).thenAnswer((_) async => null);
    when(() => clutchesDao.getById(any())).thenAnswer((_) async => null);
  });

  group('EggRepository', () {
    test('save inserts item marks pending and pushes immediately', () async {
      final egg = TestFixtures.sampleEgg(id: 'egg-1', userId: userId);

      await repository.save(egg);

      verify(() => localDao.insertItem(egg)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.upsert(egg)).called(1);
    });

    test(
      'pull uses fetchAll on full sync and inserts remote records',
      () async {
        final remoteEggs = [TestFixtures.sampleEgg(id: 'egg-remote')];
        when(
          () => remoteSource.fetchAll(userId),
        ).thenAnswer((_) async => remoteEggs);

        await repository.pull(userId);

        verify(() => remoteSource.fetchAll(userId)).called(1);
        verify(() => localDao.insertAll(remoteEggs)).called(1);
      },
    );

    test('pull rethrows AppException', () async {
      when(
        () => remoteSource.fetchAll(userId),
      ).thenThrow(const DatabaseException('pull failed'));

      expect(() => repository.pull(userId), throwsA(isA<DatabaseException>()));
    });

    test(
      'push marks sync error when remote upsert fails with AppException',
      () async {
        final egg = TestFixtures.sampleEgg(id: 'egg-1', userId: userId);
        final meta = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.eggsTable,
          recordId: egg.id,
          userId: userId,
          retryCount: 2,
        );
        when(
          () => remoteSource.upsert(egg),
        ).thenThrow(const DatabaseException('remote failure'));
        when(
          () => syncDao.getByRecord(SupabaseConstants.eggsTable, egg.id),
        ).thenAnswer((_) async => meta);

        await repository.push(egg);

        final updated =
            verify(() => syncDao.updateItem(captureAny())).captured.single
                as SyncMetadata;
        expect(updated.status, SyncStatus.error);
        expect(updated.retryCount, 3);
        expect(updated.errorMessage, 'remote failure');
      },
    );
  });

  group('ValidatedSyncMixin pushAll', () {
    test('calls clearStaleErrors before processing pending records', () async {
      when(
        () => syncDao.getErrorsByTable(userId, SupabaseConstants.eggsTable),
      ).thenAnswer((_) async => []);
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.eggsTable),
      ).thenAnswer((_) async => []);

      await repository.pushAll(userId);

      verify(
        () => syncDao.getErrorsByTable(userId, SupabaseConstants.eggsTable),
      ).called(1);
      verify(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.eggsTable),
      ).called(1);
    });

    test('cleans stale errors above max retry threshold', () async {
      final stale = TestFixtures.sampleSyncMetadata(
        id: 'stale',
        table: SupabaseConstants.eggsTable,
        userId: userId,
        recordId: 'egg-stale',
        status: SyncStatus.error,
        retryCount: ValidatedSyncMixin.maxSyncRetries,
      );
      when(
        () => syncDao.getErrorsByTable(userId, SupabaseConstants.eggsTable),
      ).thenAnswer((_) async => [stale]);
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.eggsTable),
      ).thenAnswer((_) async => []);

      await repository.pushAll(userId);

      verify(() => syncDao.hardDelete('stale')).called(1);
    });

    test('cleans orphan sync metadata when local egg is missing', () async {
      final pending = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.eggsTable,
        userId: userId,
        recordId: 'missing-egg',
      );
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.eggsTable),
      ).thenAnswer((_) async => [pending]);
      when(() => localDao.getById('missing-egg')).thenAnswer((_) async => null);

      await repository.pushAll(userId);

      verify(
        () =>
            syncDao.deleteByRecord(SupabaseConstants.eggsTable, 'missing-egg'),
      ).called(1);
      verifyNever(() => remoteSource.upsert(any()));
    });

    test(
      'skips silently when FK exists locally but parent is not yet synced',
      () async {
        final egg = TestFixtures.sampleEgg(
          id: 'egg-1',
          userId: userId,
          incubationId: 'inc-1',
        );
        final pending = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.eggsTable,
          userId: userId,
          recordId: egg.id,
        );
        final incubationPendingMeta = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.incubationsTable,
          userId: userId,
          recordId: 'inc-1',
        );

        when(
          () => syncDao.getPendingByTable(userId, SupabaseConstants.eggsTable),
        ).thenAnswer((_) async => [pending]);
        when(() => localDao.getById(egg.id)).thenAnswer((_) async => egg);
        when(
          () => incubationsDao.getById('inc-1'),
        ).thenAnswer((_) async => _sampleIncubation(id: 'inc-1'));
        when(
          () =>
              syncDao.getByRecord(SupabaseConstants.incubationsTable, 'inc-1'),
        ).thenAnswer((_) async => incubationPendingMeta);

        await repository.pushAll(userId);

        verifyNever(() => remoteSource.upsert(any()));
        verifyNever(() => syncDao.updateItem(any()));
      },
    );

    test('marks sync error when clutch FK is truly missing locally', () async {
      final egg = TestFixtures.sampleEgg(
        id: 'egg-1',
        userId: userId,
        clutchId: 'missing-clutch',
      );
      final pending = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.eggsTable,
        userId: userId,
        recordId: egg.id,
      );
      final existingMeta = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.eggsTable,
        userId: userId,
        recordId: egg.id,
        retryCount: 0,
      );
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.eggsTable),
      ).thenAnswer((_) async => [pending]);
      when(() => localDao.getById(egg.id)).thenAnswer((_) async => egg);
      when(
        () => clutchesDao.getById('missing-clutch'),
      ).thenAnswer((_) async => null);
      when(
        () => syncDao.getByRecord(SupabaseConstants.eggsTable, egg.id),
      ).thenAnswer((_) async => existingMeta);

      await repository.pushAll(userId);

      final updated =
          verify(() => syncDao.updateItem(captureAny())).captured.single
              as SyncMetadata;
      expect(updated.status, SyncStatus.error);
      expect(updated.retryCount, 1);
      expect(updated.errorMessage, contains('not found locally'));
      verifyNever(() => remoteSource.upsert(any()));
    });

    test('pushes egg when all foreign keys are valid', () async {
      final egg = TestFixtures.sampleEgg(
        id: 'egg-1',
        userId: userId,
        clutchId: 'clutch-1',
        incubationId: 'inc-1',
      );
      final pending = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.eggsTable,
        userId: userId,
        recordId: egg.id,
      );
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.eggsTable),
      ).thenAnswer((_) async => [pending]);
      when(() => localDao.getById(egg.id)).thenAnswer((_) async => egg);
      when(
        () => incubationsDao.getById('inc-1'),
      ).thenAnswer((_) async => _sampleIncubation(id: 'inc-1'));
      when(
        () => clutchesDao.getById('clutch-1'),
      ).thenAnswer((_) async => _sampleClutch(id: 'clutch-1'));
      when(
        () => syncDao.getByRecord(SupabaseConstants.incubationsTable, 'inc-1'),
      ).thenAnswer((_) async => null);
      when(
        () => syncDao.getByRecord(SupabaseConstants.clutchesTable, 'clutch-1'),
      ).thenAnswer((_) async => null);

      await repository.pushAll(userId);

      verify(() => remoteSource.upsert(egg)).called(1);
    });
  });

  group('validateForeignKeys', () {
    test('returns error when clutchId exists but clutch is missing', () async {
      final egg = TestFixtures.sampleEgg(clutchId: 'missing-clutch');
      when(
        () => clutchesDao.getById('missing-clutch'),
      ).thenAnswer((_) async => null);

      final result = await repository.validateForeignKeys(egg);
      expect(result, contains('not found locally'));
    });

    test(
      'returns error when incubationId exists but incubation is missing',
      () async {
        final egg = TestFixtures.sampleEgg(incubationId: 'missing-inc');
        when(
          () => incubationsDao.getById('missing-inc'),
        ).thenAnswer((_) async => null);

        final result = await repository.validateForeignKeys(egg);
        expect(result, contains('not found locally'));
      },
    );

    test('returns null when both foreign keys are valid and synced', () async {
      final egg = TestFixtures.sampleEgg(
        clutchId: 'clutch-1',
        incubationId: 'inc-1',
      );
      when(
        () => incubationsDao.getById('inc-1'),
      ).thenAnswer((_) async => _sampleIncubation(id: 'inc-1'));
      when(
        () => clutchesDao.getById('clutch-1'),
      ).thenAnswer((_) async => _sampleClutch(id: 'clutch-1'));
      when(
        () => syncDao.getByRecord(SupabaseConstants.incubationsTable, 'inc-1'),
      ).thenAnswer((_) async => null);
      when(
        () => syncDao.getByRecord(SupabaseConstants.clutchesTable, 'clutch-1'),
      ).thenAnswer((_) async => null);

      final result = await repository.validateForeignKeys(egg);
      expect(result, isNull);
    });
  });
}
