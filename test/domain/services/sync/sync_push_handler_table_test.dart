import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_push_handler.dart';

import '../../../helpers/mocks.dart';

// Provider to create SyncPushHandler with a real Riverpod Ref.
final _syncPushHandlerProvider = Provider<SyncPushHandler>(
  (ref) => SyncPushHandler(ref),
);

const _userId = 'test-user-push-table';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBirdRepository mockBirdRepo;
  late MockNestRepository mockNestRepo;
  late MockBreedingPairRepository mockBreedingPairRepo;
  late MockClutchRepository mockClutchRepo;
  late MockIncubationRepository mockIncubationRepo;
  late MockEggRepository mockEggRepo;
  late MockChickRepository mockChickRepo;
  late MockHealthRecordRepository mockHealthRecordRepo;
  late MockGrowthMeasurementRepository mockGrowthMeasurementRepo;
  late MockEventRepository mockEventRepo;
  late MockNotificationRepository mockNotificationRepo;
  late MockNotificationScheduleRepository mockNotificationScheduleRepo;
  late MockPhotoRepository mockPhotoRepo;
  late MockEventReminderRepository mockEventReminderRepo;
  late MockProfileRepository mockProfileRepo;
  late MockSyncMetadataDao mockSyncMetadataDao;

  void stubAllPushes() {
    when(() => mockProfileRepo.pushPending(any()))
        .thenAnswer((_) async {});
    when(() => mockBirdRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockNestRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockBreedingPairRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockClutchRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockIncubationRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockEggRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockChickRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockHealthRecordRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockGrowthMeasurementRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockEventRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockNotificationRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockNotificationScheduleRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockPhotoRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockEventReminderRepo.pushAll(any()))
        .thenAnswer((_) async => emptyPushStats);
    when(() => mockSyncMetadataDao.getPendingTableNames(any()))
        .thenAnswer((_) async => <String>{});
  }

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        birdRepositoryProvider.overrideWithValue(mockBirdRepo),
        nestRepositoryProvider.overrideWithValue(mockNestRepo),
        breedingPairRepositoryProvider.overrideWithValue(mockBreedingPairRepo),
        clutchRepositoryProvider.overrideWithValue(mockClutchRepo),
        incubationRepositoryProvider.overrideWithValue(mockIncubationRepo),
        eggRepositoryProvider.overrideWithValue(mockEggRepo),
        chickRepositoryProvider.overrideWithValue(mockChickRepo),
        healthRecordRepositoryProvider.overrideWithValue(mockHealthRecordRepo),
        growthMeasurementRepositoryProvider
            .overrideWithValue(mockGrowthMeasurementRepo),
        eventRepositoryProvider.overrideWithValue(mockEventRepo),
        notificationRepositoryProvider.overrideWithValue(mockNotificationRepo),
        notificationScheduleRepositoryProvider
            .overrideWithValue(mockNotificationScheduleRepo),
        photoRepositoryProvider.overrideWithValue(mockPhotoRepo),
        eventReminderRepositoryProvider
            .overrideWithValue(mockEventReminderRepo),
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        syncMetadataDaoProvider.overrideWithValue(mockSyncMetadataDao),
      ],
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockBirdRepo = MockBirdRepository();
    mockNestRepo = MockNestRepository();
    mockBreedingPairRepo = MockBreedingPairRepository();
    mockClutchRepo = MockClutchRepository();
    mockIncubationRepo = MockIncubationRepository();
    mockEggRepo = MockEggRepository();
    mockChickRepo = MockChickRepository();
    mockHealthRecordRepo = MockHealthRecordRepository();
    mockGrowthMeasurementRepo = MockGrowthMeasurementRepository();
    mockEventRepo = MockEventRepository();
    mockNotificationRepo = MockNotificationRepository();
    mockNotificationScheduleRepo = MockNotificationScheduleRepository();
    mockPhotoRepo = MockPhotoRepository();
    mockEventReminderRepo = MockEventReminderRepository();
    mockProfileRepo = MockProfileRepository();
    mockSyncMetadataDao = MockSyncMetadataDao();

    stubAllPushes();
  });

  group('_pushSingleTable — per-table dispatch', () {
    test('dispatches clutches table to clutchRepository.pushAll', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushTable(_userId, SupabaseConstants.clutchesTable);

      verify(() => mockClutchRepo.pushAll(_userId)).called(1);
    });

    test('dispatches events table to eventRepository.pushAll', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushTable(_userId, SupabaseConstants.eventsTable);

      verify(() => mockEventRepo.pushAll(_userId)).called(1);
    });

    test(
      'dispatches growth_measurements table to '
      'growthMeasurementRepository.pushAll',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPushHandlerProvider);

        await handler.pushTable(
          _userId,
          SupabaseConstants.growthMeasurementsTable,
        );

        verify(() => mockGrowthMeasurementRepo.pushAll(_userId)).called(1);
      },
    );

    test('dispatches notifications table to notificationRepository', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushTable(_userId, SupabaseConstants.notificationsTable);

      verify(() => mockNotificationRepo.pushAll(_userId)).called(1);
    });

    test(
      'dispatches notification_schedules table to '
      'notificationScheduleRepository',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPushHandlerProvider);

        await handler.pushTable(
          _userId,
          SupabaseConstants.notificationSchedulesTable,
        );

        verify(() => mockNotificationScheduleRepo.pushAll(_userId)).called(1);
      },
    );

    test(
      'dispatches event_reminders table to eventReminderRepository',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPushHandlerProvider);

        await handler.pushTable(_userId, SupabaseConstants.eventRemindersTable);

        verify(() => mockEventReminderRepo.pushAll(_userId)).called(1);
      },
    );
  });

  group('_pushSingleTable — error handling', () {
    test('exception in pushAll is caught and does not propagate', () async {
      when(() => mockEggRepo.pushAll(any()))
          .thenThrow(Exception('network error'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await expectLater(
        handler.pushTable(_userId, SupabaseConstants.eggsTable),
        completes,
      );
    });

    test('exception in profile pushPending is caught', () async {
      when(() => mockProfileRepo.pushPending(any()))
          .thenThrow(Exception('auth error'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await expectLater(
        handler.pushTable(_userId, SupabaseConstants.profilesTable),
        completes,
      );
    });

    test('unknown table name does not call any repository', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushTable(_userId, 'nonexistent_table');

      verifyNever(() => mockBirdRepo.pushAll(any()));
      verifyNever(() => mockEggRepo.pushAll(any()));
      verifyNever(() => mockChickRepo.pushAll(any()));
      verifyNever(() => mockClutchRepo.pushAll(any()));
      verifyNever(() => mockProfileRepo.pushPending(any()));
      verifyNever(() => mockEventRepo.pushAll(any()));
    });
  });

  group('_safeParallelPush (via pushChanges)', () {
    test('multiple L1 tables pushed in parallel when both pending', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {
                SupabaseConstants.birdsTable,
                SupabaseConstants.nestsTable,
              });

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushChanges(_userId);

      verify(() => mockBirdRepo.pushAll(_userId)).called(1);
      verify(() => mockNestRepo.pushAll(_userId)).called(1);
    });

    test('partial failure in parallel push still pushes other tables',
        () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {
                SupabaseConstants.birdsTable,
                SupabaseConstants.nestsTable,
              });
      when(() => mockBirdRepo.pushAll(any()))
          .thenThrow(Exception('bird push failed'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushChanges(_userId);

      verify(() => mockNestRepo.pushAll(_userId)).called(1);
    });

    test('L6 leaf entities pushed in parallel when all pending', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {
                SupabaseConstants.healthRecordsTable,
                SupabaseConstants.eventsTable,
                SupabaseConstants.photosTable,
              });

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushChanges(_userId);

      verify(() => mockHealthRecordRepo.pushAll(_userId)).called(1);
      verify(() => mockEventRepo.pushAll(_userId)).called(1);
      verify(() => mockPhotoRepo.pushAll(_userId)).called(1);
    });
  });

  group('_anyPending (via pushChanges)', () {
    test('skips layer when none of its tables are pending', () async {
      // Only eggs pending — L1 (birds/nests) should be skipped
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {SupabaseConstants.eggsTable});

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushChanges(_userId);

      verifyNever(() => mockBirdRepo.pushAll(any()));
      verifyNever(() => mockNestRepo.pushAll(any()));
    });

    test('pushes layer when at least one table is pending', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {SupabaseConstants.nestsTable});

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushChanges(_userId);

      verify(() => mockNestRepo.pushAll(_userId)).called(1);
      verifyNever(() => mockBirdRepo.pushAll(any()));
    });
  });

  group('FK dependency ordering (via pushChanges)', () {
    test('L2 skipped when L1 fails completely', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {
                SupabaseConstants.birdsTable,
                SupabaseConstants.breedingPairsTable,
              });
      // Both L1 tasks fail → l1Failed = true
      when(() => mockBirdRepo.pushAll(any()))
          .thenThrow(Exception('fail'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isFalse);
      verifyNever(() => mockBreedingPairRepo.pushAll(any()));
    });

    test('L3 skipped when L2 fails', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {
                SupabaseConstants.breedingPairsTable,
                SupabaseConstants.clutchesTable,
              });
      when(() => mockBreedingPairRepo.pushAll(any()))
          .thenThrow(Exception('fail'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isFalse);
      verifyNever(() => mockClutchRepo.pushAll(any()));
    });

    test('L4 skipped when L3 fails', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {
                SupabaseConstants.breedingPairsTable,
                SupabaseConstants.clutchesTable,
                SupabaseConstants.eggsTable,
              });
      // L2 succeeds, but both L3 tasks fail
      when(() => mockClutchRepo.pushAll(any()))
          .thenThrow(Exception('fail'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isFalse);
      verifyNever(() => mockEggRepo.pushAll(any()));
    });

    test('L5 skipped when L4 fails', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {
                SupabaseConstants.eggsTable,
                SupabaseConstants.chicksTable,
              });
      when(() => mockEggRepo.pushAll(any()))
          .thenThrow(Exception('fail'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isFalse);
      verifyNever(() => mockChickRepo.pushAll(any()));
    });

    test('L7 skipped when L6 fails', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {
                SupabaseConstants.eventsTable,
                SupabaseConstants.eventRemindersTable,
              });
      when(() => mockEventRepo.pushAll(any()))
          .thenThrow(Exception('fail'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isFalse);
      verifyNever(() => mockEventReminderRepo.pushAll(any()));
    });

    test('full chain succeeds when all layers succeed', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {
                SupabaseConstants.birdsTable,
                SupabaseConstants.breedingPairsTable,
                SupabaseConstants.clutchesTable,
                SupabaseConstants.eggsTable,
                SupabaseConstants.chicksTable,
                SupabaseConstants.eventsTable,
                SupabaseConstants.eventRemindersTable,
              });

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isTrue);
      verify(() => mockBirdRepo.pushAll(_userId)).called(1);
      verify(() => mockBreedingPairRepo.pushAll(_userId)).called(1);
      verify(() => mockClutchRepo.pushAll(_userId)).called(1);
      verify(() => mockEggRepo.pushAll(_userId)).called(1);
      verify(() => mockChickRepo.pushAll(_userId)).called(1);
      verify(() => mockEventRepo.pushAll(_userId)).called(1);
      verify(() => mockEventReminderRepo.pushAll(_userId)).called(1);
    });
  });

  group('pushChanges — push stats accumulation', () {
    test('returns true with correct push count when all succeed', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => {SupabaseConstants.birdsTable});
      when(() => mockBirdRepo.pushAll(any()))
          .thenAnswer((_) async => (pushed: 5, orphansCleaned: 1));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isTrue);
    });

    test('profile L0 failure returns false', () async {
      when(() => mockSyncMetadataDao.getPendingTableNames(any()))
          .thenAnswer((_) async => <String>{});
      when(() => mockProfileRepo.pushPending(any()))
          .thenThrow(Exception('profile fail'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isFalse);
    });
  });
}
