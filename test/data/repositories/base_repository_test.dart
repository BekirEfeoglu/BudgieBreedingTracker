import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';

import '../../helpers/mocks.dart';

const _tableName = 'test_entities';
const _userId = 'user-1';

class _TestEntity {
  const _TestEntity({required this.id, required this.userId});

  final String id;
  final String userId;
}

class _TestValidatedRepository extends BaseRepository<_TestEntity>
    with SyncableRepository<_TestEntity>, ValidatedSyncMixin<_TestEntity> {
  _TestValidatedRepository({required this.syncDao});

  @override
  final SyncMetadataDao syncDao;

  final Map<String, _TestEntity> _localItems = {};
  final Map<String, String?> _validationErrors = {};
  final List<String> pushedIds = [];
  bool throwOnPush = false;

  void put(_TestEntity item) {
    _localItems[item.id] = item;
  }

  void setValidationError(String id, String? error) {
    _validationErrors[id] = error;
  }

  @override
  String get syncTableName => _tableName;

  @override
  String get syncLogTag => 'TestRepo';

  @override
  Future<_TestEntity?> getLocalById(String id) async => _localItems[id];

  @override
  Future<String?> validateForeignKeys(_TestEntity item) async =>
      _validationErrors[item.id];

  @override
  String getEntityId(_TestEntity item) => item.id;

  @override
  String getEntityUserId(_TestEntity item) => item.userId;

  @override
  Future<void> pull(String userId, {DateTime? lastSyncedAt}) async {}

  @override
  Future<void> push(_TestEntity item) async {
    if (throwOnPush) {
      throw Exception('push failed');
    }
    pushedIds.add(item.id);
  }

  @override
  Future<void> upsertChunkForSync(List<_TestEntity> chunk) async {
    for (final item in chunk) {
      await push(item);
    }
  }

  @override
  Future<void> deleteRemoteForSync(String recordId, String userId) async {}

  @override
  Future<List<_TestEntity>> getAll(String userId) async => const [];

  @override
  Future<_TestEntity?> getById(String id) async => null;

  @override
  Future<void> hardRemove(String id) async {}

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> save(_TestEntity item) async {}

  @override
  Future<void> saveAll(List<_TestEntity> items) async {}

  @override
  Stream<List<_TestEntity>> watchAll(String userId) => const Stream.empty();

  @override
  Stream<_TestEntity?> watchById(String id) => const Stream.empty();
}

SyncMetadata _metadata({
  required String id,
  required String recordId,
  String table = _tableName,
  String userId = _userId,
  SyncStatus status = SyncStatus.pending,
  int? retryCount,
  String? errorMessage,
  DateTime? createdAt,
}) {
  return SyncMetadata(
    id: id,
    table: table,
    userId: userId,
    status: status,
    recordId: recordId,
    retryCount: retryCount,
    errorMessage: errorMessage,
    createdAt: createdAt,
  );
}

