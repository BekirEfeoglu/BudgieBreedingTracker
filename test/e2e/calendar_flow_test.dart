@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_generator.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Calendar Flow E2E', () {
    test(
      'GIVEN calendar module WHEN month data is generated THEN monthly event set includes breeding/incubation milestones',
      () async {
        final mockEventRepository = MockEventRepository();
        when(() => mockEventRepository.save(any())).thenAnswer((_) async {});

        final generator = CalendarEventGenerator(mockEventRepository);
        await generator.generateIncubationEvents(
          userId: 'test-user',
          breedingPairId: 'pair-1',
          startDate: DateTime.now().add(const Duration(days: 1)),
          pairLabel: 'B2',
        );

        final saved = verify(
          () => mockEventRepository.save(captureAny()),
        ).captured.cast<Event>();
        expect(saved, isNotEmpty);
        expect(
          saved.every((event) => event.type == EventType.breeding),
          isTrue,
        );
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN calendar screen WHEN manual event is added THEN event repository persists the event',
      () async {
        final mockEventRepository = MockEventRepository();
        when(() => mockEventRepository.save(any())).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepository),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(eventFormStateProvider.notifier)
            .createEvent(
              userId: 'test-user',
              title: 'Veteriner randevusu',
              eventDate: DateTime.now().add(const Duration(days: 2)),
              type: EventType.health,
            );

        final event =
            verify(() => mockEventRepository.save(captureAny())).captured.single
                as Event;
        expect(event.title, 'Veteriner randevusu');
        expect(event.type, EventType.health);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN active breeding and eggs WHEN automatic event generation runs THEN hatch and weaning milestones are created',
      () async {
        final mockEventRepository = MockEventRepository();
        when(() => mockEventRepository.save(any())).thenAnswer((_) async {});

        final generator = CalendarEventGenerator(mockEventRepository);
        final layDate = DateTime.now().add(const Duration(days: 1));

        await generator.generateEggEvents(
          userId: 'test-user',
          layDate: layDate,
          eggNumber: 1,
          incubationId: 'inc-1',
        );
        await generator.generateChickEvents(
          userId: 'test-user',
          hatchDate: layDate.add(const Duration(days: 18)),
          chickLabel: 'Yavru 1',
        );

        final generated = verify(
          () => mockEventRepository.save(captureAny()),
        ).captured.cast<Event>();
        expect(
          generated.any((event) => event.type == EventType.hatching),
          isTrue,
        );
        expect(generated.any((event) => event.type == EventType.chick), isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN existing event entry WHEN deep link payload is resolved THEN related route is available for navigation',
      () {
        final eggRoute = NotificationService.payloadToRoute(
          'egg_turning:inc-1',
        );
        final chickRoute = NotificationService.payloadToRoute('chick:chick-1');

        expect(eggRoute, '/breeding/inc-1/eggs');
        expect(chickRoute, '/chicks/chick-1');
      },
      timeout: e2eTimeout,
    );
  });
}
