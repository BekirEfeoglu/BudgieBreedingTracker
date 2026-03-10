import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart'
    as sync_model;
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/clutch_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_reminder_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/growth_measurement_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/nest_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_schedule_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/photo_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/profile_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_metadata_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_processor.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

class MockBirdRepository extends Mock implements BirdRepository {}

class MockEggRepository extends Mock implements EggRepository {}

class MockChickRepository extends Mock implements ChickRepository {}

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

class MockHealthRecordRepository extends Mock
    implements HealthRecordRepository {}

class MockGrowthMeasurementRepository extends Mock
    implements GrowthMeasurementRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockClutchRepository extends Mock implements ClutchRepository {}

class MockNestRepository extends Mock implements NestRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockPhotoRepository extends Mock implements PhotoRepository {}

class MockEventReminderRepository extends Mock
    implements EventReminderRepository {}

class MockNotificationScheduleRepository extends Mock
    implements NotificationScheduleRepository {}

class MockSyncMetadataRepository extends Mock
    implements SyncMetadataRepository {}

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

class MockNotificationProcessor extends Mock implements NotificationProcessor {}

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

  void stubRepositoryCalls() {
    when(
      () => mockProfileRepository.pushPending(any()),
    ).thenAnswer((_) async {});
    when(() => mockProfileRepository.pull(any())).thenAnswer((_) async {});

    when(
      () => mockBirdRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockBirdRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockBirdRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockNestRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockNestRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockNestRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockBreedingPairRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockBreedingPairRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockBreedingPairRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockClutchRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockClutchRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockClutchRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockIncubationRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockIncubationRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockEggRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockEggRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockEggRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockChickRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockChickRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockChickRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockHealthRecordRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockHealthRecordRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockHealthRecordRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockGrowthMeasurementRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockGrowthMeasurementRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockEventRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockEventRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockEventRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockNotificationRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockNotificationRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockNotificationScheduleRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockNotificationScheduleRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationScheduleRepository.lastPullConflicts,
    ).thenReturn([]);

    when(
      () => mockPhotoRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockPhotoRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockEventReminderRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockEventReminderRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockEventReminderRepository.lastPullConflicts).thenReturn([]);

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

    test('returns alreadySyncing when a sync is in progress', () async {
      final blockPush = Completer<void>();
      when(
        () => mockProfileRepository.pushPending(_userId),
      ).thenAnswer((_) => blockPush.future);

      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final first = orchestrator.fullSync();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = await orchestrator.fullSync();

      expect(second, SyncResult.alreadySyncing);
      blockPush.complete();
      expect(await first, SyncResult.success);
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
}
