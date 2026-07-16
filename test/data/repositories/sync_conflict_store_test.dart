import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/conflict_history_dao.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_conflict_payload_codec.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_conflict_store.dart';

class _MockConflictHistoryDao extends Mock implements ConflictHistoryDao {}

class _MockCodec extends Mock implements SyncConflictPayloadCodec {}

void main() {
  late _MockConflictHistoryDao dao;
  late _MockCodec codec;
  late SyncConflictStore store;

  const conflict = (
    recordId: 'bird-1',
    detail: 'Bird',
    localPayload: <String, dynamic>{
      'id': 'bird-1',
      'user_id': 'user-1',
      'name': 'Local',
    },
    serverPayload: <String, dynamic>{
      'id': 'bird-1',
      'user_id': 'user-1',
      'name': 'Server',
    },
  );

  setUp(() {
    dao = _MockConflictHistoryDao();
    codec = _MockCodec();
    store = SyncConflictStore(
      dao: dao,
      codec: codec,
      now: () => DateTime.utc(2026, 7, 17),
    );
  });

  test('persists encrypted local and server snapshots together', () async {
    when(
      () => codec.encode(
        tableName: 'birds',
        recordId: 'bird-1',
        userId: 'user-1',
        payload: conflict.localPayload,
      ),
    ).thenAnswer((_) async => 'encrypted-local');
    when(
      () => codec.encode(
        tableName: 'birds',
        recordId: 'bird-1',
        userId: 'user-1',
        payload: conflict.serverPayload,
      ),
    ).thenAnswer((_) async => 'encrypted-server');
    when(
      () => dao.insertAllPreservingOldestRecoverable(any()),
    ).thenAnswer((_) async => 1);

    await store.persist(
      userId: 'user-1',
      tableName: 'birds',
      conflicts: <PullConflict>[conflict],
    );

    final captured =
        verify(
              () => dao.insertAllPreservingOldestRecoverable(captureAny()),
            ).captured.single
            as List<ConflictHistory>;
    expect(captured, hasLength(1));
    expect(captured.single.localPayload, 'encrypted-local');
    expect(captured.single.serverPayload, 'encrypted-server');
    expect(captured.single.payloadVersion, 1);
    expect(captured.single.createdAt, DateTime.utc(2026, 7, 17));
  });

  test('surfaces a sanitized failure before overwrite can continue', () async {
    when(
      () => codec.encode(
        tableName: any(named: 'tableName'),
        recordId: any(named: 'recordId'),
        userId: any(named: 'userId'),
        payload: any(named: 'payload'),
      ),
    ).thenThrow(const SyncConflictPayloadException('payload_too_large'));

    await expectLater(
      store.persist(
        userId: 'user-1',
        tableName: 'birds',
        conflicts: <PullConflict>[conflict],
      ),
      throwsA(
        isA<DatabaseException>()
            .having((e) => e.code, 'code', 'payload_too_large')
            .having((e) => e.originalError, 'originalError', isNull),
      ),
    );
    verifyNever(() => dao.insertAllPreservingOldestRecoverable(any()));
  });
}
