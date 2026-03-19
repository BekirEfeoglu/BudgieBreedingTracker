import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/growth_measurements_dao.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/growth_measurement_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/growth_measurement_repository.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_fixtures.dart';

class MockGrowthMeasurementsDao extends Mock implements GrowthMeasurementsDao {}

class MockGrowthMeasurementRemoteSource extends Mock
    implements GrowthMeasurementRemoteSource {}

GrowthMeasurement _makeMeasurement({
  String id = 'gm-1',
  String userId = 'user-1',
}) {
  return GrowthMeasurement(
    id: id,
    chickId: 'chick-1',
    weight: 25.0,
    measurementDate: DateTime(2024, 2, 1),
    userId: userId,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late MockGrowthMeasurementsDao localDao;
  late MockGrowthMeasurementRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late GrowthMeasurementRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(_makeMeasurement());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockGrowthMeasurementsDao();
    remoteSource = MockGrowthMeasurementRemoteSource();
    syncDao = MockSyncMetadataDao();

    repository = GrowthMeasurementRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
    );

    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.insertAll(any())).thenAnswer((_) async {});
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
      () => localDao.watchByChick(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(() => localDao.getLatest(any())).thenAnswer((_) async => null);

    when(() => remoteSource.fetchAll(any())).thenAnswer((_) async => []);
    when(
      () => remoteSource.fetchUpdatedSince(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});
    when(() => remoteSource.deleteById(any(), userId: any(named: 'userId'))).thenAnswer((_) async {});

    when(() => syncDao.insertItem(any())).thenAnswer((_) async {});
    when(() => syncDao.insertAll(any())).thenAnswer((_) async {});
    when(() => syncDao.deleteByRecord(any(), any())).thenAnswer((_) async {});
    when(() => syncDao.updateItem(any())).thenAnswer((_) async {});
    when(() => syncDao.getByRecord(any(), any())).thenAnswer((_) async => null);
    when(
      () => syncDao.getPendingByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => syncDao.getPendingRecordIds(any())).thenAnswer((_) async => {});
  });

  group('GrowthMeasurementRepository', () {
    test('watchAll delegates to DAO stream', () {
      final expected = [_makeMeasurement(id: 'gm-1')];
      when(
        () => localDao.watchAll(userId),
      ).thenAnswer((_) => Stream.value(expected));

      expect(repository.watchAll(userId), emits(expected));
      verify(() => localDao.watchAll(userId)).called(1);
    });

    test('watchById delegates to DAO stream', () {
      final measurement = _makeMeasurement(id: 'gm-1');
      when(
        () => localDao.watchById('gm-1'),
      ).thenAnswer((_) => Stream.value(measurement));

      expect(repository.watchById('gm-1'), emits(measurement));
      verify(() => localDao.watchById('gm-1')).called(1);
    });

    test('getAll delegates to DAO', () async {
      final expected = [_makeMeasurement(id: 'gm-1')];
      when(() => localDao.getAll(userId)).thenAnswer((_) async => expected);

      final result = await repository.getAll(userId);
      expect(result, expected);
      verify(() => localDao.getAll(userId)).called(1);
    });

    test('getById delegates to DAO and may return null', () async {
      final measurement = _makeMeasurement(id: 'gm-1');
      when(() => localDao.getById('gm-1')).thenAnswer((_) async => measurement);
      when(() => localDao.getById('missing')).thenAnswer((_) async => null);

      expect(await repository.getById('gm-1'), measurement);
      expect(await repository.getById('missing'), isNull);
    });

    test(
      'save inserts item marks sync pending and tries immediate push',
      () async {
        final measurement = _makeMeasurement(id: 'gm-1');

        await repository.save(measurement);

        verify(() => localDao.insertItem(measurement)).called(1);
        final captured =
            verify(() => syncDao.insertItem(captureAny())).captured.single
                as SyncMetadata;
        expect(captured.table, SupabaseConstants.growthMeasurementsTable);
        expect(captured.recordId, measurement.id);
        expect(captured.userId, measurement.userId);
        expect(captured.status, SyncStatus.pending);
        verify(() => remoteSource.upsert(measurement)).called(1);
      },
    );

    test('saveAll inserts all and creates metadata for each item', () async {
      final items = [
        _makeMeasurement(id: 'gm-1'),
        _makeMeasurement(id: 'gm-2'),
      ];

      await repository.saveAll(items);

      verify(() => localDao.insertAll(items)).called(1);
      final captured =
          verify(() => syncDao.insertAll(captureAny())).captured.single
              as List<SyncMetadata>;
      expect(captured, hasLength(2));
      expect(
        captured.every(
          (m) => m.table == SupabaseConstants.growthMeasurementsTable,
        ),
        isTrue,
      );
      expect(captured.map((m) => m.recordId), containsAll(['gm-1', 'gm-2']));
    });

    test('saveAll with empty list does not create sync metadata', () async {
      await repository.saveAll([]);

      verify(() => localDao.insertAll([])).called(1);
      verifyNever(() => syncDao.insertAll(any()));
    });

    test(
      'remove hard deletes item creates pendingDelete metadata and tries remote delete',
      () async {
        final measurement = _makeMeasurement(id: 'gm-1', userId: userId);
        when(
          () => localDao.getById('gm-1'),
        ).thenAnswer((_) async => measurement);

        await repository.remove('gm-1');

        verify(() => localDao.hardDelete('gm-1')).called(1);
        final captured =
            verify(() => syncDao.insertItem(captureAny())).captured.single
                as SyncMetadata;
        expect(captured.table, SupabaseConstants.growthMeasurementsTable);
        expect(captured.recordId, 'gm-1');
        expect(captured.userId, userId);
        expect(captured.status, SyncStatus.pendingDelete);
        verify(() => remoteSource.deleteById('gm-1', userId: userId)).called(1);
        verify(
          () => syncDao.deleteByRecord(
            SupabaseConstants.growthMeasurementsTable,
            'gm-1',
          ),
        ).called(1);
      },
    );

    test('remove skips sync metadata when item is not found', () async {
      when(() => localDao.getById('missing')).thenAnswer((_) async => null);

      await repository.remove('missing');

      verify(() => localDao.hardDelete('missing')).called(1);
      verifyNever(() => syncDao.insertItem(any()));
      verifyNever(() => remoteSource.deleteById(any(), userId: any(named: 'userId')));
    });

    test('hardRemove delegates to DAO', () async {
      await repository.hardRemove('gm-1');
      verify(() => localDao.hardDelete('gm-1')).called(1);
    });

    test('pull uses fetchUpdatedSince when lastSyncedAt is provided', () async {
      final since = DateTime(2024, 1, 1);
      final remoteItems = [_makeMeasurement(id: 'gm-remote')];
      when(
        () => remoteSource.fetchUpdatedSince(userId, since),
      ).thenAnswer((_) async => remoteItems);

      await repository.pull(userId, lastSyncedAt: since);

      verify(() => remoteSource.fetchUpdatedSince(userId, since)).called(1);
      verify(() => localDao.insertAll(remoteItems)).called(1);
      verifyNever(() => remoteSource.fetchAll(any()));
    });

    test('pull uses fetchAll when lastSyncedAt is null', () async {
      await repository.pull(userId);
      verify(() => remoteSource.fetchAll(userId)).called(1);
      verifyNever(() => remoteSource.fetchUpdatedSince(any(), any()));
    });

    test('pull full sync removes local orphans not pending', () async {
      final local = [
        _makeMeasurement(id: 'keep-pending'),
        _makeMeasurement(id: 'delete-me'),
      ];
      when(() => remoteSource.fetchAll(userId)).thenAnswer((_) async => []);
      when(() => localDao.getAll(userId)).thenAnswer((_) async => local);
      when(
        () => syncDao.getPendingRecordIds(userId),
      ).thenAnswer((_) async => {'keep-pending'});

      await repository.pull(userId);

      verify(() => localDao.hardDelete('delete-me')).called(1);
      verifyNever(() => localDao.hardDelete('keep-pending'));
    });

    test('pull rethrows AppException', () async {
      when(
        () => remoteSource.fetchAll(userId),
      ).thenThrow(const DatabaseException('db failure'));

      expect(() => repository.pull(userId), throwsA(isA<DatabaseException>()));
    });

    test('pull logs unknown errors and does not throw', () async {
      when(
        () => remoteSource.fetchAll(userId),
      ).thenThrow(Exception('unexpected'));

      await expectLater(repository.pull(userId), completes);
    });

    test('push upserts remote and clears sync metadata on success', () async {
      final measurement = _makeMeasurement(id: 'gm-1');

      await repository.push(measurement);

      verify(() => remoteSource.upsert(measurement)).called(1);
      verify(
        () => syncDao.deleteByRecord(
          SupabaseConstants.growthMeasurementsTable,
          'gm-1',
        ),
      ).called(1);
    });

    test('push marks error when AppException occurs', () async {
      final measurement = _makeMeasurement(id: 'gm-1', userId: userId);
      final existing = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.growthMeasurementsTable,
        recordId: 'gm-1',
        userId: userId,
        retryCount: 1,
      );
      when(
        () => remoteSource.upsert(measurement),
      ).thenThrow(const DatabaseException('push failed'));
      when(
        () => syncDao.getByRecord(
          SupabaseConstants.growthMeasurementsTable,
          'gm-1',
        ),
      ).thenAnswer((_) async => existing);

      await repository.push(measurement);

      final updated =
          verify(() => syncDao.updateItem(captureAny())).captured.single
              as SyncMetadata;
      expect(updated.status, SyncStatus.error);
      expect(updated.retryCount, 2);
      expect(updated.errorMessage, 'push failed');
    });

    test(
      'pushAll iterates pending metadata and pushes existing records',
      () async {
        final gm1 = _makeMeasurement(id: 'gm-1');
        final pending = [
          TestFixtures.sampleSyncMetadata(
            id: 'meta-1',
            table: SupabaseConstants.growthMeasurementsTable,
            recordId: 'gm-1',
            userId: userId,
          ),
          TestFixtures.sampleSyncMetadata(
            id: 'meta-2',
            table: SupabaseConstants.growthMeasurementsTable,
            recordId: 'missing',
            userId: userId,
          ),
        ];
        when(
          () => syncDao.getPendingByTable(
            userId,
            SupabaseConstants.growthMeasurementsTable,
          ),
        ).thenAnswer((_) async => pending);
        when(() => localDao.getById('gm-1')).thenAnswer((_) async => gm1);
        when(() => localDao.getById('missing')).thenAnswer((_) async => null);

        await repository.pushAll(userId);

        verify(() => remoteSource.upsert(gm1)).called(1);
      },
    );

    test(
      'pushAll cleans orphan sync metadata for missing local records',
      () async {
        final pending = [
          TestFixtures.sampleSyncMetadata(
            id: 'meta-1',
            table: SupabaseConstants.growthMeasurementsTable,
            recordId: 'missing',
            userId: userId,
          ),
        ];
        when(
          () => syncDao.getPendingByTable(
            userId,
            SupabaseConstants.growthMeasurementsTable,
          ),
        ).thenAnswer((_) async => pending);
        when(() => localDao.getById('missing')).thenAnswer((_) async => null);

        await repository.pushAll(userId);

        verify(
          () => syncDao.deleteByRecord(
            SupabaseConstants.growthMeasurementsTable,
            'missing',
          ),
        ).called(1);
        verifyNever(() => remoteSource.upsert(any()));
      },
    );

    test('pushAll processes pendingDelete records by remote delete', () async {
      final pendingDelete = TestFixtures.sampleSyncMetadata(
        id: 'meta-del',
        table: SupabaseConstants.growthMeasurementsTable,
        recordId: 'del-1',
        userId: userId,
        status: SyncStatus.pendingDelete,
      );
      when(
        () => syncDao.getPendingByTable(
          userId,
          SupabaseConstants.growthMeasurementsTable,
        ),
      ).thenAnswer((_) async => [pendingDelete]);

      await repository.pushAll(userId);

      verify(() => remoteSource.deleteById('del-1', userId: userId)).called(1);
      verify(
        () => syncDao.deleteByRecord(
          SupabaseConstants.growthMeasurementsTable,
          'del-1',
        ),
      ).called(1);
    });

    test(
      'pushAll marks error when pendingDelete remote delete fails',
      () async {
        final pendingDelete = TestFixtures.sampleSyncMetadata(
          id: 'meta-del',
          table: SupabaseConstants.growthMeasurementsTable,
          recordId: 'del-1',
          userId: userId,
          status: SyncStatus.pendingDelete,
        );
        final existing = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.growthMeasurementsTable,
          recordId: 'del-1',
          userId: userId,
          retryCount: 0,
        );
        when(
          () => syncDao.getPendingByTable(
            userId,
            SupabaseConstants.growthMeasurementsTable,
          ),
        ).thenAnswer((_) async => [pendingDelete]);
        when(
          () => remoteSource.deleteById('del-1', userId: userId),
        ).thenThrow(const NetworkException('network error'));
        when(
          () => syncDao.getByRecord(
            SupabaseConstants.growthMeasurementsTable,
            'del-1',
          ),
        ).thenAnswer((_) async => existing);

        await repository.pushAll(userId);

        final updated =
            verify(() => syncDao.updateItem(captureAny())).captured.single
                as SyncMetadata;
        expect(updated.status, SyncStatus.error);
        expect(updated.retryCount, 1);
      },
    );

    test('watchByChick delegates to DAO', () {
      final expected = [_makeMeasurement(id: 'gm-1')];
      when(
        () => localDao.watchByChick('chick-1'),
      ).thenAnswer((_) => Stream.value(expected));

      expect(repository.watchByChick('chick-1'), emits(expected));
      verify(() => localDao.watchByChick('chick-1')).called(1);
    });

    test('getLatest delegates to DAO', () async {
      final measurement = _makeMeasurement(id: 'gm-latest');
      when(
        () => localDao.getLatest('chick-1'),
      ).thenAnswer((_) async => measurement);

      final result = await repository.getLatest('chick-1');
      expect(result, measurement);
      verify(() => localDao.getLatest('chick-1')).called(1);
    });

    test('getLatest returns null when no measurements', () async {
      when(() => localDao.getLatest('chick-1')).thenAnswer((_) async => null);

      final result = await repository.getLatest('chick-1');
      expect(result, isNull);
    });
  });
}
