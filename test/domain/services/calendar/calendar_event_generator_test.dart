import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_generator.dart';

class MockEventRepository extends Mock implements EventRepository {}

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
  });

  setUp(() {
    mockRepo = MockEventRepository();
    generator = CalendarEventGenerator(mockRepo);
    when(() => mockRepo.save(any())).thenAnswer((_) async {});
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

      verify(() => mockRepo.save(any())).called(5);
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

        verifyNever(() => mockRepo.save(any()));
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

    test('generateChickEvents creates 3 future milestone events', () async {
      final hatchDate = DateTime.now().add(const Duration(days: 1));

      await generator.generateChickEvents(
        userId: 'user-1',
        hatchDate: hatchDate,
        chickLabel: 'Chick A',
      );

      verify(() => mockRepo.save(any())).called(3);
    });
  });
}