void main() {
  late MockSyncMetadataDao mockSyncDao;
  late _TestValidatedRepository repository;

  setUpAll(() {
    registerFallbackValue(_metadata(id: 'fallback', recordId: 'fallback'));
  });

  setUp(() {
    mockSyncDao = MockSyncMetadataDao();
    repository = _TestValidatedRepository(syncDao: mockSyncDao);

    when(() => mockSyncDao.getErrors(any())).thenAnswer((_) async => []);
    when(
      () => mockSyncDao.getErrorsByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => mockSyncDao.getPending(any())).thenAnswer((_) async => []);
    when(
      () => mockSyncDao.getPendingByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => mockSyncDao.hardDelete(any())).thenAnswer((_) async {});
    when(
      () => mockSyncDao.deleteByRecord(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockSyncDao.deleteByRecords(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockSyncDao.getByRecord(any(), any()),
    ).thenAnswer((_) async => null);
    when(() => mockSyncDao.updateItem(any())).thenAnswer((_) async {});
  });

  group('SyncableRepository', () {
    test('tryImmediatePush swallows push failures', () async {
      repository.throwOnPush = true;
      const item = _TestEntity(id: 'entity-1', userId: _userId);

      await repository.tryImmediatePush(item);
      expect(repository.pushedIds, isEmpty);
    });
  });

  group('ValidatedSyncMixin', () {
    test(
      'clearStaleErrors removes only stale errors for target table',
      () async {
        when(
          () => mockSyncDao.getErrorsByTable(_userId, _tableName),
        ).thenAnswer(
          (_) async => [
            _metadata(
              id: 'stale',
              recordId: 'r1',
              status: SyncStatus.error,
              retryCount: ValidatedSyncMixin.maxSyncRetries,
              // Exhausted retries AND aged past the 24h window → unrecoverable.
              createdAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
            _metadata(
              id: 'fresh',
              recordId: 'r2',
              status: SyncStatus.error,
              retryCount: ValidatedSyncMixin.maxSyncRetries - 1,
              createdAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ],
        );

        await repository.clearStaleErrors(_userId);

        verify(() => mockSyncDao.hardDelete('stale')).called(1);
        verifyNever(() => mockSyncDao.hardDelete('fresh'));
      },
    );

    test(
      'clearStaleErrors keeps retry-exhausted records still inside the 24h window',
      () async {
        when(
          () => mockSyncDao.getErrorsByTable(_userId, _tableName),
        ).thenAnswer(
          (_) async => [
            _metadata(
              id: 'recent',
              recordId: 'r3',
              status: SyncStatus.error,
              retryCount: ValidatedSyncMixin.maxSyncRetries,
              // Retries exhausted but created moments ago → still protected.
              createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
          ],
        );

        await repository.clearStaleErrors(_userId);

        verifyNever(() => mockSyncDao.hardDelete('recent'));
      },
    );

    test(
      'pushAll cleans orphan metadata when local record is missing',
      () async {
        when(
          () => mockSyncDao.getPendingByTable(_userId, _tableName),
        ).thenAnswer(
          (_) async => [
            _metadata(id: 'pending-1', recordId: 'missing-record'),
            _metadata(
              id: 'pending-2',
              recordId: 'other-table-record',
              table: 'different_table',
            ),
          ],
        );

        await repository.pushAll(_userId);

        verify(
          () => mockSyncDao.deleteByRecord(_tableName, 'missing-record'),
        ).called(1);
        expect(repository.pushedIds, isEmpty);
      },
    );

    test(
      'pushAll marks true FK orphans as sync error with incremented retry',
      () async {
        const entity = _TestEntity(id: 'entity-2', userId: _userId);
        repository.put(entity);
        repository.setValidationError('entity-2', 'parent not found locally');

        when(
          () => mockSyncDao.getPendingByTable(_userId, _tableName),
        ).thenAnswer(
          (_) async => [_metadata(id: 'pending-1', recordId: 'entity-2')],
        );
        when(() => mockSyncDao.getByRecord(_tableName, 'entity-2')).thenAnswer(
          (_) async => _metadata(
            id: 'meta-entity-2',
            recordId: 'entity-2',
            status: SyncStatus.pending,
            retryCount: 2,
          ),
        );

        SyncMetadata? updated;
        when(() => mockSyncDao.updateItem(any())).thenAnswer((
          invocation,
        ) async {
          updated = invocation.positionalArguments.first as SyncMetadata;
        });

        await repository.pushAll(_userId);

        expect(updated, isNotNull);
        expect(updated!.status, SyncStatus.error);
        expect(updated!.retryCount, 3);
        expect(updated!.errorMessage, contains('not found locally'));
        expect(repository.pushedIds, isEmpty);
      },
    );

    test(
      'pushAll skips dependency-waiting records without marking error',
      () async {
        const entity = _TestEntity(id: 'entity-3', userId: _userId);
        repository.put(entity);
        repository.setValidationError('entity-3', 'parent not yet synced');

        when(
          () => mockSyncDao.getPendingByTable(_userId, _tableName),
        ).thenAnswer(
          (_) async => [_metadata(id: 'pending-1', recordId: 'entity-3')],
        );

        await repository.pushAll(_userId);

        verifyNever(() => mockSyncDao.getByRecord(_tableName, 'entity-3'));
        verifyNever(() => mockSyncDao.updateItem(any()));
        expect(repository.pushedIds, isEmpty);
      },
    );

    test('pushAll pushes valid pending records', () async {
      const entity = _TestEntity(id: 'entity-4', userId: _userId);
      repository.put(entity);

      when(() => mockSyncDao.getPendingByTable(_userId, _tableName)).thenAnswer(
        (_) async => [_metadata(id: 'pending-1', recordId: 'entity-4')],
      );

      await repository.pushAll(_userId);

      expect(repository.pushedIds, ['entity-4']);
      verifyNever(() => mockSyncDao.deleteByRecord(_tableName, 'entity-4'));
    });

    test(
      'markSyncError creates new error entry when metadata does not exist',
      () async {
        when(
          () => mockSyncDao.getByRecord(_tableName, 'entity-5'),
        ).thenAnswer((_) async => null);
        when(() => mockSyncDao.insertItem(any())).thenAnswer((_) async {});

        await repository.markSyncError('entity-5', _userId, 'missing parent');

        verifyNever(() => mockSyncDao.updateItem(any()));
        final captured =
            verify(() => mockSyncDao.insertItem(captureAny())).captured.single
                as SyncMetadata;
        expect(captured.table, _tableName);
        expect(captured.recordId, 'entity-5');
        expect(captured.userId, _userId);
        expect(captured.status, SyncStatus.error);
        expect(captured.errorMessage, 'missing parent');
        expect(captured.retryCount, 1);
      },
    );
  });

  group('detectPullConflicts', () {
    ({String id, String name}) rec(String id, String name) =>
        (id: id, name: name);

    test('flags a pending local row overwritten by remote regardless of order', () {
      final remote = [rec('a', 'RA'), rec('b', 'RB'), rec('c', 'RC')];
      final localMap = {
        'a': rec('a', 'LA'),
        'b': rec('b', 'LB'),
        // 'c' is NOT present locally.
      };

      final conflicts = detectPullConflicts<({String id, String name})>(
        remote: remote,
        localMap: localMap,
        pendingIds: {'a', 'b', 'c'},
        idOf: (e) => e.id,
        detailOf: (e) => e.name,
      );

      // a + b are pending AND present locally → conflict, timestamp-agnostic
      // (the whole point: an unpushed edit is discarded on ANY overwrite).
      // c is pending but absent locally → nothing to discard → no conflict.
      expect(conflicts.map((c) => c.recordId), ['a', 'b']);
      expect(conflicts.first.detail, 'RA');
    });

    test('ignores rows that are not pending even if present locally', () {
      final conflicts = detectPullConflicts<({String id, String name})>(
        remote: [rec('a', 'RA')],
        localMap: {'a': rec('a', 'LA')},
        pendingIds: const {},
        idOf: (e) => e.id,
        detailOf: (e) => e.name,
      );

      expect(conflicts, isEmpty);
    });
  });
}
