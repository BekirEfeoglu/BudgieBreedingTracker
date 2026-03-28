import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_processor.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import '../../../helpers/mocks.dart';

const _userId = 'user-1';

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
    when(
      () => mockProfileRepository.pushPending(any()),
    ).thenAnswer((_) async {});
    when(() => mockProfileRepository.pull(any())).thenAnswer((_) async {});

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

    when(
      () => mockSyncMetadataRepository.getErrors(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockSyncMetadataDao.getPendingTableNames(any()),
    ).thenAnswer((_) async => _allTables);
    when(
      () => mockSyncMetadataDao.deleteStaleErrors(any(), any(), any()),
    ).thenAnswer((_) async => 0);
  }

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(_userId),
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
    mockNotificationScheduleRepository =
        MockNotificationScheduleRepository();
    mockSyncMetadataRepository = MockSyncMetadataRepository();
    mockSyncMetadataDao = MockSyncMetadataDao();
    mockNotificationProcessor = MockNotificationProcessor();

    when(() => mockNotificationProcessor.processAll())
        .thenAnswer((_) async {});

    stubRepositoryCalls();
  });

  group('Sync time persistence', () {
    test('fullSync persists lastSyncedAt to SharedPreferences', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      final result = await orchestrator.fullSync();

      expect(result, SyncResult.success);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppPreferences.keyLastSyncedAt);
      expect(raw, isNotNull);

      final persisted = DateTime.parse(raw!);
      expect(
        persisted.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('fullSync updates lastSyncTimeProvider after success', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final orchestrator = container.read(syncOrchestratorProvider);

      expect(container.read(lastSyncTimeProvider), isNull);

      await orchestrator.fullSync();

      expect(container.read(lastSyncTimeProvider), isNotNull);
    });

    test(
      'fullSync reads persisted lastSyncedAt for incremental pull',
      () async {
        final lastSync = DateTime.now().subtract(const Duration(hours: 2));
        final recentReconcile =
            DateTime.now().subtract(const Duration(hours: 1));
        SharedPreferences.setMockInitialValues({
          AppPreferences.keyLastSyncedAt: lastSync.toIso8601String(),
          AppPreferences.keyLastReconciledAt:
              recentReconcile.toIso8601String(),
        });

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        await orchestrator.fullSync();

        verify(
          () => mockBirdRepository.pull(_userId, lastSyncedAt: lastSync),
        ).called(1);
      },
    );
  });

  group('Reconciliation due check', () {
    test(
      'reconciliation is due when lastReconciledAt is older than 6 hours',
      () async {
        final oldReconcile =
            DateTime.now().subtract(const Duration(hours: 7));
        SharedPreferences.setMockInitialValues({
          AppPreferences.keyLastSyncedAt:
              DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          AppPreferences.keyLastReconciledAt:
              oldReconcile.toIso8601String(),
        });

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        await orchestrator.fullSync();

        // Full reconciliation passes null as lastSyncedAt
        verify(
          () => mockBirdRepository.pull(_userId, lastSyncedAt: null),
        ).called(1);

        // Reconcile timestamp should be updated
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(AppPreferences.keyLastReconciledAt);
        expect(raw, isNotNull);
        expect(DateTime.parse(raw!).isAfter(oldReconcile), isTrue);
      },
    );

    test(
      'reconciliation is NOT due when lastReconciledAt is recent',
      () async {
        final lastSync = DateTime.now().subtract(const Duration(hours: 2));
        final recentReconcile =
            DateTime.now().subtract(const Duration(hours: 3));
        SharedPreferences.setMockInitialValues({
          AppPreferences.keyLastSyncedAt: lastSync.toIso8601String(),
          AppPreferences.keyLastReconciledAt:
              recentReconcile.toIso8601String(),
        });

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        await orchestrator.fullSync();

        // Incremental pull passes the persisted lastSync value
        verify(
          () => mockBirdRepository.pull(_userId, lastSyncedAt: lastSync),
        ).called(1);

        // Reconcile timestamp should NOT be updated
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(AppPreferences.keyLastReconciledAt),
          recentReconcile.toIso8601String(),
        );
      },
    );

    test(
      'reconciliation is due when keyLastReconciledAt is absent',
      () async {
        SharedPreferences.setMockInitialValues({
          AppPreferences.keyLastSyncedAt:
              DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        });

        final container = createContainer();
        addTearDown(container.dispose);
        final orchestrator = container.read(syncOrchestratorProvider);

        await orchestrator.fullSync();

        // Missing reconcile key → full reconciliation (null since)
        verify(
          () => mockBirdRepository.pull(_userId, lastSyncedAt: null),
        ).called(1);
      },
    );
  });
}
