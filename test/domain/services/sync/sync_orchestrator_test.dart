import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart'
    as sync_model;
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_processor.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import '../../../helpers/mocks.dart';

const _userId = 'user-1';

// All table names that pushChanges checks via getPendingTableNames()
const _allTables = {
  'birds',
  'nests',
  'breeding_pairs',
  'clutches',
  'incubations',
  'eggs',
  'chicks',
  'health_records',
  'growth_measurements',
  'events',
  'notifications',
  'notification_schedules',
  'photos',
  'event_reminders',
};

sync_model.SyncMetadata _errorRecord({
  required String id,
  required String table,
  required int retryCount,
  required DateTime updatedAt,
}) {
  return sync_model.SyncMetadata(
    id: id,
    table: table,
    userId: _userId,
    status: sync_model.SyncStatus.error,
    retryCount: retryCount,
    updatedAt: updatedAt,
    recordId: 'record-$id',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const Duration(hours: 1));
  });

  late MockBirdRepository mockBirdRepository;
  late MockEggRepository mockEggRepository;
  late MockChickRepository mockChickRepository;
  late MockBreedingPairRepository mockBreedingPairRepository;
  late MockIncubationRepository mockIncubationRepository;
  late MockHealthRecordRepository mockHealthRecordRepository;
  late MockGrowthMeasurementRepository mockGrowthMeasurementRepository;
  late MockEventRepository mockEventRepository;
  late MockNotificationRepository mockNotificationRepository;
  late MockClutchRepository mockClutchRepository;
  late MockNestRepository mockNestRepository;
  late MockProfileRepository mockProfileRepository;
  late MockPhotoRepository mockPhotoRepository;
  late MockEventReminderRepository mockEventReminderRepository;
  late MockNotificationScheduleRepository mockNotificationScheduleRepository;
  late MockSyncMetadataRepository mockSyncMetadataRepository;
  late MockSyncMetadataDao mockSyncMetadataDao;
  late MockNotificationProcessor mockNotificationProcessor;

  /// Stubs pushAll + pull on a syncable repository mock, and optionally
  /// stubs lastPullConflicts to return an empty list.
  ///
  /// [pushAll] — `() => mockRepo.pushAll(any())`
  /// [pull]    — `() => mockRepo.pull(any(), lastSyncedAt: ...)`
  /// [lastPullConflicts] — `() => mockRepo.lastPullConflicts` (null to skip)
  void stubPushAndPull({
    required Future<PushStats> Function() pushAll,
    required Future<void> Function() pull,
    List<({String recordId, String detail})> Function()? lastPullConflicts,
  }) {
    when(pushAll).thenAnswer((_) async => emptyPushStats);
    when(pull).thenAnswer((_) async {});
    if (lastPullConflicts != null) {
      when(lastPullConflicts).thenReturn([]);
    }
  }

  void stubRepositoryCalls() {
    // Profile (special: pushPending + pull with no lastSyncedAt)
    when(
      () => mockProfileRepository.pushPending(any()),
    ).thenAnswer((_) async {});
    when(() => mockProfileRepository.pull(any())).thenAnswer((_) async {});

    // Syncable repositories with lastPullConflicts
    stubPushAndPull(
      pushAll: () => mockBirdRepository.pushAll(any()),
      pull: () => mockBirdRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () => mockBirdRepository.lastPullConflicts,
    );
    stubPushAndPull(
      pushAll: () => mockNestRepository.pushAll(any()),
      pull: () => mockNestRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () => mockNestRepository.lastPullConflicts,
    );
    stubPushAndPull(
      pushAll: () => mockBreedingPairRepository.pushAll(any()),
      pull: () => mockBreedingPairRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () =>
          mockBreedingPairRepository.lastPullConflicts,
    );
    stubPushAndPull(
      pushAll: () => mockClutchRepository.pushAll(any()),
      pull: () => mockClutchRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () => mockClutchRepository.lastPullConflicts,
    );
    stubPushAndPull(
      pushAll: () => mockEggRepository.pushAll(any()),
      pull: () => mockEggRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () => mockEggRepository.lastPullConflicts,
    );
    stubPushAndPull(
      pushAll: () => mockChickRepository.pushAll(any()),
      pull: () => mockChickRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () => mockChickRepository.lastPullConflicts,
    );
    stubPushAndPull(
      pushAll: () => mockHealthRecordRepository.pushAll(any()),
      pull: () => mockHealthRecordRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () =>
          mockHealthRecordRepository.lastPullConflicts,
    );
    stubPushAndPull(
      pushAll: () => mockEventRepository.pushAll(any()),
      pull: () => mockEventRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () => mockEventRepository.lastPullConflicts,
    );
    stubPushAndPull(
      pushAll: () => mockNotificationScheduleRepository.pushAll(any()),
      pull: () => mockNotificationScheduleRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () =>
          mockNotificationScheduleRepository.lastPullConflicts,
    );
    stubPushAndPull(
      pushAll: () => mockEventReminderRepository.pushAll(any()),
      pull: () => mockEventReminderRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
      lastPullConflicts: () =>
          mockEventReminderRepository.lastPullConflicts,
    );

    // Syncable repositories without lastPullConflicts
    stubPushAndPull(
      pushAll: () => mockIncubationRepository.pushAll(any()),
      pull: () => mockIncubationRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    );
    stubPushAndPull(
      pushAll: () => mockGrowthMeasurementRepository.pushAll(any()),
      pull: () => mockGrowthMeasurementRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    );
    stubPushAndPull(
      pushAll: () => mockNotificationRepository.pushAll(any()),
      pull: () => mockNotificationRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    );
    stubPushAndPull(
      pushAll: () => mockPhotoRepository.pushAll(any()),
      pull: () => mockPhotoRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    );

    // Sync metadata
    when(
      () => mockSyncMetadataRepository.getErrors(any()),
    ).thenAnswer((_) async => []);

    // DAO stubs
    when(
      () => mockSyncMetadataDao.getPendingTableNames(any()),
    ).thenAnswer((_) async => _allTables);
    when(
      () => mockSyncMetadataDao.deleteStaleErrors(any(), any(), any()),
    ).thenAnswer((_) async => 0);
  }

  ProviderContainer createContainer({String userId = _userId}) {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
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
          mockGrowthMeasurementRepository,
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
        syncMetadataRepositoryProvider.overrideWithValue(
          mockSyncMetadataRepository,
        ),
        syncMetadataDaoProvider.overrideWithValue(mockSyncMetadataDao),
        notificationProcessorProvider.overrideWithValue(
          mockNotificationProcessor,
        ),
      ],
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockBirdRepository = MockBirdRepository();
    mockEggRepository = MockEggRepository();
    mockChickRepository = MockChickRepository();
    mockBreedingPairRepository = MockBreedingPairRepository();
    mockIncubationRepository = MockIncubationRepository();
    mockHealthRecordRepository = MockHealthRecordRepository();
    mockGrowthMeasurementRepository = MockGrowthMeasurementRepository();
    mockEventRepository = MockEventRepository();
    mockNotificationRepository = MockNotificationRepository();
    mockClutchRepository = MockClutchRepository();
    mockNestRepository = MockNestRepository();
    mockProfileRepository = MockProfileRepository();
    mockPhotoRepository = MockPhotoRepository();
    mockEventReminderRepository = MockEventReminderRepository();
    mockNotificationScheduleRepository = MockNotificationScheduleRepository();
    mockSyncMetadataRepository = MockSyncMetadataRepository();
    mockSyncMetadataDao = MockSyncMetadataDao();
    mockNotificationProcessor = MockNotificationProcessor();

    when(() => mockNotificationProcessor.processAll()).thenAnswer((_) async {});

    stubRepositoryCalls();
  });

  group('SyncOrchestrator.fullSync', () {
    test('runs push phase before pull phase', () async {
      final callLog = <String>[];
      when(() => mockBirdRepository.pushAll(_userId)).thenAnswer((_) async {
        callLog.add('push:birds');
        return emptyPushStats;
      });
      when(
        () => mockBirdRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenAnswer((_) async => callLog.add('pull:birds'));

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.fullSync();

      expect(result, SyncResult.success);
      expect(callLog.indexOf('push:birds'), greaterThanOrEqualTo(0));
      expect(callLog.indexOf('pull:birds'), greaterThanOrEqualTo(0));
      expect(
        callLog.indexOf('push:birds'),
        lessThan(callLog.indexOf('pull:birds')),
      );
    });

    test('returns error for anonymous user without repository calls', () async {
      final container = createContainer(userId: 'anonymous');
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.fullSync();

      expect(result, SyncResult.error);
      expect(orchestrator.isSyncing, isFalse);
      expect(container.read(isSyncingProvider), isFalse);
      verifyNever(() => mockProfileRepository.pushPending(any()));
      verifyNever(
        () => mockBirdRepository.pull(
          any(),
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      );
    });

    test('uses incremental pull when reconciliation is not due', () async {
      final lastSync = DateTime.now().subtract(const Duration(hours: 2));
      final lastReconciled = DateTime.now().subtract(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'pref_last_synced_at': lastSync.toIso8601String(),
        'pref_last_reconciled_at': lastReconciled.toIso8601String(),
      });

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.fullSync();

      expect(result, SyncResult.success);
      verify(() => mockProfileRepository.pushPending(_userId)).called(1);
      verify(
        () => mockBirdRepository.pull(_userId, lastSyncedAt: lastSync),
      ).called(1);

      final prefs = await SharedPreferences.getInstance();
      final persistedReconcile = prefs.getString('pref_last_reconciled_at');
      final persistedLastSync = prefs.getString('pref_last_synced_at');

      expect(persistedReconcile, lastReconciled.toIso8601String());
      expect(persistedLastSync, isNotNull);
      expect(DateTime.parse(persistedLastSync!).isAfter(lastSync), isTrue);
      expect(container.read(lastSyncTimeProvider), isNotNull);
    });

    test(
      'uses full reconciliation when due and updates reconcile timestamp',
      () async {
        final oldReconcile = DateTime.now().subtract(const Duration(days: 2));
        SharedPreferences.setMockInitialValues({
          'pref_last_synced_at': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'pref_last_reconciled_at': oldReconcile.toIso8601String(),
        });

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        final result = await orchestrator.fullSync();

        expect(result, SyncResult.success);
        verify(
          () => mockBirdRepository.pull(_userId, lastSyncedAt: null),
        ).called(1);

        final prefs = await SharedPreferences.getInstance();
        final persistedReconcile = prefs.getString('pref_last_reconciled_at');
        expect(persistedReconcile, isNotNull);
        expect(
          DateTime.parse(persistedReconcile!).isAfter(oldReconcile),
          isTrue,
        );
      },
    );

    test('returns same future when a sync is already in progress', () async {
      final blockPush = Completer<void>();
      when(
        () => mockProfileRepository.pushPending(_userId),
      ).thenAnswer((_) => blockPush.future);

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final first = orchestrator.fullSync();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = orchestrator.fullSync();

      // Both calls return the same future instance
      expect(identical(first, second), isTrue);
      expect(orchestrator.isSyncing, isTrue);

      blockPush.complete();
      expect(await first, SyncResult.success);
      expect(await second, SyncResult.success);
      expect(orchestrator.isSyncing, isFalse);
    });

    test('sets syncErrorProvider when an exception occurs', () async {
      // getPendingTableNames is called before any try-catch inside pushChanges,
      // so an exception there propagates up through fullSync's catch block.
      when(
        () => mockSyncMetadataDao.getPendingTableNames(any()),
      ).thenThrow(Exception('DB query failed'));

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.fullSync();

      expect(result, SyncResult.error);
      expect(container.read(syncErrorProvider), isTrue);
      expect(container.read(isSyncingProvider), isFalse);
      expect(orchestrator.isSyncing, isFalse);
    });

    test(
      'returns error and does not advance checkpoint when pull is partial',
      () async {
        final previousSync = DateTime(2026, 1, 1, 10, 0, 0);
        SharedPreferences.setMockInitialValues({
          'pref_last_synced_at': previousSync.toIso8601String(),
          'pref_last_reconciled_at': DateTime(
            2026,
            1,
            1,
            9,
            0,
            0,
          ).toIso8601String(),
        });
        when(
          () => mockBirdRepository.pull(
            _userId,
            lastSyncedAt: any(named: 'lastSyncedAt'),
          ),
        ).thenThrow(Exception('partial pull failure'));

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        final result = await orchestrator.fullSync();

        expect(result, SyncResult.error);
        expect(container.read(syncErrorProvider), isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('pref_last_synced_at'),
          previousSync.toIso8601String(),
        );
      },
    );
  });

  group('SyncOrchestrator.forceFullSync', () {
    test('always pulls with null since and persists both timestamps', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.forceFullSync();

      expect(result, SyncResult.success);
      verify(
        () => mockBirdRepository.pull(_userId, lastSyncedAt: null),
      ).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_last_synced_at'), isNotNull);
      expect(prefs.getString('pref_last_reconciled_at'), isNotNull);
    });

    test(
      'returns error and does not advance checkpoint when pull is partial',
      () async {
        final previousSync = DateTime(2026, 1, 1, 10, 0, 0);
        SharedPreferences.setMockInitialValues({
          'pref_last_synced_at': previousSync.toIso8601String(),
          'pref_last_reconciled_at': DateTime(
            2026,
            1,
            1,
            9,
            0,
            0,
          ).toIso8601String(),
        });
        when(
          () => mockBirdRepository.pull(
            _userId,
            lastSyncedAt: any(named: 'lastSyncedAt'),
          ),
        ).thenThrow(Exception('partial pull failure'));

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        final result = await orchestrator.forceFullSync();

        expect(result, SyncResult.error);
        expect(container.read(syncErrorProvider), isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('pref_last_synced_at'),
          previousSync.toIso8601String(),
        );
      },
    );
  });

  group('SyncOrchestrator.pushChanges', () {
    test('respects FK dependency push order across layers', () async {
      final callLog = <String>[];

      when(
        () => mockProfileRepository.pushPending(_userId),
      ).thenAnswer((_) async => callLog.add('profile'));
      when(() => mockBirdRepository.pushAll(_userId)).thenAnswer((_) async {
        callLog.add('birds');
        return emptyPushStats;
      });
      when(() => mockNestRepository.pushAll(_userId)).thenAnswer((_) async {
        callLog.add('nests');
        return emptyPushStats;
      });
      when(() => mockBreedingPairRepository.pushAll(_userId)).thenAnswer((
        _,
      ) async {
        callLog.add('breeding_pairs');
        return emptyPushStats;
      });
      when(() => mockClutchRepository.pushAll(_userId)).thenAnswer((_) async {
        callLog.add('clutches');
        return emptyPushStats;
      });
      when(() => mockIncubationRepository.pushAll(_userId)).thenAnswer((
        _,
      ) async {
        callLog.add('incubations');
        return emptyPushStats;
      });
      when(() => mockEggRepository.pushAll(_userId)).thenAnswer((_) async {
        callLog.add('eggs');
        return emptyPushStats;
      });
      when(() => mockChickRepository.pushAll(_userId)).thenAnswer((_) async {
        callLog.add('chicks');
        return emptyPushStats;
      });
      when(() => mockHealthRecordRepository.pushAll(_userId)).thenAnswer((
        _,
      ) async {
        callLog.add('health_records');
        return emptyPushStats;
      });
      when(() => mockGrowthMeasurementRepository.pushAll(_userId)).thenAnswer((
        _,
      ) async {
        callLog.add('growth_measurements');
        return emptyPushStats;
      });
      when(() => mockEventRepository.pushAll(_userId)).thenAnswer((_) async {
        callLog.add('events');
        return emptyPushStats;
      });
      when(() => mockNotificationRepository.pushAll(_userId)).thenAnswer((
        _,
      ) async {
        callLog.add('notifications');
        return emptyPushStats;
      });
      when(
        () => mockNotificationScheduleRepository.pushAll(_userId),
      ).thenAnswer((_) async {
        callLog.add('notification_schedules');
        return emptyPushStats;
      });
      when(() => mockPhotoRepository.pushAll(_userId)).thenAnswer((_) async {
        callLog.add('photos');
        return emptyPushStats;
      });
      when(() => mockEventReminderRepository.pushAll(_userId)).thenAnswer((
        _,
      ) async {
        callLog.add('event_reminders');
        return emptyPushStats;
      });

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      await orchestrator.pushChanges(_userId);

      final index = <String, int>{};
      for (var i = 0; i < callLog.length; i++) {
        index.putIfAbsent(callLog[i], () => i);
      }

      expect(index['profile']!, lessThan(index['birds']!));
      expect(index['profile']!, lessThan(index['nests']!));
      expect(index['birds']!, lessThan(index['breeding_pairs']!));
      expect(index['nests']!, lessThan(index['breeding_pairs']!));
      expect(index['breeding_pairs']!, lessThan(index['clutches']!));
      expect(index['breeding_pairs']!, lessThan(index['incubations']!));
      expect(index['clutches']!, lessThan(index['eggs']!));
      expect(index['incubations']!, lessThan(index['eggs']!));
      expect(index['eggs']!, lessThan(index['chicks']!));
      expect(index['chicks']!, lessThan(index['event_reminders']!));

      verify(() => mockBirdRepository.pushAll(_userId)).called(1);
      verify(() => mockBreedingPairRepository.pushAll(_userId)).called(1);
      verify(() => mockEggRepository.pushAll(_userId)).called(1);
      verify(() => mockChickRepository.pushAll(_userId)).called(1);
    });
  });

  group('SyncOrchestrator.pullChanges', () {
    test('passes since value for incremental pull', () async {
      final since = DateTime(2026, 1, 15);
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      await orchestrator.pullChanges(_userId, since: since);

      verify(
        () => mockBirdRepository.pull(_userId, lastSyncedAt: since),
      ).called(1);
      verify(
        () => mockBreedingPairRepository.pull(_userId, lastSyncedAt: since),
      ).called(1);
      verify(
        () => mockEggRepository.pull(_userId, lastSyncedAt: since),
      ).called(1);
      verify(
        () => mockChickRepository.pull(_userId, lastSyncedAt: since),
      ).called(1);
    });

    test('uses null since for full pull', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      await orchestrator.pullChanges(_userId, since: null);

      verify(
        () => mockBirdRepository.pull(_userId, lastSyncedAt: null),
      ).called(1);
      verify(
        () => mockBreedingPairRepository.pull(_userId, lastSyncedAt: null),
      ).called(1);
      verify(
        () => mockEggRepository.pull(_userId, lastSyncedAt: null),
      ).called(1);
      verify(
        () => mockChickRepository.pull(_userId, lastSyncedAt: null),
      ).called(1);
    });

    test('respects FK dependency pull order across layers', () async {
      final callLog = <String>[];

      when(
        () => mockProfileRepository.pull(_userId),
      ).thenAnswer((_) async => callLog.add('profile'));
      when(
        () => mockBirdRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenAnswer((_) async => callLog.add('birds'));
      when(
        () => mockNestRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenAnswer((_) async => callLog.add('nests'));
      when(
        () => mockBreedingPairRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenAnswer((_) async => callLog.add('breeding_pairs'));
      when(
        () => mockClutchRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenAnswer((_) async => callLog.add('clutches'));
      when(
        () => mockIncubationRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenAnswer((_) async => callLog.add('incubations'));
      when(
        () => mockEggRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenAnswer((_) async => callLog.add('eggs'));
      when(
        () => mockChickRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenAnswer((_) async => callLog.add('chicks'));
      when(
        () => mockEventReminderRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenAnswer((_) async => callLog.add('event_reminders'));

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      await orchestrator.pullChanges(_userId, since: DateTime(2026, 1, 1));

      final index = <String, int>{};
      for (var i = 0; i < callLog.length; i++) {
        index.putIfAbsent(callLog[i], () => i);
      }

      expect(index['profile']!, lessThan(index['birds']!));
      expect(index['profile']!, lessThan(index['nests']!));
      expect(index['birds']!, lessThan(index['breeding_pairs']!));
      expect(index['nests']!, lessThan(index['breeding_pairs']!));
      expect(index['breeding_pairs']!, lessThan(index['clutches']!));
      expect(index['breeding_pairs']!, lessThan(index['incubations']!));
      expect(index['clutches']!, lessThan(index['eggs']!));
      expect(index['incubations']!, lessThan(index['eggs']!));
      expect(index['eggs']!, lessThan(index['chicks']!));
      expect(index['chicks']!, lessThan(index['event_reminders']!));
    });
  });

  group('SyncOrchestrator.retryFailedRecords', () {
    test('retries only ready records and deduplicates by table', () async {
      when(() => mockSyncMetadataRepository.getErrors(_userId)).thenAnswer(
        (_) async => [
          _errorRecord(
            id: '1',
            table: 'birds',
            retryCount: 1,
            updatedAt: DateTime(2000),
          ),
          _errorRecord(
            id: '2',
            table: 'birds',
            retryCount: 2,
            updatedAt: DateTime(2000),
          ),
          _errorRecord(
            id: '3',
            table: 'profiles',
            retryCount: 0,
            updatedAt: DateTime(2000),
          ),
          _errorRecord(
            id: '4',
            table: 'eggs',
            retryCount: 1,
            updatedAt: DateTime.now().add(const Duration(hours: 1)),
          ),
          _errorRecord(
            id: '5',
            table: 'unknown_table',
            retryCount: 1,
            updatedAt: DateTime(2000),
          ),
          _errorRecord(
            id: '6',
            table: 'chicks',
            retryCount: 10,
            updatedAt: DateTime(2000),
          ),
        ],
      );

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      await orchestrator.retryFailedRecords(_userId);

      verify(() => mockBirdRepository.pushAll(_userId)).called(1);
      verify(() => mockProfileRepository.pushPending(_userId)).called(1);
      verifyNever(() => mockEggRepository.pushAll(_userId));
      verifyNever(() => mockChickRepository.pushAll(_userId));
    });

    test('returns early when there are no retryable errors', () async {
      when(
        () => mockSyncMetadataRepository.getErrors(_userId),
      ).thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      await orchestrator.retryFailedRecords(_userId);

      verifyNever(() => mockBirdRepository.pushAll(_userId));
      verifyNever(() => mockProfileRepository.pushPending(_userId));
    });

    test('triggers pushAll for each eligible retry table', () async {
      when(() => mockSyncMetadataRepository.getErrors(_userId)).thenAnswer(
        (_) async => [
          _errorRecord(
            id: '1',
            table: 'eggs',
            retryCount: 0,
            updatedAt: DateTime(2000),
          ),
          _errorRecord(
            id: '2',
            table: 'chicks',
            retryCount: 1,
            updatedAt: DateTime(2000),
          ),
          _errorRecord(
            id: '3',
            table: 'breeding_pairs',
            retryCount: 0,
            updatedAt: DateTime(2000),
          ),
        ],
      );

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      await orchestrator.retryFailedRecords(_userId);

      verify(() => mockEggRepository.pushAll(_userId)).called(1);
      verify(() => mockChickRepository.pushAll(_userId)).called(1);
      verify(() => mockBreedingPairRepository.pushAll(_userId)).called(1);
    });
  });

  group('SyncTimeHelpers — notification processing', () {
    test('fullSync calls processNotifications on success', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.fullSync();

      expect(result, SyncResult.success);
      verify(() => mockNotificationProcessor.processAll()).called(1);
    });

    test('fullSync calls processNotifications even when pull fails', () async {
      when(
        () => mockBirdRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenThrow(Exception('pull failure'));

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.fullSync();

      expect(result, SyncResult.error);
      verify(() => mockNotificationProcessor.processAll()).called(1);
    });

    test('forceFullSync calls processNotifications', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.forceFullSync();

      expect(result, SyncResult.success);
      verify(() => mockNotificationProcessor.processAll()).called(1);
    });
  });

  group('SyncTimeHelpers — timestamp persistence', () {
    test('fullSync persists sync time after successful sync', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final beforeSync = DateTime.now();
      final result = await orchestrator.fullSync();

      expect(result, SyncResult.success);

      final prefs = await SharedPreferences.getInstance();
      final persistedValue = prefs.getString('pref_last_synced_at');
      expect(persistedValue, isNotNull);
      final persistedTime = DateTime.parse(persistedValue!);
      expect(persistedTime.isAfter(beforeSync) || persistedTime.isAtSameMomentAs(beforeSync), isTrue);
      expect(container.read(lastSyncTimeProvider), isNotNull);
    });

    test('fullSync does not persist sync time when pull fails', () async {
      when(
        () => mockBirdRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenThrow(Exception('pull failure'));

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.fullSync();

      expect(result, SyncResult.error);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_last_synced_at'), isNull);
    });

    test('forceFullSync persists both sync and reconcile timestamps', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final beforeSync = DateTime.now();
      final result = await orchestrator.forceFullSync();

      expect(result, SyncResult.success);

      final prefs = await SharedPreferences.getInstance();
      final syncTime = prefs.getString('pref_last_synced_at');
      final reconcileTime = prefs.getString('pref_last_reconciled_at');
      expect(syncTime, isNotNull);
      expect(reconcileTime, isNotNull);
      expect(DateTime.parse(syncTime!).isAfter(beforeSync) || DateTime.parse(syncTime).isAtSameMomentAs(beforeSync), isTrue);
      expect(DateTime.parse(reconcileTime!).isAfter(beforeSync) || DateTime.parse(reconcileTime).isAtSameMomentAs(beforeSync), isTrue);
    });
  });

  group('SyncTimeHelpers — reconciliation timing', () {
    test(
      'fullSync triggers reconciliation when last reconcile is older than 6 hours',
      () async {
        final oldReconcile = DateTime.now().subtract(const Duration(hours: 7));
        final lastSync = DateTime.now().subtract(const Duration(hours: 1));
        SharedPreferences.setMockInitialValues({
          'pref_last_synced_at': lastSync.toIso8601String(),
          'pref_last_reconciled_at': oldReconcile.toIso8601String(),
        });

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        final result = await orchestrator.fullSync();

        expect(result, SyncResult.success);
        // Full reconciliation pulls with null since (no incremental)
        verify(
          () => mockBirdRepository.pull(_userId, lastSyncedAt: null),
        ).called(1);

        // Reconcile time should be updated
        final prefs = await SharedPreferences.getInstance();
        final newReconcile = prefs.getString('pref_last_reconciled_at');
        expect(newReconcile, isNotNull);
        expect(DateTime.parse(newReconcile!).isAfter(oldReconcile), isTrue);
      },
    );

    test(
      'fullSync skips reconciliation when last reconcile is within 6 hours',
      () async {
        final recentReconcile =
            DateTime.now().subtract(const Duration(hours: 3));
        final lastSync = DateTime.now().subtract(const Duration(hours: 1));
        SharedPreferences.setMockInitialValues({
          'pref_last_synced_at': lastSync.toIso8601String(),
          'pref_last_reconciled_at': recentReconcile.toIso8601String(),
        });

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        final result = await orchestrator.fullSync();

        expect(result, SyncResult.success);
        // Incremental pull uses lastSync timestamp
        verify(
          () => mockBirdRepository.pull(_userId, lastSyncedAt: lastSync),
        ).called(1);

        // Reconcile time should NOT be updated
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('pref_last_reconciled_at'),
          recentReconcile.toIso8601String(),
        );
      },
    );

    test(
      'fullSync triggers reconciliation on first sync (no stored timestamps)',
      () async {
        SharedPreferences.setMockInitialValues({});

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        final result = await orchestrator.fullSync();

        expect(result, SyncResult.success);
        // First sync: no lastSync → full pull with null
        verify(
          () => mockBirdRepository.pull(_userId, lastSyncedAt: null),
        ).called(1);

        // Both timestamps should now be persisted
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('pref_last_synced_at'), isNotNull);
        expect(prefs.getString('pref_last_reconciled_at'), isNotNull);
      },
    );
  });

  group('SyncTimeHelpers — forceFullSync throttling', () {
    test('second forceFullSync within cooldown returns throttled', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final first = await orchestrator.forceFullSync();
      expect(first, SyncResult.success);

      final second = await orchestrator.forceFullSync();
      expect(second, SyncResult.throttled);
    });
  });

  group('SyncTimeHelpers — encryption migration', () {
    late MockBirdsDao mockBirdsDao;
    late MockConflictHistoryDao mockConflictHistoryDao;
    late MockEncryptionService mockEncryptionService;

    setUp(() {
      mockBirdsDao = MockBirdsDao();
      mockConflictHistoryDao = MockConflictHistoryDao();
      mockEncryptionService = MockEncryptionService();

      when(() => mockBirdsDao.getWithRingNumber(any()))
          .thenAnswer((_) async => []);
      when(() => mockConflictHistoryDao.deleteOlderThan(any()))
          .thenAnswer((_) async => 0);
    });

    ProviderContainer createContainerWithEncryption({
      String userId = _userId,
    }) {
      final base = createContainer(userId: userId);
      // Layer encryption-specific overrides on top of the base container.
      // We dispose the base and create a new one with all overrides merged.
      base.dispose();
      return ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue(userId),
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
            mockGrowthMeasurementRepository,
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
          syncMetadataRepositoryProvider.overrideWithValue(
            mockSyncMetadataRepository,
          ),
          syncMetadataDaoProvider.overrideWithValue(mockSyncMetadataDao),
          notificationProcessorProvider.overrideWithValue(
            mockNotificationProcessor,
          ),
          // Encryption-specific overrides
          birdsDaoProvider.overrideWithValue(mockBirdsDao),
          conflictHistoryDaoProvider.overrideWithValue(
            mockConflictHistoryDao,
          ),
          encryptionServiceProvider.overrideWithValue(mockEncryptionService),
        ],
      );
    }

    test(
      'fullSync runs encryption migration on first sync (no previous sync time)',
      () async {
        SharedPreferences.setMockInitialValues({});

        final container = createContainerWithEncryption();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        final result = await orchestrator.fullSync();

        expect(result, SyncResult.success);
        // Migration should query birds with ring numbers
        verify(() => mockBirdsDao.getWithRingNumber(_userId)).called(1);
      },
    );

    test(
      'fullSync skips encryption migration during incremental sync',
      () async {
        final recentReconcile =
            DateTime.now().subtract(const Duration(hours: 2));
        final lastSync = DateTime.now().subtract(const Duration(hours: 1));
        SharedPreferences.setMockInitialValues({
          'pref_last_synced_at': lastSync.toIso8601String(),
          'pref_last_reconciled_at': recentReconcile.toIso8601String(),
        });

        final container = createContainerWithEncryption();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        final result = await orchestrator.fullSync();

        expect(result, SyncResult.success);
        // No migration during incremental sync
        verifyNever(() => mockBirdsDao.getWithRingNumber(any()));
      },
    );

    test(
      'forceFullSync always runs encryption migration',
      () async {
        SharedPreferences.setMockInitialValues({});

        final container = createContainerWithEncryption();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        final result = await orchestrator.forceFullSync();

        expect(result, SyncResult.success);
        verify(() => mockBirdsDao.getWithRingNumber(_userId)).called(1);
      },
    );
  });
}
