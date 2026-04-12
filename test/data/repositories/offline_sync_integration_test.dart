import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/bird_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/egg_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart'
    show syncOrchestratorProvider;
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import '../../helpers/mocks.dart';

class MockBirdsDao extends Mock implements BirdsDao {}

class MockBirdRemoteSource extends Mock implements BirdRemoteSource {}

class MockEggRemoteSource extends Mock implements EggRemoteSource {}

Bird _bird({required String id, String name = 'Bird', DateTime? updatedAt}) {
  return Bird(
    id: id,
    userId: 'user-1',
    name: name,
    gender: BirdGender.male,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime(2024, 1, 1),
  );
}

Egg _egg({required String id, String? clutchId, String? incubationId}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2024, 1, 1),
    status: EggStatus.incubating,
    clutchId: clutchId,
    incubationId: incubationId,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

SyncMetadata _meta({
  required String id,
  required String table,
  required String recordId,
  SyncStatus status = SyncStatus.pending,
  int? retryCount,
}) {
  return SyncMetadata(
    id: id,
    table: table,
    userId: 'user-1',
    recordId: recordId,
    status: status,
    retryCount: retryCount,
    updatedAt: DateTime(2024, 1, 1),
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(_bird(id: 'fallback'));
    registerFallbackValue(_egg(id: 'fallback'));
    registerFallbackValue(
      _meta(
        id: 'fallback',
        table: SupabaseConstants.birdsTable,
        recordId: 'fallback',
      ),
    );
    registerFallbackValue(DateTime(2024, 1, 1));
  });

  group('offline-first sync integration', () {
    test(
      'offline create keeps pending metadata and online push clears it',
      () async {
        final localDao = MockBirdsDao();
        final remote = MockBirdRemoteSource();
        final syncDao = MockSyncMetadataDao();
        final repo = BirdRepository(
          localDao: localDao,
          remoteSource: remote,
          syncDao: syncDao,
        );
        final bird = _bird(id: 'bird-1');
        final pending = _meta(
          id: 'm1',
          table: SupabaseConstants.birdsTable,
          recordId: bird.id,
        );

        when(() => localDao.insertItem(any())).thenAnswer((_) async {});
        when(
          () => syncDao.getByRecord(any(), any()),
        ).thenAnswer((_) async => null);
        when(() => syncDao.insertItem(any())).thenAnswer((_) async {});
        when(() => remote.upsert(any())).thenThrow(Exception('offline'));
        when(
          () => syncDao.getPendingByTable(userId, SupabaseConstants.birdsTable),
        ).thenAnswer((_) async => [pending]);
        when(() => localDao.getById(bird.id)).thenAnswer((_) async => bird);
        when(
          () => syncDao.deleteByRecord(any(), any()),
        ).thenAnswer((_) async {});

        await repo.save(bird);
        final createdMeta =
            verify(() => syncDao.insertItem(captureAny())).captured.first
                as SyncMetadata;
        expect(createdMeta.status, SyncStatus.pending);

        clearInteractions(remote);
        when(() => remote.upsert(any())).thenAnswer((_) async {});
        await repo.pushAll(userId);

        verify(() => remote.upsert(bird)).called(1);
        verify(
          () => syncDao.deleteByRecord(SupabaseConstants.birdsTable, bird.id),
        ).called(1);
      },
    );

    test('pull performs last-write-wins merge and orphan cleanup', () async {
      final localDao = MockBirdsDao();
      final remote = MockBirdRemoteSource();
      final syncDao = MockSyncMetadataDao();
      final repo = BirdRepository(
        localDao: localDao,
        remoteSource: remote,
        syncDao: syncDao,
      );
      final remoteBird = _bird(
        id: 'shared',
        name: 'Remote Newer',
        updatedAt: DateTime(2024, 2, 1),
      );

      when(() => remote.fetchAll(userId)).thenAnswer((_) async => [remoteBird]);
      when(() => localDao.insertAll(any())).thenAnswer((_) async {});
      when(() => localDao.getAll(userId)).thenAnswer(
        (_) async => [
          _bird(
            id: 'shared',
            name: 'Local Older',
            updatedAt: DateTime(2024, 1, 1),
          ),
          _bird(id: 'local-only'),
        ],
      );
      when(
        () => syncDao.getPendingRecordIds(userId),
      ).thenAnswer((_) async => {});
      when(() => localDao.hardDelete(any())).thenAnswer((_) async {});

      await repo.pull(userId);

      final inserted =
          verify(() => localDao.insertAll(captureAny())).captured.single
              as List<Bird>;
      expect(inserted.single.name, 'Remote Newer');
      verify(() => localDao.hardDelete('local-only')).called(1);
    });

    test(
      'sync orchestrator keeps FK order birds -> breeding_pairs -> eggs',
      () async {
        final birdRepo = MockBirdRepository();
        final eggRepo = MockEggRepository();
        final chickRepo = MockChickRepository();
        final pairRepo = MockBreedingPairRepository();
        final incubationRepo = MockIncubationRepository();
        final healthRepo = MockHealthRecordRepository();
        final growthRepo = MockGrowthMeasurementRepository();
        final eventRepo = MockEventRepository();
        final notificationRepo = MockNotificationRepository();
        final clutchRepo = MockClutchRepository();
        final nestRepo = MockNestRepository();
        final profileRepo = MockProfileRepository();
        final photoRepo = MockPhotoRepository();
        final eventReminderRepo = MockEventReminderRepository();
        final notificationScheduleRepo = MockNotificationScheduleRepository();
        final syncMetadataRepo = MockSyncMetadataRepository();
        // syncMetadataDaoProvider must also be mocked — SyncOrchestrator reads it
        // directly to call getPendingTableNames(); without this override it falls
        // through to the real AppDatabase which requires WidgetsFlutterBinding.
        final syncMetadataDaoMock = MockSyncMetadataDao();
        final calls = <String>[];

        when(() => profileRepo.pushPending(any())).thenAnswer((_) async {});
        when(() => birdRepo.pushAll(any())).thenAnswer((_) async {
          calls.add('birds');
          return emptyPushStats;
        });
        when(
          () => nestRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(() => pairRepo.pushAll(any())).thenAnswer((_) async {
          calls.add('breeding_pairs');
          return emptyPushStats;
        });
        when(
          () => clutchRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(
          () => incubationRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(() => eggRepo.pushAll(any())).thenAnswer((_) async {
          calls.add('eggs');
          return emptyPushStats;
        });
        when(
          () => chickRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(
          () => healthRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(
          () => growthRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(
          () => eventRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(
          () => notificationRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(
          () => notificationScheduleRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(
          () => photoRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(
          () => eventReminderRepo.pushAll(any()),
        ).thenAnswer((_) async => emptyPushStats);
        when(
          () => syncMetadataRepo.getErrors(any()),
        ).thenAnswer((_) async => []);
        // Report that birds, breeding_pairs and eggs have pending records so all
        // three layers are exercised by the orchestrator.
        when(
          () => syncMetadataDaoMock.getPendingTableNames(userId),
        ).thenAnswer((_) async => {'birds', 'breeding_pairs', 'eggs'});

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue(userId),
            syncMetadataDaoProvider.overrideWithValue(syncMetadataDaoMock),
            birdRepositoryProvider.overrideWithValue(birdRepo),
            eggRepositoryProvider.overrideWithValue(eggRepo),
            chickRepositoryProvider.overrideWithValue(chickRepo),
            breedingPairRepositoryProvider.overrideWithValue(pairRepo),
            incubationRepositoryProvider.overrideWithValue(incubationRepo),
            healthRecordRepositoryProvider.overrideWithValue(healthRepo),
            growthMeasurementRepositoryProvider.overrideWithValue(growthRepo),
            eventRepositoryProvider.overrideWithValue(eventRepo),
            notificationRepositoryProvider.overrideWithValue(notificationRepo),
            clutchRepositoryProvider.overrideWithValue(clutchRepo),
            nestRepositoryProvider.overrideWithValue(nestRepo),
            profileRepositoryProvider.overrideWithValue(profileRepo),
            photoRepositoryProvider.overrideWithValue(photoRepo),
            eventReminderRepositoryProvider.overrideWithValue(
              eventReminderRepo,
            ),
            notificationScheduleRepositoryProvider.overrideWithValue(
              notificationScheduleRepo,
            ),
            syncMetadataRepositoryProvider.overrideWithValue(syncMetadataRepo),
          ],
        );
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        await orchestrator.pushChanges(userId);

        expect(
          calls.indexOf('birds'),
          lessThan(calls.indexOf('breeding_pairs')),
        );
        expect(
          calls.indexOf('breeding_pairs'),
          lessThan(calls.indexOf('eggs')),
        );
      },
    );

    test(
      'validated sync cleans orphan metadata for missing FK records',
      () async {
        final localDao = MockEggsDao();
        final remote = MockEggRemoteSource();
        final syncDao = MockSyncMetadataDao();
        final incubationsDao = MockIncubationsDao();
        final clutchesDao = MockClutchesDao();

        final repo = EggRepository(
          localDao: localDao,
          remoteSource: remote,
          syncDao: syncDao,
          incubationsDao: incubationsDao,
          clutchesDao: clutchesDao,
        );

        when(
          () => syncDao.getErrorsByTable(userId, SupabaseConstants.eggsTable),
        ).thenAnswer((_) async => []);
        when(
          () => syncDao.getPendingByTable(userId, SupabaseConstants.eggsTable),
        ).thenAnswer(
          (_) async => [
            _meta(
              id: 'm1',
              table: SupabaseConstants.eggsTable,
              recordId: 'missing',
            ),
          ],
        );
        when(() => localDao.getById('missing')).thenAnswer((_) async => null);
        when(
          () => syncDao.deleteByRecord(any(), any()),
        ).thenAnswer((_) async {});

        await repo.pushAll(userId);

        verify(
          () => syncDao.deleteByRecord(SupabaseConstants.eggsTable, 'missing'),
        ).called(1);
        verifyNever(() => remote.upsert(any()));
      },
    );

    test('validated sync clears stale errors above max retries', () async {
      final localDao = MockEggsDao();
      final remote = MockEggRemoteSource();
      final syncDao = MockSyncMetadataDao();
      final incubationsDao = MockIncubationsDao();
      final clutchesDao = MockClutchesDao();
      final repo = EggRepository(
        localDao: localDao,
        remoteSource: remote,
        syncDao: syncDao,
        incubationsDao: incubationsDao,
        clutchesDao: clutchesDao,
      );

      when(
        () => syncDao.getErrorsByTable(userId, SupabaseConstants.eggsTable),
      ).thenAnswer(
        (_) async => [
          _meta(
            id: 'stale-1',
            table: SupabaseConstants.eggsTable,
            recordId: 'egg-1',
            status: SyncStatus.error,
            retryCount: 10,
          ),
        ],
      );
      when(() => syncDao.hardDelete('stale-1')).thenAnswer((_) async {});
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.eggsTable),
      ).thenAnswer((_) async => []);

      await repo.pushAll(userId);

      verify(() => syncDao.hardDelete('stale-1')).called(1);
    });

    test(
      'pull reconciliation preserves local records with error sync metadata',
      () async {
        // Scenario: bird added offline → push fails (metadata becomes error)
        // → pull with full reconciliation → bird must NOT be deleted
        final localDao = MockBirdsDao();
        final remote = MockBirdRemoteSource();
        final syncDao = MockSyncMetadataDao();
        final repo = BirdRepository(
          localDao: localDao,
          remoteSource: remote,
          syncDao: syncDao,
        );

        final offlineBird = _bird(id: 'offline-bird', name: 'Offline Created');
        final serverBird = _bird(id: 'server-bird', name: 'Server Bird');

        // Server only has server-bird (offline-bird was never pushed)
        when(
          () => remote.fetchAll(userId),
        ).thenAnswer((_) async => [serverBird]);
        when(() => localDao.insertAll(any())).thenAnswer((_) async {});
        // Local has both birds
        when(
          () => localDao.getAll(userId),
        ).thenAnswer((_) async => [offlineBird, serverBird]);
        // getPendingRecordIds now returns both pending AND error records
        // offline-bird has error status metadata (push failed)
        when(
          () => syncDao.getPendingRecordIds(userId),
        ).thenAnswer((_) async => {'offline-bird'});
        when(() => localDao.hardDelete(any())).thenAnswer((_) async {});

        await repo.pull(userId);

        // offline-bird should NOT be deleted (protected by error metadata)
        verifyNever(() => localDao.hardDelete('offline-bird'));
        // server-bird is in remoteIds, so no deletion either
        verifyNever(() => localDao.hardDelete('server-bird'));
      },
    );

    test(
      'pull reconciliation deletes orphans with NO sync metadata at all',
      () async {
        // Scenario: local record has no matching server record AND no
        // sync metadata → it is a true orphan and should be deleted
        final localDao = MockBirdsDao();
        final remote = MockBirdRemoteSource();
        final syncDao = MockSyncMetadataDao();
        final repo = BirdRepository(
          localDao: localDao,
          remoteSource: remote,
          syncDao: syncDao,
        );

        final serverBird = _bird(id: 'server-bird');
        final orphanBird = _bird(id: 'orphan-bird');

        when(
          () => remote.fetchAll(userId),
        ).thenAnswer((_) async => [serverBird]);
        when(() => localDao.insertAll(any())).thenAnswer((_) async {});
        when(
          () => localDao.getAll(userId),
        ).thenAnswer((_) async => [serverBird, orphanBird]);
        // No pending or error metadata for orphan-bird
        when(
          () => syncDao.getPendingRecordIds(userId),
        ).thenAnswer((_) async => <String>{});
        when(() => localDao.hardDelete(any())).thenAnswer((_) async {});

        await repo.pull(userId);

        // orphan-bird has no server record and no metadata → should be deleted
        verify(() => localDao.hardDelete('orphan-bird')).called(1);
        verifyNever(() => localDao.hardDelete('server-bird'));
      },
    );

    test(
      'markPending upserts existing metadata instead of creating duplicate',
      () async {
        final localDao = MockBirdsDao();
        final remote = MockBirdRemoteSource();
        final syncDao = MockSyncMetadataDao();
        final repo = BirdRepository(
          localDao: localDao,
          remoteSource: remote,
          syncDao: syncDao,
        );

        final existingMeta = _meta(
          id: 'existing-meta',
          table: SupabaseConstants.birdsTable,
          recordId: 'bird-1',
          status: SyncStatus.error,
          retryCount: 3,
        );

        // Existing error metadata found for this record
        when(
          () => syncDao.getByRecord(SupabaseConstants.birdsTable, 'bird-1'),
        ).thenAnswer((_) async => existingMeta);
        when(() => syncDao.updateItem(any())).thenAnswer((_) async {});

        await repo.markPending('bird-1', userId);

        // Should update existing metadata (reset to pending) instead of insert
        final updated =
            verify(() => syncDao.updateItem(captureAny())).captured.single
                as SyncMetadata;
        expect(updated.status, SyncStatus.pending);
        expect(updated.retryCount, 0);
        expect(updated.errorMessage, isNull);
        // insertItem should NOT be called (no duplicate)
        verifyNever(() => syncDao.insertItem(any()));
      },
    );

    test('markPending creates new metadata when none exists', () async {
      final localDao = MockBirdsDao();
      final remote = MockBirdRemoteSource();
      final syncDao = MockSyncMetadataDao();
      final repo = BirdRepository(
        localDao: localDao,
        remoteSource: remote,
        syncDao: syncDao,
      );

      // No existing metadata
      when(
        () => syncDao.getByRecord(SupabaseConstants.birdsTable, 'bird-new'),
      ).thenAnswer((_) async => null);
      when(() => syncDao.insertItem(any())).thenAnswer((_) async {});

      await repo.markPending('bird-new', userId);

      // Should create new metadata
      final created =
          verify(() => syncDao.insertItem(captureAny())).captured.single
              as SyncMetadata;
      expect(created.status, SyncStatus.pending);
      expect(created.recordId, 'bird-new');
      // updateItem should NOT be called
      verifyNever(() => syncDao.updateItem(any()));
    });
  });
}
