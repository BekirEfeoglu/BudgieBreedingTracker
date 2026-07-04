import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_generator.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';

import '../../../helpers/mocks.dart';

Event _dummyEvent() => Event(
  id: 'id',
  title: 'title',
  eventDate: DateTime(2026, 1, 1),
  type: EventType.custom,
  userId: 'user-1',
);

void main() {
  late MockEventRepository mockRepo;
  late CalendarEventGenerator generator;

  setUpAll(() {
    registerFallbackValue(_dummyEvent());
    registerFallbackValue(<Event>[]);
  });

  setUp(() {
    mockRepo = MockEventRepository();
    generator = CalendarEventGenerator(mockRepo);
    when(() => mockRepo.save(any())).thenAnswer((_) async {});
    when(() => mockRepo.saveAll(any())).thenAnswer((_) async {});
  });

  group('CalendarEventGenerator', () {
    test('generateIncubationEvents creates 5 future events', () async {
      final startDate = DateTime.now().add(const Duration(days: 1));

      await generator.generateIncubationEvents(
        userId: 'user-1',
        breedingPairId: 'pair-1',
        startDate: startDate,
        pairLabel: 'Pair A',
      );

      final captured =
          verify(() => mockRepo.saveAll(captureAny())).captured.single
              as List<dynamic>;
      expect(captured.length, 5);
    });

    test(
      'generateIncubationEvents skips all milestones in distant past',
      () async {
        final startDate = DateTime.now().subtract(const Duration(days: 100));

        await generator.generateIncubationEvents(
          userId: 'user-1',
          breedingPairId: 'pair-1',
          startDate: startDate,
          pairLabel: 'Pair A',
        );

        verifyNever(() => mockRepo.saveAll(any()));
      },
    );

    test(
      'generateIncubationEvents builds milestones via local field addition, so '
      'each event lands on the same local calendar day as its reminder even for '
      'a start time near local midnight / a DST-transition boundary',
      () async {
        // A start "moment" late in the local day (23:50) is the case where
        // naive `startDate.add(Duration(days: N))` wall-clock math is most
        // likely to drift onto the wrong calendar day. Field addition
        // (day + N) is DST-safe AND — unlike a UTC-midnight instant, which
        // .toLocal() shifts a day earlier in UTC-negative zones — keeps the
        // event on the local day the notification scheduler fires on. Anchored
        // relative to `now` so this test never goes stale.
        final anchor = DateTime.now().add(const Duration(days: 10));
        final startDate = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
          23,
          50,
        );
        final milestones = incubationMilestonesForSpecies(Species.unknown);
        DateTime milestoneDate(int day) =>
            DateTime(startDate.year, startDate.month, startDate.day + day);
        final futureDays = [
          milestones.candlingDay,
          milestones.secondCheckDay,
          milestones.sensitivePeriodDay,
          milestones.expectedHatchDay,
          milestones.lateHatchDay,
        ].where((day) => !milestoneDate(day).isBefore(DateTime.now()));

        await generator.generateIncubationEvents(
          userId: 'user-1',
          breedingPairId: 'pair-1',
          startDate: startDate,
          pairLabel: 'Pair A',
        );

        final captured =
            verify(() => mockRepo.saveAll(captureAny())).captured.single
                as List<Event>;
        final expectedDates = futureDays.map(milestoneDate).toSet();
        final actualDates = captured.map((e) => e.eventDate).toSet();
        expect(actualDates, expectedDates);
      },
    );

    test('generateEggEvents creates two events for future lay date', () async {
      final layDate = DateTime.now().add(const Duration(days: 1));

      await generator.generateEggEvents(
        userId: 'user-1',
        layDate: layDate,
        eggNumber: 3,
        incubationId: 'inc-1',
      );

      final captured = verify(() => mockRepo.save(captureAny())).captured;
      expect(captured.length, 2);
      final hatchEvent = captured.cast<Event>().firstWhere(
        (e) => e.type == EventType.hatching,
      );
      expect(hatchEvent.userId, 'user-1');
    });

    test(
      'generateEggEvents only saves lay event when hatch date is past',
      () async {
        final layDate = DateTime.now().subtract(const Duration(days: 200));

        await generator.generateEggEvents(
          userId: 'user-1',
          layDate: layDate,
          eggNumber: 3,
          incubationId: 'inc-1',
        );

        verify(() => mockRepo.save(any())).called(1);
      },
    );

    test(
      'generateEggEvents computes the expected-hatch date via local field '
      'addition, keeping the calendar cell on the reminder day near a boundary',
      () async {
        // Lay "moment" late in the local day (23:50), anchored relative to
        // `now` so the test never goes stale. Field addition (day + N) is
        // DST-safe and lands on the same local day as the reminder; a raw
        // `layDate.add(Duration(days: N))` would risk a day-off around a DST
        // transition, and a UTC-midnight instant would mis-bucket a day earlier
        // in UTC-negative zones.
        final anchor = DateTime.now().add(const Duration(days: 10));
        final layDate = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
          23,
          50,
        );
        final expectedHatch = DateTime(
          layDate.year,
          layDate.month,
          layDate.day + incubationDaysForSpecies(Species.budgie),
        );

        await generator.generateEggEvents(
          userId: 'user-1',
          layDate: layDate,
          eggNumber: 1,
          incubationId: 'inc-1',
          species: Species.budgie,
        );

        final captured = verify(() => mockRepo.save(captureAny())).captured;
        final hatchEvent = captured.cast<Event>().firstWhere(
          (e) => e.type == EventType.hatching,
        );
        expect(hatchEvent.eventDate, expectedHatch);
      },
    );

    test('generateChickEvents creates 3 future milestone events', () async {
      final hatchDate = DateTime.now().add(const Duration(days: 1));

      await generator.generateChickEvents(
        userId: 'user-1',
        hatchDate: hatchDate,
        chickLabel: 'Chick A',
      );

      final captured =
          verify(() => mockRepo.saveAll(captureAny())).captured.single
              as List<dynamic>;
      expect(captured.length, 3);
    });
  });
}
