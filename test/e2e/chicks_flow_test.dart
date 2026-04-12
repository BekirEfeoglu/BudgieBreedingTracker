@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Chicks Flow E2E', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'GIVEN hatched egg context WHEN chick is created THEN repository.save is called and newborn stage is available',
      () async {
        final mockChickRepository = MockChickRepository();
        final mockNotificationScheduler = MockNotificationScheduler();
        final mockCalendarGenerator = MockCalendarEventGenerator();

        when(() => mockChickRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockNotificationScheduler.scheduleChickCareReminder(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            startDate: any(named: 'startDate'),
            intervalHours: any(named: 'intervalHours'),
            durationDays: any(named: 'durationDays'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockCalendarGenerator.generateChickEvents(
            userId: any(named: 'userId'),
            hatchDate: any(named: 'hatchDate'),
            chickLabel: any(named: 'chickLabel'),
          ),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            chickRepositoryProvider.overrideWithValue(mockChickRepository),
            notificationSchedulerProvider.overrideWithValue(
              mockNotificationScheduler,
            ),
            calendarEventGeneratorProvider.overrideWithValue(
              mockCalendarGenerator,
            ),
          ],
        );
        addTearDown(container.dispose);

        final hatchDate = DateTime.now();
        await container
            .read(chickFormStateProvider.notifier)
            .createChick(
              userId: 'test-user',
              gender: BirdGender.unknown,
              hatchWeight: 2.1,
              hatchDate: hatchDate,
              healthStatus: ChickHealthStatus.healthy,
            );

        final saved =
            verify(() => mockChickRepository.save(captureAny())).captured.single
                as Chick;
        expect(saved.hatchWeight, 2.1);
        expect(saved.healthStatus, ChickHealthStatus.healthy);
        expect(saved.developmentStage, DevelopmentStage.newborn);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN existing chick WHEN age checkpoints are evaluated THEN stage badges map to newborn/nestling/fledgling/juvenile',
      () {
        final now = DateTime.now();
        final day7 = Chick(
          id: 'c1',
          userId: 'u1',
          hatchDate: now.subtract(const Duration(days: 7)),
        );
        final day21 = Chick(
          id: 'c2',
          userId: 'u1',
          hatchDate: now.subtract(const Duration(days: 21)),
        );
        final day35 = Chick(
          id: 'c3',
          userId: 'u1',
          hatchDate: now.subtract(const Duration(days: 35)),
        );
        final day40 = Chick(
          id: 'c4',
          userId: 'u1',
          hatchDate: now.subtract(const Duration(days: 40)),
        );

        expect(day7.developmentStage, DevelopmentStage.newborn);
        expect(day21.developmentStage, DevelopmentStage.nestling);
        expect(day35.developmentStage, DevelopmentStage.fledgling);
        expect(day40.developmentStage, DevelopmentStage.juvenile);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN chick in weaning stage WHEN wean action completes THEN wean date is saved, reminder scheduling path runs and promotion to Bird is possible',
      () async {
        final mockChickRepository = MockChickRepository();
        final mockBirdRepository = MockBirdRepository();
        final mockEggRepository = MockEggRepository();
        final mockIncubationRepository = MockIncubationRepository();
        final mockPairRepository = MockBreedingPairRepository();
        final mockNotificationScheduler = MockNotificationScheduler();
        final mockCalendarGenerator = MockCalendarEventGenerator();

        final chick = Chick(
          id: 'chick-1',
          userId: 'test-user',
          eggId: 'egg-1',
          hatchDate: DateTime.now().subtract(const Duration(days: 28)),
          gender: BirdGender.female,
        );

        when(() => mockChickRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockChickRepository.getById('chick-1'),
        ).thenAnswer((_) async => chick);
        when(() => mockBirdRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockEggRepository.getById('egg-1'),
        ).thenAnswer((_) async => null);
        when(
          () => mockIncubationRepository.getById(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockPairRepository.getById(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockNotificationScheduler.scheduleChickCareReminder(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            startDate: any(named: 'startDate'),
            intervalHours: any(named: 'intervalHours'),
            durationDays: any(named: 'durationDays'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockCalendarGenerator.generateChickEvents(
            userId: any(named: 'userId'),
            hatchDate: any(named: 'hatchDate'),
            chickLabel: any(named: 'chickLabel'),
          ),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            chickRepositoryProvider.overrideWithValue(mockChickRepository),
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
            eggRepositoryProvider.overrideWithValue(mockEggRepository),
            incubationRepositoryProvider.overrideWithValue(
              mockIncubationRepository,
            ),
            breedingPairRepositoryProvider.overrideWithValue(
              mockPairRepository,
            ),
            notificationSchedulerProvider.overrideWithValue(
              mockNotificationScheduler,
            ),
            calendarEventGeneratorProvider.overrideWithValue(
              mockCalendarGenerator,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(chickFormStateProvider.notifier)
            .createChick(
              userId: 'test-user',
              hatchDate: DateTime.now(),
              name: 'Yavru 1',
            );

        await container
            .read(chickFormStateProvider.notifier)
            .markAsWeaned('chick-1');
        await container
            .read(chickFormStateProvider.notifier)
            .promoteToBird(chick);

        verify(
          () => mockNotificationScheduler.scheduleChickCareReminder(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            startDate: any(named: 'startDate'),
            intervalHours: any(named: 'intervalHours'),
            durationDays: any(named: 'durationDays'),
            settings: any(named: 'settings'),
          ),
        ).called(1);

        final weanedSaveCalls = verify(
          () => mockChickRepository.save(captureAny()),
        ).captured.cast<Chick>();
        expect(weanedSaveCalls.any((entry) => entry.weanDate != null), isTrue);
        verify(() => mockBirdRepository.save(any())).called(1);
      },
      timeout: e2eTimeout,
    );
  });
}
