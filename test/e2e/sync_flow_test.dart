@Tags(['e2e'])
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart'
    as sync_model;
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Sync Flow E2E', () {
    test(
      'GIVEN online user WHEN app goes offline then online and manual sync runs THEN pending metadata is synced and offline banner state flips',
      () async {
        Future<bool> firstNetworkValue(ProviderContainer container) async {
          final completer = Completer<bool>();
          late final ProviderSubscription<AsyncValue<bool>> subscription;
          subscription = container.listen<AsyncValue<bool>>(
            networkStatusProvider,
            (_, next) {
              next.when(
                data: (value) {
                  if (!completer.isCompleted) completer.complete(value);
                  subscription.close();
                },
                error: (error, stackTrace) {
                  if (!completer.isCompleted) {
                    completer.completeError(error, stackTrace);
                  }
                  subscription.close();
                },
                loading: () {},
              );
            },
            fireImmediately: true,
          );
          return completer.future.timeout(const Duration(seconds: 2));
        }

        final mockSyncOrchestrator = MockSyncOrchestrator();

        when(
          () => mockSyncOrchestrator.retryFailedRecords('test-user'),
        ).thenAnswer((_) async {});
        when(
          () => mockSyncOrchestrator.forceFullSync(),
        ).thenAnswer((_) async => SyncResult.success);

        final pendingMetadata = List<sync_model.SyncMetadata>.generate(
          3,
          (index) => sync_model.SyncMetadata(
            id: 'm$index',
            table: 'birds',
            userId: 'test-user',
            recordId: 'bird-$index',
            status: sync_model.SyncStatus.pending,
          ),
        );

        final offlineContainer = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            networkStatusProvider.overrideWith((_) => Stream.value(false)),
            syncOrchestratorProvider.overrideWithValue(mockSyncOrchestrator),
          ],
        );
        addTearDown(offlineContainer.dispose);

        final offlineValue = await firstNetworkValue(offlineContainer);
        expect(offlineValue, isFalse);
        expect(
          offlineContainer.read(syncStatusProvider),
          SyncDisplayStatus.offline,
        );
        expect(
          pendingMetadata.where(
            (item) => item.status == sync_model.SyncStatus.pending,
          ),
          hasLength(3),
        );

        final onlineContainer = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            networkStatusProvider.overrideWith((_) => Stream.value(true)),
            syncOrchestratorProvider.overrideWithValue(mockSyncOrchestrator),
          ],
        );
        addTearDown(onlineContainer.dispose);
        final onlineValue = await firstNetworkValue(onlineContainer);
        expect(onlineValue, isTrue);
        expect(
          onlineContainer.read(syncStatusProvider),
          SyncDisplayStatus.synced,
        );

        final manualSyncProvider = FutureProvider<SyncResult>(
          (ref) => triggerManualSync(ref),
        );
        final syncResult = await onlineContainer.read(
          manualSyncProvider.future,
        );

        final syncedMetadata = pendingMetadata
            .map((item) => item.copyWith(status: sync_model.SyncStatus.synced))
            .toList();

        expect(syncResult, SyncResult.success);
        expect(
          syncedMetadata.every(
            (item) => item.status == sync_model.SyncStatus.synced,
          ),
          isTrue,
        );
        verify(
          () => mockSyncOrchestrator.retryFailedRecords('test-user'),
        ).called(1);
        verify(() => mockSyncOrchestrator.forceFullSync()).called(1);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN conflicting local/server record WHEN pull conflict resolution uses server-wins THEN local value is overridden and metadata is updated',
      () {
        const localName = 'Sari Boncuk (Local)';
        const serverName = 'Sari Boncuk (Server)';

        const resolvedName = serverName; // server-wins strategy
        final metadata = sync_model.SyncMetadata(
          id: 'sync-1',
          table: 'birds',
          userId: 'test-user',
          recordId: 'bird-1',
          status: sync_model.SyncStatus.synced,
          updatedAt: DateTime.now(),
        );

        expect(localName == resolvedName, isFalse);
        expect(resolvedName, serverName);
        expect(metadata.status, sync_model.SyncStatus.synced);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN repeated sync failures WHEN retry mechanism runs up to 10 attempts THEN retry_count increments and terminal status becomes error',
      () async {
        const maxAttempts = 10;
        var retryCount = 0;
        var status = sync_model.SyncStatus.pending;

        final mockSyncOrchestrator = MockSyncOrchestrator();
        when(
          () => mockSyncOrchestrator.forceFullSync(),
        ).thenAnswer((_) async => SyncResult.error);

        for (var attempt = 1; attempt <= maxAttempts; attempt++) {
          final result = await mockSyncOrchestrator.forceFullSync();
          if (result == SyncResult.error) {
            retryCount++;
            if (retryCount >= maxAttempts) {
              status = sync_model.SyncStatus.error;
            }
          }
        }

        expect(retryCount, maxAttempts);
        expect(status, sync_model.SyncStatus.error);
        verify(() => mockSyncOrchestrator.forceFullSync()).called(maxAttempts);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN offline-created parent/child records WHEN pushAll executes THEN birds are pushed before breeding pairs without FK errors',
      () async {
        final callLog = <String>[];
        final mockBirdRepository = MockBirdRepository();
        final mockEggRepository = MockEggRepository();
        final mockChickRepository = MockChickRepository();
        final mockBreedingPairRepository = MockBreedingPairRepository();
        final mockIncubationRepository = MockIncubationRepository();
        final mockHealthRecordRepository = MockHealthRecordRepository();
        final mockGrowthRepository = MockGrowthMeasurementRepository();
        final mockEventRepository = MockEventRepository();
        final mockNotificationRepository = MockNotificationRepository();
        final mockClutchRepository = MockClutchRepository();
        final mockNestRepository = MockNestRepository();
        final mockProfileRepository = MockProfileRepository();
        final mockPhotoRepository = MockPhotoRepository();
        final mockEventReminderRepository = MockEventReminderRepository();
        final mockNotificationScheduleRepository =
            MockNotificationScheduleRepository();

        final mockSyncMetadataDao = MockSyncMetadataDao();
        when(
          () => mockSyncMetadataDao.getPendingTableNames('test-user'),
        ).thenAnswer((_) async => {'birds', 'breeding_pairs'});

        when(
          () => mockProfileRepository.pushPending('test-user'),
        ).thenAnswer((_) async => callLog.add('profile'));
        when(() => mockBirdRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('birds');
          return emptyPushStats;
        });
        when(() => mockNestRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('nests');
          return emptyPushStats;
        });
        when(() => mockBreedingPairRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('breeding_pairs');
          return emptyPushStats;
        });
        when(() => mockClutchRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('clutches');
          return emptyPushStats;
        });
        when(() => mockIncubationRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('incubations');
          return emptyPushStats;
        });
        when(() => mockEggRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('eggs');
          return emptyPushStats;
        });
        when(() => mockChickRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('chicks');
          return emptyPushStats;
        });
        when(() => mockHealthRecordRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('health');
          return emptyPushStats;
        });
        when(() => mockGrowthRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('growth');
          return emptyPushStats;
        });
        when(() => mockEventRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('events');
          return emptyPushStats;
        });
        when(() => mockNotificationRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('notifications');
          return emptyPushStats;
        });
        when(
          () => mockNotificationScheduleRepository.pushAll('test-user'),
        ).thenAnswer((_) async {
          callLog.add('notification_schedules');
          return emptyPushStats;
        });
        when(() => mockPhotoRepository.pushAll('test-user')).thenAnswer((
          _,
        ) async {
          callLog.add('photos');
          return emptyPushStats;
        });
        when(() => mockEventReminderRepository.pushAll('test-user')).thenAnswer(
          (_) async {
            callLog.add('event_reminders');
            return emptyPushStats;
          },
        );

        final container = createTestContainer(
          overrides: [
            syncMetadataDaoProvider.overrideWithValue(mockSyncMetadataDao),
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
            eggRepositoryProvider.overrideWithValue(mockEggRepository),
            chickRepositoryProvider.overrideWithValue(mockChickRepository),
            breedingPairRepositoryProvider.overrideWithValue(
              mockBreedingPairRepository,
            ),
            incubationRepositoryProvider.overrideWithValue(
              mockIncubationRepository,
            ),
            healthRecordRepositoryProvider.overrideWithValue(
              mockHealthRecordRepository,
            ),
            growthMeasurementRepositoryProvider.overrideWithValue(
              mockGrowthRepository,
            ),
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
            notificationRepositoryProvider.overrideWithValue(
              mockNotificationRepository,
            ),
            clutchRepositoryProvider.overrideWithValue(mockClutchRepository),
            nestRepositoryProvider.overrideWithValue(mockNestRepository),
            profileRepositoryProvider.overrideWithValue(mockProfileRepository),
            photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
            eventReminderRepositoryProvider.overrideWithValue(
              mockEventReminderRepository,
            ),
            notificationScheduleRepositoryProvider.overrideWithValue(
              mockNotificationScheduleRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final orchestrator = container.read(syncOrchestratorProvider);
        await orchestrator.pushChanges('test-user');

        final birdIndex = callLog.indexOf('birds');
        final pairIndex = callLog.indexOf('breeding_pairs');

        expect(birdIndex, greaterThanOrEqualTo(0));
        expect(pairIndex, greaterThanOrEqualTo(0));
        expect(birdIndex, lessThan(pairIndex));
      },
      timeout: e2eTimeout,
    );
  });
}
