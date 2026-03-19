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

// Local provider so SyncPushHandler receives a proper Riverpod Ref
final _syncPushHandlerProvider = Provider<SyncPushHandler>(
  (ref) => SyncPushHandler(ref),
);

const _userId = 'user-1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBirdRepository mockBirdRepository;
  late MockNestRepository mockNestRepository;
  late MockBreedingPairRepository mockBreedingPairRepository;
  late MockClutchRepository mockClutchRepository;
  late MockIncubationRepository mockIncubationRepository;
  late MockEggRepository mockEggRepository;
  late MockChickRepository mockChickRepository;
  late MockHealthRecordRepository mockHealthRecordRepository;
  late MockGrowthMeasurementRepository mockGrowthMeasurementRepository;
  late MockEventRepository mockEventRepository;
  late MockNotificationRepository mockNotificationRepository;
  late MockNotificationScheduleRepository mockNotificationScheduleRepository;
  late MockPhotoRepository mockPhotoRepository;
  late MockEventReminderRepository mockEventReminderRepository;
  late MockProfileRepository mockProfileRepository;
  late MockSyncMetadataDao mockSyncMetadataDao;

  void stubAllPushes() {
    when(
      () => mockProfileRepository.pushPending(any()),
    ).thenAnswer((_) async {});

    when(
      () => mockBirdRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockNestRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockBreedingPairRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockClutchRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockIncubationRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockEggRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockChickRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockHealthRecordRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockGrowthMeasurementRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockEventRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockNotificationRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockNotificationScheduleRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockPhotoRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);
    when(
      () => mockEventReminderRepository.pushAll(any()),
    ).thenAnswer((_) async => emptyPushStats);

    when(
      () => mockSyncMetadataDao.getPendingTableNames(any()),
    ).thenAnswer((_) async => <String>{});
  }

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        birdRepositoryProvider.overrideWithValue(mockBirdRepository),
        nestRepositoryProvider.overrideWithValue(mockNestRepository),
        breedingPairRepositoryProvider.overrideWithValue(
          mockBreedingPairRepository,
        ),
        clutchRepositoryProvider.overrideWithValue(mockClutchRepository),
        incubationRepositoryProvider.overrideWithValue(
          mockIncubationRepository,
        ),
        eggRepositoryProvider.overrideWithValue(mockEggRepository),
        chickRepositoryProvider.overrideWithValue(mockChickRepository),
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
        notificationScheduleRepositoryProvider.overrideWithValue(
          mockNotificationScheduleRepository,
        ),
        photoRepositoryProvider.overrideWithValue(mockPhotoRepository),
        eventReminderRepositoryProvider.overrideWithValue(
          mockEventReminderRepository,
        ),
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        syncMetadataDaoProvider.overrideWithValue(mockSyncMetadataDao),
      ],
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockBirdRepository = MockBirdRepository();
    mockNestRepository = MockNestRepository();
    mockBreedingPairRepository = MockBreedingPairRepository();
    mockClutchRepository = MockClutchRepository();
    mockIncubationRepository = MockIncubationRepository();
    mockEggRepository = MockEggRepository();
    mockChickRepository = MockChickRepository();
    mockHealthRecordRepository = MockHealthRecordRepository();
    mockGrowthMeasurementRepository = MockGrowthMeasurementRepository();
    mockEventRepository = MockEventRepository();
    mockNotificationRepository = MockNotificationRepository();
    mockNotificationScheduleRepository = MockNotificationScheduleRepository();
    mockPhotoRepository = MockPhotoRepository();
    mockEventReminderRepository = MockEventReminderRepository();
    mockProfileRepository = MockProfileRepository();
    mockSyncMetadataDao = MockSyncMetadataDao();

    stubAllPushes();
  });

  group('SyncPushHandler.pushTable', () {
    test('dispatches birds table to birdRepository.pushAll', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushTable(_userId, SupabaseConstants.birdsTable);

      verify(() => mockBirdRepository.pushAll(_userId)).called(1);
    });

    test('dispatches eggs table to eggRepository.pushAll', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushTable(_userId, SupabaseConstants.eggsTable);

      verify(() => mockEggRepository.pushAll(_userId)).called(1);
    });

    test('dispatches chicks table to chickRepository.pushAll', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushTable(_userId, SupabaseConstants.chicksTable);

      verify(() => mockChickRepository.pushAll(_userId)).called(1);
    });

    test(
      'dispatches breeding_pairs table to breedingPairRepository.pushAll',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPushHandlerProvider);

        await handler.pushTable(_userId, SupabaseConstants.breedingPairsTable);

        verify(() => mockBreedingPairRepository.pushAll(_userId)).called(1);
      },
    );

    test(
      'dispatches incubations table to incubationRepository.pushAll',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPushHandlerProvider);

        await handler.pushTable(_userId, SupabaseConstants.incubationsTable);

        verify(() => mockIncubationRepository.pushAll(_userId)).called(1);
      },
    );

    test(
      'dispatches health_records table to healthRecordRepository.pushAll',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPushHandlerProvider);

        await handler.pushTable(_userId, SupabaseConstants.healthRecordsTable);

        verify(() => mockHealthRecordRepository.pushAll(_userId)).called(1);
      },
    );

    test('dispatches nests table to nestRepository.pushAll', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushTable(_userId, SupabaseConstants.nestsTable);

      verify(() => mockNestRepository.pushAll(_userId)).called(1);
    });

    test('dispatches photos table to photoRepository.pushAll', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushTable(_userId, SupabaseConstants.photosTable);

      verify(() => mockPhotoRepository.pushAll(_userId)).called(1);
    });

    test(
      'dispatches profiles table to profileRepository.pushPending',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPushHandlerProvider);

        await handler.pushTable(_userId, SupabaseConstants.profilesTable);

        verify(() => mockProfileRepository.pushPending(_userId)).called(1);
      },
    );

    test('unknown table does not throw and calls no repo', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await expectLater(
        handler.pushTable(_userId, 'unknown_table_xyz'),
        completes,
      );

      verifyNever(() => mockBirdRepository.pushAll(any()));
      verifyNever(() => mockEggRepository.pushAll(any()));
    });

    test('repo exception is caught and does not propagate', () async {
      when(
        () => mockBirdRepository.pushAll(any()),
      ).thenThrow(Exception('Push failed'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await expectLater(
        handler.pushTable(_userId, SupabaseConstants.birdsTable),
        completes,
      );
    });
  });

  group('SyncPushHandler.pushChanges', () {
    test('returns true when no pending tables', () async {
      when(
        () => mockSyncMetadataDao.getPendingTableNames(any()),
      ).thenAnswer((_) async => <String>{});

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isTrue);
    });

    test(
      'always calls profile pushPending regardless of pending set',
      () async {
        when(
          () => mockSyncMetadataDao.getPendingTableNames(any()),
        ).thenAnswer((_) async => <String>{});

        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPushHandlerProvider);

        await handler.pushChanges(_userId);

        verify(() => mockProfileRepository.pushPending(_userId)).called(1);
      },
    );

    test('skips bird push when birds table not in pending set', () async {
      when(
        () => mockSyncMetadataDao.getPendingTableNames(any()),
      ).thenAnswer((_) async => <String>{SupabaseConstants.eggsTable});

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushChanges(_userId);

      verifyNever(() => mockBirdRepository.pushAll(any()));
    });

    test('calls bird push when birds table is in pending set', () async {
      when(
        () => mockSyncMetadataDao.getPendingTableNames(any()),
      ).thenAnswer((_) async => {SupabaseConstants.birdsTable});

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      await handler.pushChanges(_userId);

      verify(() => mockBirdRepository.pushAll(_userId)).called(1);
    });

    test('returns false when a layer push fails', () async {
      when(
        () => mockSyncMetadataDao.getPendingTableNames(any()),
      ).thenAnswer((_) async => {SupabaseConstants.birdsTable});

      when(
        () => mockBirdRepository.pushAll(any()),
      ).thenThrow(Exception('fail'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPushHandlerProvider);

      final result = await handler.pushChanges(_userId);

      expect(result, isFalse);
    });
  });
}
