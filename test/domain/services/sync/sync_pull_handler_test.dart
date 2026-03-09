import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:budgie_breeding_tracker/domain/services/sync/sync_pull_handler.dart';

// Local provider so SyncPullHandler receives a proper Riverpod Ref
final _syncPullHandlerProvider = Provider<SyncPullHandler>(
  (ref) => SyncPullHandler(ref),
);

class MockBirdRepository extends Mock implements BirdRepository {}

class MockNestRepository extends Mock implements NestRepository {}

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockClutchRepository extends Mock implements ClutchRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

class MockEggRepository extends Mock implements EggRepository {}

class MockChickRepository extends Mock implements ChickRepository {}

class MockHealthRecordRepository extends Mock
    implements HealthRecordRepository {}

class MockGrowthMeasurementRepository extends Mock
    implements GrowthMeasurementRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockNotificationScheduleRepository extends Mock
    implements NotificationScheduleRepository {}

class MockPhotoRepository extends Mock implements PhotoRepository {}

class MockEventReminderRepository extends Mock
    implements EventReminderRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

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

  void stubAllPulls() {
    when(() => mockProfileRepository.pull(any())).thenAnswer((_) async {});

    when(
      () => mockBirdRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockBirdRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockNestRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockNestRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockBreedingPairRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockBreedingPairRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockClutchRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockClutchRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockIncubationRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockEggRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockEggRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockChickRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockChickRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockHealthRecordRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockHealthRecordRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockGrowthMeasurementRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockEventRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockEventRepository.lastPullConflicts).thenReturn([]);

    when(
      () => mockNotificationRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});

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
      () => mockPhotoRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockEventReminderRepository.pull(
        any(),
        lastSyncedAt: any(named: 'lastSyncedAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockEventReminderRepository.lastPullConflicts).thenReturn([]);
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

    stubAllPulls();
  });

  group('SyncPullHandler.pullChanges', () {
    test('passes since=null to repos for full reconciliation', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPullHandlerProvider);

      await handler.pullChanges(_userId, since: null);

      final captured = verify(
        () => mockBirdRepository.pull(
          _userId,
          lastSyncedAt: captureAny(named: 'lastSyncedAt'),
        ),
      ).captured;
      expect(captured.last, isNull);
    });

    test('passes past since value to repos for incremental pull', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPullHandlerProvider);

      final pastTime = DateTime(2020, 1, 1);
      await handler.pullChanges(_userId, since: pastTime);

      final captured = verify(
        () => mockBirdRepository.pull(
          _userId,
          lastSyncedAt: captureAny(named: 'lastSyncedAt'),
        ),
      ).captured;
      expect(captured.last, pastTime);
    });

    test(
      'clock skew: future since is reset to null (full reconciliation)',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPullHandlerProvider);

        // since is set to 1 hour in the future — clock skew scenario
        final futureTime = DateTime.now().add(const Duration(hours: 1));
        await handler.pullChanges(_userId, since: futureTime);

        // Repos should receive null, not the future timestamp
        final captured = verify(
          () => mockBirdRepository.pull(
            _userId,
            lastSyncedAt: captureAny(named: 'lastSyncedAt'),
          ),
        ).captured;
        expect(
          captured.last,
          isNull,
          reason: 'Clock skew: future since should be converted to null',
        );
      },
    );

    test('clock skew boundary: 1ms future is treated as clock skew', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPullHandlerProvider);

      // Even 1 ms in the future triggers clock skew protection
      final slightlyFuture = DateTime.now().add(
        const Duration(milliseconds: 1),
      );
      await handler.pullChanges(_userId, since: slightlyFuture);

      final captured = verify(
        () => mockBirdRepository.pull(
          _userId,
          lastSyncedAt: captureAny(named: 'lastSyncedAt'),
        ),
      ).captured;
      expect(
        captured.last,
        isNull,
        reason: '1ms future should also be treated as clock skew',
      );
    });

    test(
      'clock skew boundary: 1ms past is NOT treated as clock skew',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final handler = container.read(_syncPullHandlerProvider);

        // 1 ms in the past — should NOT be affected by clock skew protection
        final slightlyPast = DateTime.now().subtract(
          const Duration(milliseconds: 1),
        );
        await handler.pullChanges(_userId, since: slightlyPast);

        final captured = verify(
          () => mockBirdRepository.pull(
            _userId,
            lastSyncedAt: captureAny(named: 'lastSyncedAt'),
          ),
        ).captured;
        // since is in the past — should be passed through, not nullified
        expect(
          captured.last,
          isNotNull,
          reason: '1ms-past since should be forwarded as-is (no clock skew)',
        );
      },
    );

    test('calls all repository pull methods', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPullHandlerProvider);

      await handler.pullChanges(_userId);

      verify(() => mockProfileRepository.pull(_userId)).called(1);
      verify(
        () => mockBirdRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).called(1);
      verify(
        () => mockNestRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).called(1);
      verify(
        () => mockBreedingPairRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).called(1);
      verify(
        () => mockEggRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).called(1);
      verify(
        () => mockChickRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).called(1);
      verify(
        () => mockHealthRecordRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).called(1);
      verify(
        () => mockEventRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).called(1);
      verify(
        () => mockEventReminderRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).called(1);
    });

    test('does not throw when a layer repo throws', () async {
      when(
        () => mockBirdRepository.pull(
          any(),
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenThrow(Exception('Network error'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPullHandlerProvider);

      // Should complete without throwing — errors are isolated per layer
      await expectLater(handler.pullChanges(_userId), completes);
    });

    test('still pulls other repos when one layer fails', () async {
      when(
        () => mockBirdRepository.pull(
          any(),
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).thenThrow(Exception('L1 error'));

      final container = createContainer();
      addTearDown(container.dispose);
      final handler = container.read(_syncPullHandlerProvider);

      await handler.pullChanges(_userId);

      // L4 (eggs) depends on L3, not L1, so eggs should still be pulled
      verify(
        () => mockEggRepository.pull(
          _userId,
          lastSyncedAt: any(named: 'lastSyncedAt'),
        ),
      ).called(1);
    });
  });
}
