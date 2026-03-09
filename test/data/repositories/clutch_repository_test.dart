import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/clutch_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/clutch_repository.dart';

import '../../helpers/test_fixtures.dart';

class MockClutchesDao extends Mock implements ClutchesDao {}

class MockClutchRemoteSource extends Mock implements ClutchRemoteSource {}

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

void main() {
  late MockClutchesDao localDao;
  late MockClutchRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late ClutchRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(TestFixtures.sampleClutch());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockClutchesDao();
    remoteSource = MockClutchRemoteSource();
    syncDao = MockSyncMetadataDao();

    repository = ClutchRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
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
    when(() => localDao.getByBreeding(any())).thenAnswer((_) async => []);

    when(() => remoteSource.fetchAll(any())).thenAnswer((_) async => []);
    when(
      () => remoteSource.fetchUpdatedSince(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});

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

  group('ClutchRepository', () {
    test('watchAll delegates to DAO stream', () {
      final expected = [TestFixtures.sampleClutch(id: 'clutch-1')];
      when(
        () => localDao.watchAll(userId),
      ).thenAnswer((_) => Stream.value(expected));

      expect(repository.watchAll(userId), emits(expected));
      verify(() => localDao.watchAll(userId)).called(1);
    });

    test('watchById delegates to DAO stream', () {
      final clutch = TestFixtures.sampleClutch(id: 'clutch-1');
      when(
        () => localDao.watchById('clutch-1'),
      ).thenAnswer((_) => Stream.value(clutch));

      expect(repository.watchById('clutch-1'), emits(clutch));
      verify(() => localDao.watchById('clutch-1')).called(1);
    });

    test('getAll delegates to DAO', () async {
      final expected = [TestFixtures.sampleClutch(id: 'clutch-1')];
      when(() => localDao.getAll(userId)).thenAnswer((_) async => expected);

      final result = await repository.getAll(userId);
      expect(result, expected);
      verify(() => localDao.getAll(userId)).called(1);
    });

    test('getById delegates to DAO and may return null', () async {
      final clutch = TestFixtures.sampleClutch(id: 'clutch-1');
      when(() => localDao.getById('clutch-1')).thenAnswer((_) async => clutch);
      when(() => localDao.getById('missing')).thenAnswer((_) async => null);

      expect(await repository.getById('clutch-1'), clutch);
      expect(await repository.getById('missing'), isNull);
    });

    test(
      'save inserts item marks sync pending and tries immediate push',
      () async {
        final clutch = TestFixtures.sampleClutch(id: 'clutch-1');

        await repository.save(clutch);

        verify(() => localDao.insertItem(clutch)).called(1);
        final captured =
            verify(() => syncDao.insertItem(captureAny())).captured.single
                as SyncMetadata;
        expect(captured.table, SupabaseConstants.clutchesTable);
        expect(captured.recordId, clutch.id);
        expect(captured.userId, clutch.userId);
        expect(captured.status, SyncStatus.pending);
        verify(() => remoteSource.upsert(clutch)).called(1);
      },
    );

    test('saveAll inserts all and creates metadata for each item', () async {
      final items = [
        TestFixtures.sampleClutch(id: 'clutch-1'),
        TestFixtures.sampleClutch(id: 'clutch-2'),
      ];

      await repository.saveAll(items);

      verify(() => localDao.insertAll(items)).called(1);
      final captured =
          verify(() => syncDao.insertAll(captureAny())).captured.single
              as List<SyncMetadata>;
      expect(captured, hasLength(2));
      expect(
        captured.every((m) => m.table == SupabaseConstants.clutchesTable),
        isTrue,
      );
      expect(
        captured.map((m) => m.recordId),
        containsAll(['clutch-1', 'clutch-2']),
      );
    });

    test('saveAll with empty list does not create sync metadata', () async {
      await repository.saveAll([]);

      verify(() => localDao.insertAll([])).called(1);
      verifyNever(() => syncDao.insertAll(any()));
    });

    test(
      'remove soft deletes item marks pending and pushes deleted copy',
      () async {
        final clutch = TestFixtures.sampleClutch(
          id: 'clutch-1',
          userId: userId,
        );
        when(
          () => localDao.getById('clutch-1'),
        ).thenAnswer((_) async => clutch);

        await repository.remove('clutch-1');

        verify(() => localDao.softDelete('clutch-1')).called(1);
        verify(() => syncDao.insertItem(any())).called(1);
        final pushedClutch =
            verify(() => remoteSource.upsert(captureAny())).captured.single
                as Clutch;
        expect(pushedClutch.id, clutch.id);
        expect(pushedClutch.isDeleted, isTrue);
      },
    );

    test('remove skips sync metadata when item is not found', () async {
      when(() => localDao.getById('missing')).thenAnswer((_) async => null);

      await repository.remove('missing');

      verify(() => localDao.softDelete('missing')).called(1);
      verifyNever(() => syncDao.insertItem(any()));
      verifyNever(() => remoteSource.upsert(any()));
    });

    test('hardRemove delegates to DAO', () async {
      await repository.hardRemove('clutch-1');
      verify(() => localDao.hardDelete('clutch-1')).called(1);
    });

    test('pull uses fetchUpdatedSince when lastSyncedAt is provided', () async {
      final since = DateTime(2024, 1, 1);
      final remoteItems = [TestFixtures.sampleClutch(id: 'clutch-remote')];
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
        TestFixtures.sampleClutch(id: 'keep-pending'),
        TestFixtures.sampleClutch(id: 'delete-me'),
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
      final clutch = TestFixtures.sampleClutch(id: 'clutch-1');

      await repository.push(clutch);

      verify(() => remoteSource.upsert(clutch)).called(1);
      verify(
        () =>
            syncDao.deleteByRecord(SupabaseConstants.clutchesTable, 'clutch-1'),
      ).called(1);
    });

    test('push marks error when AppException occurs', () async {
      final clutch = TestFixtures.sampleClutch(id: 'clutch-1', userId: userId);
      final existing = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.clutchesTable,
        recordId: 'clutch-1',
        userId: userId,
        retryCount: 1,
      );
      when(
        () => remoteSource.upsert(clutch),
      ).thenThrow(const DatabaseException('push failed'));
      when(
        () => syncDao.getByRecord(SupabaseConstants.clutchesTable, 'clutch-1'),
      ).thenAnswer((_) async => existing);

      await repository.push(clutch);

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
        final clutch1 = TestFixtures.sampleClutch(id: 'clutch-1');
        final pending = [
          TestFixtures.sampleSyncMetadata(
            id: 'meta-1',
            table: SupabaseConstants.clutchesTable,
            recordId: 'clutch-1',
            userId: userId,
          ),
          TestFixtures.sampleSyncMetadata(
            id: 'meta-2',
            table: SupabaseConstants.clutchesTable,
            recordId: 'missing',
            userId: userId,
          ),
        ];
        when(
          () => syncDao.getPendingByTable(
            userId,
            SupabaseConstants.clutchesTable,
          ),
        ).thenAnswer((_) async => pending);
        when(
          () => localDao.getById('clutch-1'),
        ).thenAnswer((_) async => clutch1);
        when(() => localDao.getById('missing')).thenAnswer((_) async => null);

        await repository.pushAll(userId);

        verify(() => remoteSource.upsert(clutch1)).called(1);
      },
    );

    test(
      'pushAll cleans orphan sync metadata for missing local records',
      () async {
        final pending = [
          TestFixtures.sampleSyncMetadata(
            id: 'meta-1',
            table: SupabaseConstants.clutchesTable,
            recordId: 'missing',
            userId: userId,
          ),
        ];
        when(
          () => syncDao.getPendingByTable(
            userId,
            SupabaseConstants.clutchesTable,
          ),
        ).thenAnswer((_) async => pending);
        when(() => localDao.getById('missing')).thenAnswer((_) async => null);

        await repository.pushAll(userId);

        verify(
          () => syncDao.deleteByRecord(
            SupabaseConstants.clutchesTable,
            'missing',
          ),
        ).called(1);
        verifyNever(() => remoteSource.upsert(any()));
      },
    );

    test('getByBreeding delegates to DAO', () async {
      final expected = [TestFixtures.sampleClutch(id: 'clutch-1')];
      when(
        () => localDao.getByBreeding('pair-1'),
      ).thenAnswer((_) async => expected);

      final result = await repository.getByBreeding('pair-1');
      expect(result, expected);
      verify(() => localDao.getByBreeding('pair-1')).called(1);
    });
  });
}
