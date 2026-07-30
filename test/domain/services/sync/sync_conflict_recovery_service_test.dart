import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_conflict_payload_codec.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_conflict_store.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_conflict_recovery_service.dart';

class _MockCodec extends Mock implements SyncConflictPayloadCodec {}

void main() {
  const userId = 'user-1';
  const localPayload = <String, dynamic>{
    'id': 'bird-1',
    'name': 'Local restored',
    'gender': 'male',
    'user_id': userId,
    'notes': 'private local note',
  };
  const serverPayload = <String, dynamic>{
    'id': 'bird-1',
    'name': 'Server wins',
    'gender': 'male',
    'user_id': userId,
    'notes': 'server note',
  };

  late AppDatabase db;
  late _MockCodec codec;
  late ProviderContainer container;

  ConflictHistory conflict({
    String id = 'conflict-1',
    String? encrypted = 'encrypted-local',
    int? version = 1,
  }) {
    return ConflictHistory(
      id: id,
      userId: userId,
      tableName: 'birds',
      recordId: 'bird-1',
      description: 'Bird',
      conflictType: ConflictType.serverWins,
      localPayload: encrypted,
      serverPayload: 'encrypted-server',
      payloadVersion: version,
      createdAt: DateTime.utc(2026, 7, 17),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    codec = _MockCodec();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncConflictPayloadCodecProvider.overrideWithValue(codec),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> seedServerWinsState({String metadataId = 'metadata-1'}) async {
    await db.birdsDao.insertItem(Bird.fromJson(serverPayload));
    await db.syncMetadataDao.insertItem(
      SyncMetadata(
        id: metadataId,
        table: 'birds',
        userId: userId,
        status: SyncStatus.pending,
        recordId: 'bird-1',
      ),
    );
  }

  test(
    'keep remote resolves history and removes only matching pending metadata',
    () async {
      await seedServerWinsState();
      await db.conflictHistoryDao.insert(conflict());
      await db.syncMetadataDao.insertItem(
        const SyncMetadata(
          id: 'metadata-2',
          table: 'birds',
          userId: userId,
          status: SyncStatus.pending,
          recordId: 'bird-2',
        ),
      );

      final resolved = await container
          .read(syncConflictRecoveryServiceProvider)
          .keepRemote(userId);

      expect(resolved, 1);
      expect((await db.birdsDao.getById('bird-1'))?.name, 'Server wins');
      expect(
        await db.syncMetadataDao.getByRecords('birds', ['bird-1']),
        isEmpty,
      );
      expect(
        await db.syncMetadataDao.getByRecords('birds', ['bird-2']),
        hasLength(1),
      );
      expect(
        (await db.conflictHistoryDao.getById('conflict-1'))?.resolvedAt,
        isNotNull,
      );
      expect(
        (await db.conflictHistoryDao.getById('conflict-1'))?.conflictType,
        ConflictType.serverWins,
      );
      expect(await db.conflictHistoryDao.watchAll(userId).first, hasLength(1));
    },
  );

  test(
    'restores local fields and marks the record pending atomically',
    () async {
      await seedServerWinsState();
      await db.conflictHistoryDao.insert(conflict());
      when(
        () => codec.decode(
          encryptedPayload: 'encrypted-local',
          payloadVersion: 1,
          tableName: 'birds',
          recordId: 'bird-1',
          userId: userId,
        ),
      ).thenAnswer((_) async => localPayload);

      final result = await container
          .read(syncConflictRecoveryServiceProvider)
          .retryLocal(userId);

      expect(result.restored, 1);
      expect(result.failed, 0);
      expect(result.restoredRecords, const [
        (tableName: 'birds', recordId: 'bird-1'),
      ]);
      expect(
        () => result.restoredRecords.add((
          tableName: 'birds',
          recordId: 'other-bird',
        )),
        throwsUnsupportedError,
      );
      final bird = await db.birdsDao.getById('bird-1');
      expect(bird?.name, 'Local restored');
      expect(bird?.notes, 'private local note');
      final metadata = await db.syncMetadataDao.getByRecords('birds', [
        'bird-1',
      ]);
      expect(metadata, hasLength(1));
      expect(metadata.single.id, 'metadata-1');
      expect(metadata.single.status, SyncStatus.pending);
      expect(metadata.single.userId, userId);
      expect(
        await container
            .read(syncConflictRecoveryServiceProvider)
            .areRestoredRecordsSynced(result.restoredRecords),
        isFalse,
      );
      await db.syncMetadataDao.deleteByRecord('birds', 'bird-1');
      expect(
        await container
            .read(syncConflictRecoveryServiceProvider)
            .areRestoredRecordsSynced(result.restoredRecords),
        isTrue,
      );
      expect(
        (await db.conflictHistoryDao.getById('conflict-1'))?.resolvedAt,
        isNotNull,
      );
      expect(
        (await db.conflictHistoryDao.getById('conflict-1'))?.conflictType,
        ConflictType.localOverwritten,
      );
    },
  );

  test(
    'old payload-less history stays unresolved with fallback result',
    () async {
      await seedServerWinsState();
      await db.conflictHistoryDao.insert(
        conflict(encrypted: null, version: null),
      );

      final result = await container
          .read(syncConflictRecoveryServiceProvider)
          .retryLocal(userId);

      expect(result.unavailable, 1);
      expect(result.restored, 0);
      expect((await db.birdsDao.getById('bird-1'))?.name, 'Server wins');
      expect(
        await db.syncMetadataDao.getByRecords('birds', ['bird-1']),
        hasLength(1),
      );
      expect(
        (await db.conflictHistoryDao.getById('conflict-1'))?.resolvedAt,
        isNull,
      );
      verifyNever(
        () => codec.decode(
          encryptedPayload: any(named: 'encryptedPayload'),
          payloadVersion: any(named: 'payloadVersion'),
          tableName: any(named: 'tableName'),
          recordId: any(named: 'recordId'),
          userId: any(named: 'userId'),
        ),
      );
    },
  );

  test(
    'corrupt payload changes neither local row nor resolution state',
    () async {
      await seedServerWinsState();
      await db.conflictHistoryDao.insert(conflict());
      when(
        () => codec.decode(
          encryptedPayload: any(named: 'encryptedPayload'),
          payloadVersion: any(named: 'payloadVersion'),
          tableName: any(named: 'tableName'),
          recordId: any(named: 'recordId'),
          userId: any(named: 'userId'),
        ),
      ).thenThrow(const SyncConflictPayloadException('payload_decode_failed'));

      final result = await container
          .read(syncConflictRecoveryServiceProvider)
          .retryLocal(userId);

      expect(result.failed, 1);
      expect(result.restored, 0);
      expect((await db.birdsDao.getById('bird-1'))?.name, 'Server wins');
      final metadata = await db.syncMetadataDao.getByRecords('birds', [
        'bird-1',
      ]);
      expect(metadata, hasLength(1));
      expect(metadata.single.id, 'metadata-1');
      expect(
        (await db.conflictHistoryDao.getById('conflict-1'))?.resolvedAt,
        isNull,
      );
    },
  );

  test('coalesces racing duplicate retries into one restore', () async {
    await seedServerWinsState();
    await db.conflictHistoryDao.insert(conflict());
    final gate = Completer<void>();
    when(
      () => codec.decode(
        encryptedPayload: any(named: 'encryptedPayload'),
        payloadVersion: any(named: 'payloadVersion'),
        tableName: any(named: 'tableName'),
        recordId: any(named: 'recordId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {
      await gate.future;
      return localPayload;
    });

    final service = container.read(syncConflictRecoveryServiceProvider);
    final first = service.retryLocal(userId);
    final second = service.retryLocal(userId);
    gate.complete();
    final results = await Future.wait([first, second]);

    expect(results.map((result) => result.restored), everyElement(1));
    verify(
      () => codec.decode(
        encryptedPayload: any(named: 'encryptedPayload'),
        payloadVersion: any(named: 'payloadVersion'),
        tableName: any(named: 'tableName'),
        recordId: any(named: 'recordId'),
        userId: any(named: 'userId'),
      ),
    ).called(1);
    final metadata = await db.syncMetadataDao.getByRecords('birds', ['bird-1']);
    expect(metadata, hasLength(1));
    expect(metadata.single.id, 'metadata-1');
    expect(metadata.single.status, SyncStatus.pending);
  });

  test(
    'repeated pull keeps first local snapshot and retry restores it',
    () async {
      await db.birdsDao.insertItem(Bird.fromJson(localPayload));
      await db.syncMetadataDao.insertItem(
        const SyncMetadata(
          id: 'metadata-1',
          table: 'birds',
          userId: userId,
          status: SyncStatus.pending,
          recordId: 'bird-1',
        ),
      );
      when(
        () => codec.encode(
          tableName: any(named: 'tableName'),
          recordId: any(named: 'recordId'),
          userId: any(named: 'userId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((invocation) async {
        final payload =
            invocation.namedArguments[#payload]! as Map<String, dynamic>;
        return payload['name'] == 'Local restored'
            ? 'encrypted-original-local'
            : 'encrypted-server';
      });
      final store = SyncConflictStore(
        dao: db.conflictHistoryDao,
        codec: codec,
        now: () => DateTime.utc(2026, 7, 17),
      );

      await store.persist(
        userId: userId,
        tableName: 'birds',
        conflicts: const <PullConflict>[
          (
            recordId: 'bird-1',
            detail: 'Bird',
            localPayload: localPayload,
            serverPayload: serverPayload,
          ),
        ],
      );
      await db.birdsDao.insertItem(Bird.fromJson(serverPayload));
      await store.persist(
        userId: userId,
        tableName: 'birds',
        conflicts: const <PullConflict>[
          (
            recordId: 'bird-1',
            detail: 'Bird',
            localPayload: serverPayload,
            serverPayload: serverPayload,
          ),
        ],
      );

      final unresolved = await db.conflictHistoryDao.getUnresolved(userId);
      expect(unresolved, hasLength(1));
      expect(unresolved.single.localPayload, 'encrypted-original-local');
      when(
        () => codec.decode(
          encryptedPayload: 'encrypted-original-local',
          payloadVersion: 1,
          tableName: 'birds',
          recordId: 'bird-1',
          userId: userId,
        ),
      ).thenAnswer((_) async => localPayload);

      final result = await container
          .read(syncConflictRecoveryServiceProvider)
          .retryLocal(userId);

      expect(result.restored, 1);
      expect((await db.birdsDao.getById('bird-1'))?.name, 'Local restored');
      final metadata = await db.syncMetadataDao.getByRecords('birds', [
        'bird-1',
      ]);
      expect(metadata, hasLength(1));
      expect(metadata.single.id, 'metadata-1');
      expect(metadata.single.status, SyncStatus.pending);
    },
  );
}
