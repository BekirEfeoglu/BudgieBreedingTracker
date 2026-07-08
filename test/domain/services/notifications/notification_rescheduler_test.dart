import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_settings_dao.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rescheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

// ── Mock classes ──

class MockIncubationsDao extends Mock implements IncubationsDao {}

class MockEggsDao extends Mock implements EggsDao {}

class MockChicksDao extends Mock implements ChicksDao {}

class MockNotificationSettingsDao extends Mock
    implements NotificationSettingsDao {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

// ── Helpers ──

const _userId = 'user-test';

Incubation _incubation({
  String id = 'incubation-aabbccdd',
  IncubationStatus status = IncubationStatus.active,
  Object? startDate = _sentinel,
}) {
  return Incubation(
    id: id,
    userId: _userId,
    status: status,
    startDate: startDate == _sentinel
        ? DateTime(2024, 1, 1)
        : startDate as DateTime?,
  );
}

const Object _sentinel = Object();

Egg _egg({
  String id = 'egg-1',
  int? eggNumber = 1,
  EggStatus status = EggStatus.incubating,
  String? incubationId,
}) {
  return Egg(
    id: id,
    userId: _userId,
    layDate: DateTime(2024, 1, 10),
    status: status,
    eggNumber: eggNumber,
    incubationId: incubationId,
  );
}

Chick _chick({
  String id = 'chick-aabbccdd',
  String? name,
  DateTime? hatchDate,
  DateTime? weanDate,
  DateTime? bandingDate,
  int bandingDay = 10,
}) {
  return Chick(
    id: id,
    userId: _userId,
    name: name,
    hatchDate: hatchDate ?? DateTime(2024, 1, 20),
    weanDate: weanDate,
    bandingDate: bandingDate,
    bandingDay: bandingDay,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Species.unknown);
    registerFallbackValue(DateTime(2024));
    registerFallbackValue(const NotificationToggleSettings());
  });

  late MockIncubationsDao mockIncubationsDao;
  late MockEggsDao mockEggsDao;
  late MockChicksDao mockChicksDao;
  late MockNotificationSettingsDao mockNotificationSettingsDao;
  late MockNotificationScheduler mockScheduler;
  late NotificationRescheduler rescheduler;

  setUp(() {
    mockIncubationsDao = MockIncubationsDao();
    mockEggsDao = MockEggsDao();
    mockChicksDao = MockChicksDao();
    mockNotificationSettingsDao = MockNotificationSettingsDao();
    mockScheduler = MockNotificationScheduler();

    rescheduler = NotificationRescheduler(
      incubationsDao: mockIncubationsDao,
      eggsDao: mockEggsDao,
      chicksDao: mockChicksDao,
      notificationSettingsDao: mockNotificationSettingsDao,
      scheduler: mockScheduler,
    );

    // Default: all DAOs return empty lists so tests only stub what they need
    when(() => mockIncubationsDao.getAll(_userId)).thenAnswer((_) async => []);
    when(() => mockEggsDao.getIncubating(_userId)).thenAnswer((_) async => []);
    when(() => mockChicksDao.getUnweaned(_userId)).thenAnswer((_) async => []);
    when(
      () => mockNotificationSettingsDao.getByUser(_userId),
    ).thenAnswer((_) async => null);

    // Default scheduler stubs — no-op
    when(
      () => mockScheduler.scheduleIncubationMilestones(
        incubationId: any(named: 'incubationId'),
        startDate: any(named: 'startDate'),
        label: any(named: 'label'),
        species: any(named: 'species'),
        settings: any(named: 'settings'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockScheduler.scheduleEggTurningReminders(
        eggId: any(named: 'eggId'),
        startDate: any(named: 'startDate'),
        eggLabel: any(named: 'eggLabel'),
        species: any(named: 'species'),
        settings: any(named: 'settings'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockScheduler.scheduleChickCareReminder(
        chickId: any(named: 'chickId'),
        chickLabel: any(named: 'chickLabel'),
        startDate: any(named: 'startDate'),
        intervalHours: any(named: 'intervalHours'),
        durationDays: any(named: 'durationDays'),
        settings: any(named: 'settings'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockScheduler.scheduleBandingReminders(
        chickId: any(named: 'chickId'),
        chickLabel: any(named: 'chickLabel'),
        hatchDate: any(named: 'hatchDate'),
        bandingDay: any(named: 'bandingDay'),
        settings: any(named: 'settings'),
      ),
    ).thenAnswer((_) async {});
  });

  group('NotificationRescheduler.rescheduleAll', () {
    test('passes saved toggle settings to all scheduled categories', () async {
      when(() => mockNotificationSettingsDao.getByUser(_userId)).thenAnswer(
        (_) async => const NotificationSettings(
          id: 'settings-1',
          userId: _userId,
          eggTurningEnabled: false,
          incubationReminderEnabled: false,
          feedingReminderEnabled: false,
          healthCheckEnabled: true,
          bandingEnabled: false,
        ),
      );
      final incubation = _incubation();
      final egg = _egg();
      final chick = _chick(name: 'Sunny');
      when(
        () => mockIncubationsDao.getAll(_userId),
      ).thenAnswer((_) async => [incubation]);
      when(
        () => mockEggsDao.getIncubating(_userId),
      ).thenAnswer((_) async => [egg]);
      when(
        () => mockChicksDao.getUnweaned(_userId),
      ).thenAnswer((_) async => [chick]);

      await rescheduler.rescheduleAll(_userId);

      final incubationSettings =
          verify(
                () => mockScheduler.scheduleIncubationMilestones(
                  incubationId: incubation.id,
                  startDate: incubation.startDate!,
                  label: 'incubati',
                  species: incubation.species,
                  settings: captureAny(named: 'settings'),
                ),
              ).captured.single
              as NotificationToggleSettings;
      final eggSettings =
          verify(
                () => mockScheduler.scheduleEggTurningReminders(
                  eggId: egg.id,
                  startDate: egg.layDate,
                  eggLabel: 'Egg 1',
                  species: Species.unknown,
                  settings: captureAny(named: 'settings'),
                ),
              ).captured.single
              as NotificationToggleSettings;
      final chickCareSettings =
          verify(
                () => mockScheduler.scheduleChickCareReminder(
                  chickId: chick.id,
                  chickLabel: 'Sunny',
                  startDate: chick.hatchDate!,
                  intervalHours: 4,
                  durationDays: 30,
                  settings: captureAny(named: 'settings'),
                ),
              ).captured.single
              as NotificationToggleSettings;
      final bandingSettings =
          verify(
                () => mockScheduler.scheduleBandingReminders(
                  chickId: chick.id,
                  chickLabel: 'Sunny',
                  hatchDate: chick.hatchDate!,
                  bandingDay: chick.bandingDay,
                  settings: captureAny(named: 'settings'),
                ),
              ).captured.single
              as NotificationToggleSettings;

      for (final settings in [
        incubationSettings,
        eggSettings,
        chickCareSettings,
        bandingSettings,
      ]) {
        expect(settings.eggTurning, isFalse);
        expect(settings.incubation, isFalse);
        expect(settings.chickCare, isFalse);
        expect(settings.banding, isFalse);
      }
    });

    group('incubations', () {
      test(
        'schedules milestones for active incubation with startDate',
        () async {
          // Arrange
          final incubation = _incubation(
            id: 'incubation-aabbccdd',
            status: IncubationStatus.active,
            startDate: DateTime(2024, 1, 1),
          );
          when(
            () => mockIncubationsDao.getAll(_userId),
          ).thenAnswer((_) async => [incubation]);

          // Act
          await rescheduler.rescheduleAll(_userId);

          // Assert
          verify(
            () => mockScheduler.scheduleIncubationMilestones(
              incubationId: 'incubation-aabbccdd',
              startDate: DateTime(2024, 1, 1),
              label: 'incubati',
              species: incubation.species,
              settings: any(named: 'settings'),
            ),
          ).called(1);
        },
      );

      test('skips completed incubations', () async {
        // Arrange
        final incubation = _incubation(status: IncubationStatus.completed);
        when(
          () => mockIncubationsDao.getAll(_userId),
        ).thenAnswer((_) async => [incubation]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verifyNever(
          () => mockScheduler.scheduleIncubationMilestones(
            incubationId: any(named: 'incubationId'),
            startDate: any(named: 'startDate'),
            label: any(named: 'label'),
            species: any(named: 'species'),
            settings: any(named: 'settings'),
          ),
        );
      });

      test('skips cancelled incubations', () async {
        // Arrange
        final incubation = _incubation(status: IncubationStatus.cancelled);
        when(
          () => mockIncubationsDao.getAll(_userId),
        ).thenAnswer((_) async => [incubation]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verifyNever(
          () => mockScheduler.scheduleIncubationMilestones(
            incubationId: any(named: 'incubationId'),
            startDate: any(named: 'startDate'),
            label: any(named: 'label'),
            species: any(named: 'species'),
            settings: any(named: 'settings'),
          ),
        );
      });

      test('skips active incubation with null startDate', () async {
        // Arrange
        final incubation = _incubation(
          status: IncubationStatus.active,
          startDate: null as Object?,
        );
        when(
          () => mockIncubationsDao.getAll(_userId),
        ).thenAnswer((_) async => [incubation]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verifyNever(
          () => mockScheduler.scheduleIncubationMilestones(
            incubationId: any(named: 'incubationId'),
            startDate: any(named: 'startDate'),
            label: any(named: 'label'),
            species: any(named: 'species'),
            settings: any(named: 'settings'),
          ),
        );
      });
    });

    group('eggs', () {
      test('schedules egg turning for incubating eggs', () async {
        // Arrange
        final egg = _egg(id: 'egg-1', eggNumber: 3);
        when(
          () => mockEggsDao.getIncubating(_userId),
        ).thenAnswer((_) async => [egg]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verify(
          () => mockScheduler.scheduleEggTurningReminders(
            eggId: 'egg-1',
            startDate: egg.layDate,
            eggLabel: 'Egg 3',
            species: Species.unknown,
            settings: any(named: 'settings'),
          ),
        ).called(1);
      });

      test(
        'uses the egg incubation species when rescheduling egg turning',
        () async {
          final egg = _egg(
            id: 'egg-canary',
            eggNumber: 2,
            incubationId: 'inc-canary',
          );
          final incubation = _incubation(
            id: 'inc-canary',
            status: IncubationStatus.active,
          ).copyWith(species: Species.canary);
          when(
            () => mockEggsDao.getIncubating(_userId),
          ).thenAnswer((_) async => [egg]);
          when(
            () => mockIncubationsDao.getById('inc-canary'),
          ).thenAnswer((_) async => incubation);

          await rescheduler.rescheduleAll(_userId);

          verify(
            () => mockScheduler.scheduleEggTurningReminders(
              eggId: 'egg-canary',
              startDate: egg.layDate,
              eggLabel: 'Egg 2',
              species: Species.canary,
              settings: any(named: 'settings'),
            ),
          ).called(1);
        },
      );

      test('uses empty string suffix when eggNumber is null', () async {
        // Arrange
        final egg = _egg(id: 'egg-2', eggNumber: null);
        when(
          () => mockEggsDao.getIncubating(_userId),
        ).thenAnswer((_) async => [egg]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verify(
          () => mockScheduler.scheduleEggTurningReminders(
            eggId: 'egg-2',
            startDate: egg.layDate,
            eggLabel: 'Egg ',
            species: Species.unknown,
            settings: any(named: 'settings'),
          ),
        ).called(1);
      });

      test('handles empty egg list gracefully', () async {
        // Arrange — default stub already returns []

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verifyNever(
          () => mockScheduler.scheduleEggTurningReminders(
            eggId: any(named: 'eggId'),
            startDate: any(named: 'startDate'),
            eggLabel: any(named: 'eggLabel'),
            species: any(named: 'species'),
            settings: any(named: 'settings'),
          ),
        );
      });
    });

    group('chicks', () {
      test('schedules chick care and banding for unweaned chicks', () async {
        // Arrange
        final chick = _chick(
          id: 'chick-aabbccdd',
          name: 'Tweety',
          hatchDate: DateTime(2024, 1, 20),
        );
        when(
          () => mockChicksDao.getUnweaned(_userId),
        ).thenAnswer((_) async => [chick]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verify(
          () => mockScheduler.scheduleChickCareReminder(
            chickId: 'chick-aabbccdd',
            chickLabel: 'Tweety',
            startDate: DateTime(2024, 1, 20),
            intervalHours: 4,
            durationDays: 30,
            settings: any(named: 'settings'),
          ),
        ).called(1);

        verify(
          () => mockScheduler.scheduleBandingReminders(
            chickId: 'chick-aabbccdd',
            chickLabel: 'Tweety',
            hatchDate: DateTime(2024, 1, 20),
            bandingDay: 10,
            settings: any(named: 'settings'),
          ),
        ).called(1);
      });

      test('uses id substring as label when chick has no name', () async {
        // Arrange — id is 'chick-aabbccdd' → first 8 chars = 'chick-aa'
        final chick = _chick(id: 'chick-aabbccdd', name: null);
        when(
          () => mockChicksDao.getUnweaned(_userId),
        ).thenAnswer((_) async => [chick]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verify(
          () => mockScheduler.scheduleChickCareReminder(
            chickId: 'chick-aabbccdd',
            chickLabel: 'chick-aa',
            startDate: any(named: 'startDate'),
            intervalHours: 4,
            durationDays: 30,
            settings: any(named: 'settings'),
          ),
        ).called(1);
      });

      test('skips banding for already-banded chicks', () async {
        // Arrange
        final chick = _chick(
          bandingDate: DateTime(2024, 1, 30), // already banded
        );
        when(
          () => mockChicksDao.getUnweaned(_userId),
        ).thenAnswer((_) async => [chick]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert — care is scheduled but banding is skipped
        verify(
          () => mockScheduler.scheduleChickCareReminder(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            startDate: any(named: 'startDate'),
            intervalHours: any(named: 'intervalHours'),
            durationDays: any(named: 'durationDays'),
            settings: any(named: 'settings'),
          ),
        ).called(1);

        verifyNever(
          () => mockScheduler.scheduleBandingReminders(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            hatchDate: any(named: 'hatchDate'),
            bandingDay: any(named: 'bandingDay'),
            settings: any(named: 'settings'),
          ),
        );
      });

      test('handles empty chick list gracefully', () async {
        // Arrange — default stub already returns []

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verifyNever(
          () => mockScheduler.scheduleChickCareReminder(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            startDate: any(named: 'startDate'),
            intervalHours: any(named: 'intervalHours'),
            durationDays: any(named: 'durationDays'),
            settings: any(named: 'settings'),
          ),
        );
      });
    });

    group('error isolation', () {
      test(
        'continues processing eggs and chicks when incubationsDao throws',
        () async {
          // Arrange
          when(
            () => mockIncubationsDao.getAll(_userId),
          ).thenThrow(Exception('DB error'));
          final egg = _egg();
          when(
            () => mockEggsDao.getIncubating(_userId),
          ).thenAnswer((_) async => [egg]);
          final chick = _chick();
          when(
            () => mockChicksDao.getUnweaned(_userId),
          ).thenAnswer((_) async => [chick]);

          // Act — should not throw
          await expectLater(rescheduler.rescheduleAll(_userId), completes);

          // Assert — eggs and chicks still processed
          verify(
            () => mockScheduler.scheduleEggTurningReminders(
              eggId: any(named: 'eggId'),
              startDate: any(named: 'startDate'),
              eggLabel: any(named: 'eggLabel'),
              species: any(named: 'species'),
              settings: any(named: 'settings'),
            ),
          ).called(1);

          verify(
            () => mockScheduler.scheduleChickCareReminder(
              chickId: any(named: 'chickId'),
              chickLabel: any(named: 'chickLabel'),
              startDate: any(named: 'startDate'),
              intervalHours: any(named: 'intervalHours'),
              durationDays: any(named: 'durationDays'),
              settings: any(named: 'settings'),
            ),
          ).called(1);
        },
      );

      test(
        'continues processing incubations and chicks when eggsDao throws',
        () async {
          // Arrange
          final incubation = _incubation();
          when(
            () => mockIncubationsDao.getAll(_userId),
          ).thenAnswer((_) async => [incubation]);
          when(
            () => mockEggsDao.getIncubating(_userId),
          ).thenThrow(Exception('network error'));
          final chick = _chick();
          when(
            () => mockChicksDao.getUnweaned(_userId),
          ).thenAnswer((_) async => [chick]);

          // Act
          await expectLater(rescheduler.rescheduleAll(_userId), completes);

          // Assert — incubations and chicks still processed
          verify(
            () => mockScheduler.scheduleIncubationMilestones(
              incubationId: any(named: 'incubationId'),
              startDate: any(named: 'startDate'),
              label: any(named: 'label'),
              species: any(named: 'species'),
              settings: any(named: 'settings'),
            ),
          ).called(1);

          verify(
            () => mockScheduler.scheduleChickCareReminder(
              chickId: any(named: 'chickId'),
              chickLabel: any(named: 'chickLabel'),
              startDate: any(named: 'startDate'),
              intervalHours: any(named: 'intervalHours'),
              durationDays: any(named: 'durationDays'),
              settings: any(named: 'settings'),
            ),
          ).called(1);
        },
      );
    });
  });
}
