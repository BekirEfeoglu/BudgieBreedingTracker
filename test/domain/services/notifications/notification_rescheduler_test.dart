import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rescheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';

// ── Mock classes ──

class MockIncubationsDao extends Mock implements IncubationsDao {}

class MockEggsDao extends Mock implements EggsDao {}

class MockChicksDao extends Mock implements ChicksDao {}

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
}) {
  return Egg(
    id: id,
    userId: _userId,
    layDate: DateTime(2024, 1, 10),
    status: status,
    eggNumber: eggNumber,
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
  });

  late MockIncubationsDao mockIncubationsDao;
  late MockEggsDao mockEggsDao;
  late MockChicksDao mockChicksDao;
  late MockNotificationScheduler mockScheduler;
  late NotificationRescheduler rescheduler;

  setUp(() {
    mockIncubationsDao = MockIncubationsDao();
    mockEggsDao = MockEggsDao();
    mockChicksDao = MockChicksDao();
    mockScheduler = MockNotificationScheduler();

    rescheduler = NotificationRescheduler(
      incubationsDao: mockIncubationsDao,
      eggsDao: mockEggsDao,
      chicksDao: mockChicksDao,
      scheduler: mockScheduler,
    );

    // Default: all DAOs return empty lists so tests only stub what they need
    when(() => mockIncubationsDao.getAll(_userId))
        .thenAnswer((_) async => []);
    when(() => mockEggsDao.getIncubating(_userId))
        .thenAnswer((_) async => []);
    when(() => mockChicksDao.getUnweaned(_userId))
        .thenAnswer((_) async => []);

    // Default scheduler stubs — no-op
    when(
      () => mockScheduler.scheduleIncubationMilestones(
        incubationId: any(named: 'incubationId'),
        startDate: any(named: 'startDate'),
        label: any(named: 'label'),
        species: any(named: 'species'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockScheduler.scheduleEggTurningReminders(
        eggId: any(named: 'eggId'),
        startDate: any(named: 'startDate'),
        eggLabel: any(named: 'eggLabel'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockScheduler.scheduleChickCareReminder(
        chickId: any(named: 'chickId'),
        chickLabel: any(named: 'chickLabel'),
        startDate: any(named: 'startDate'),
        intervalHours: any(named: 'intervalHours'),
        durationDays: any(named: 'durationDays'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockScheduler.scheduleBandingReminders(
        chickId: any(named: 'chickId'),
        chickLabel: any(named: 'chickLabel'),
        hatchDate: any(named: 'hatchDate'),
        bandingDay: any(named: 'bandingDay'),
      ),
    ).thenAnswer((_) async {});
  });

  group('NotificationRescheduler.rescheduleAll', () {
    group('incubations', () {
      test('schedules milestones for active incubation with startDate',
          () async {
        // Arrange
        final incubation = _incubation(
          id: 'incubation-aabbccdd',
          status: IncubationStatus.active,
          startDate: DateTime(2024, 1, 1),
        );
        when(() => mockIncubationsDao.getAll(_userId))
            .thenAnswer((_) async => [incubation]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verify(
          () => mockScheduler.scheduleIncubationMilestones(
            incubationId: 'incubation-aabbccdd',
            startDate: DateTime(2024, 1, 1),
            label: 'incubati',
            species: incubation.species,
          ),
        ).called(1);
      });

      test('skips completed incubations', () async {
        // Arrange
        final incubation = _incubation(status: IncubationStatus.completed);
        when(() => mockIncubationsDao.getAll(_userId))
            .thenAnswer((_) async => [incubation]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verifyNever(
          () => mockScheduler.scheduleIncubationMilestones(
            incubationId: any(named: 'incubationId'),
            startDate: any(named: 'startDate'),
            label: any(named: 'label'),
            species: any(named: 'species'),
          ),
        );
      });

      test('skips cancelled incubations', () async {
        // Arrange
        final incubation = _incubation(status: IncubationStatus.cancelled);
        when(() => mockIncubationsDao.getAll(_userId))
            .thenAnswer((_) async => [incubation]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verifyNever(
          () => mockScheduler.scheduleIncubationMilestones(
            incubationId: any(named: 'incubationId'),
            startDate: any(named: 'startDate'),
            label: any(named: 'label'),
            species: any(named: 'species'),
          ),
        );
      });

      test('skips active incubation with null startDate', () async {
        // Arrange
        final incubation = _incubation(
          status: IncubationStatus.active,
          startDate: null as Object?,
        );
        when(() => mockIncubationsDao.getAll(_userId))
            .thenAnswer((_) async => [incubation]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verifyNever(
          () => mockScheduler.scheduleIncubationMilestones(
            incubationId: any(named: 'incubationId'),
            startDate: any(named: 'startDate'),
            label: any(named: 'label'),
            species: any(named: 'species'),
          ),
        );
      });
    });

    group('eggs', () {
      test('schedules egg turning for incubating eggs', () async {
        // Arrange
        final egg = _egg(id: 'egg-1', eggNumber: 3);
        when(() => mockEggsDao.getIncubating(_userId))
            .thenAnswer((_) async => [egg]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verify(
          () => mockScheduler.scheduleEggTurningReminders(
            eggId: 'egg-1',
            startDate: egg.layDate,
            eggLabel: 'Egg 3',
          ),
        ).called(1);
      });

      test('uses empty string suffix when eggNumber is null', () async {
        // Arrange
        final egg = _egg(id: 'egg-2', eggNumber: null);
        when(() => mockEggsDao.getIncubating(_userId))
            .thenAnswer((_) async => [egg]);

        // Act
        await rescheduler.rescheduleAll(_userId);

        // Assert
        verify(
          () => mockScheduler.scheduleEggTurningReminders(
            eggId: 'egg-2',
            startDate: egg.layDate,
            eggLabel: 'Egg ',
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
        when(() => mockChicksDao.getUnweaned(_userId))
            .thenAnswer((_) async => [chick]);

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
          ),
        ).called(1);

        verify(
          () => mockScheduler.scheduleBandingReminders(
            chickId: 'chick-aabbccdd',
            chickLabel: 'Tweety',
            hatchDate: DateTime(2024, 1, 20),
            bandingDay: 10,
          ),
        ).called(1);
      });

      test('uses id substring as label when chick has no name', () async {
        // Arrange — id is 'chick-aabbccdd' → first 8 chars = 'chick-aa'
        final chick = _chick(id: 'chick-aabbccdd', name: null);
        when(() => mockChicksDao.getUnweaned(_userId))
            .thenAnswer((_) async => [chick]);

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
          ),
        ).called(1);
      });

      test('skips banding for already-banded chicks', () async {
        // Arrange
        final chick = _chick(
          bandingDate: DateTime(2024, 1, 30), // already banded
        );
        when(() => mockChicksDao.getUnweaned(_userId))
            .thenAnswer((_) async => [chick]);

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
          ),
        ).called(1);

        verifyNever(
          () => mockScheduler.scheduleBandingReminders(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            hatchDate: any(named: 'hatchDate'),
            bandingDay: any(named: 'bandingDay'),
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
          ),
        );
      });
    });

    group('error isolation', () {
      test('continues processing eggs and chicks when incubationsDao throws',
          () async {
        // Arrange
        when(() => mockIncubationsDao.getAll(_userId))
            .thenThrow(Exception('DB error'));
        final egg = _egg();
        when(() => mockEggsDao.getIncubating(_userId))
            .thenAnswer((_) async => [egg]);
        final chick = _chick();
        when(() => mockChicksDao.getUnweaned(_userId))
            .thenAnswer((_) async => [chick]);

        // Act — should not throw
        await expectLater(
          rescheduler.rescheduleAll(_userId),
          completes,
        );

        // Assert — eggs and chicks still processed
        verify(
          () => mockScheduler.scheduleEggTurningReminders(
            eggId: any(named: 'eggId'),
            startDate: any(named: 'startDate'),
            eggLabel: any(named: 'eggLabel'),
          ),
        ).called(1);

        verify(
          () => mockScheduler.scheduleChickCareReminder(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            startDate: any(named: 'startDate'),
            intervalHours: any(named: 'intervalHours'),
            durationDays: any(named: 'durationDays'),
          ),
        ).called(1);
      });

      test('continues processing incubations and chicks when eggsDao throws',
          () async {
        // Arrange
        final incubation = _incubation();
        when(() => mockIncubationsDao.getAll(_userId))
            .thenAnswer((_) async => [incubation]);
        when(() => mockEggsDao.getIncubating(_userId))
            .thenThrow(Exception('network error'));
        final chick = _chick();
        when(() => mockChicksDao.getUnweaned(_userId))
            .thenAnswer((_) async => [chick]);

        // Act
        await expectLater(
          rescheduler.rescheduleAll(_userId),
          completes,
        );

        // Assert — incubations and chicks still processed
        verify(
          () => mockScheduler.scheduleIncubationMilestones(
            incubationId: any(named: 'incubationId'),
            startDate: any(named: 'startDate'),
            label: any(named: 'label'),
            species: any(named: 'species'),
          ),
        ).called(1);

        verify(
          () => mockScheduler.scheduleChickCareReminder(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            startDate: any(named: 'startDate'),
            intervalHours: any(named: 'intervalHours'),
            durationDays: any(named: 'durationDays'),
          ),
        ).called(1);
      });
    });
  });
}
