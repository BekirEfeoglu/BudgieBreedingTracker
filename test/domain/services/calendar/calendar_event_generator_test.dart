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
      'generateIncubationEvents normalizes to UTC midnight before adding '
      'day offsets, so a start time near local midnight/DST-transition '
      'hours never drifts the milestone onto the wrong calendar day',
      () async {
        // A start "moment" late in the local day (23:50) is the case where
        // naive `startDate.add(Duration(days: N))` wall-clock math is most
        // likely to disagree with UTC-midnight-normalized math — DST
        // transitions and UTC offset conversions both pivot around day
        // boundaries. Anchored relative to `now` so this test never goes
        // stale.
        final anchor = DateTime.now().add(const Duration(days: 10));
        final startDate = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
          23,
          50,
        );
        final milestones = incubationMilestonesForSpecies(Species.unknown);
        final base = DateTime.utc(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final futureDays = [
          milestones.candlingDay,
          milestones.secondCheckDay,
          milestones.sensitivePeriodDay,
          milestones.expectedHatchDay,
          milestones.lateHatchDay,
        ].where((day) => !base.add(Duration(days: day)).isBefore(DateTime.now()));

        await generator.generateIncubationEvents(
          userId: 'user-1',
          breedingPairId: 'pair-1',
          startDate: startDate,
          pairLabel: 'Pair A',
        );

        final captured =
            verify(() => mockRepo.saveAll(captureAny())).captured.single
                as List<Event>;
        final expectedDates = futureDays
            .map((day) => base.add(Duration(days: day)))
            .toSet();
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
      'generateEggEvents computes the expected-hatch date via UTC-midnight '
      'normalization, not local wall-clock math near a day boundary',
      () async {
        // Lay "moment" late in the local day (23:50), anchored relative to
        // `now` so the test never goes stale. If the production code ever
        // regressed to `layDate.add(Duration(days: N))` on the raw
        // (non-UTC-normalized) layDate, this time-of-day would risk landing
        // the hatch date a day off around a DST transition.
        final anchor = DateTime.now().add(const Duration(days: 10));
        final layDate = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
          23,
          50,
        );
        final expectedHatch = DateTime.utc(
          layDate.year,
          layDate.month,
          layDate.day,
        ).add(Duration(days: incubationDaysForSpecies(Species.budgie)));

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
