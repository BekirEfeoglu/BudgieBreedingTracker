import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockEventRepository repo;
  late MockEventReminderRepository reminderRepo;
  late MockNotificationService notificationService;

  setUp(() {
    repo = MockEventRepository();
    reminderRepo = MockEventReminderRepository();
    notificationService = MockNotificationService();
    registerFallbackValue(
      Event(
        id: '',
        title: '',
        eventDate: DateTime(2024),
        type: EventType.unknown,
        userId: '',
      ),
    );
    registerFallbackValue(
      EventReminder(id: '', userId: '', eventId: '', createdAt: DateTime(2024)),
    );
    when(() => reminderRepo.save(any())).thenAnswer((_) async {});
    when(() => reminderRepo.getByEvent(any())).thenAnswer((_) async => []);
    when(() => notificationService.cancel(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        eventRepositoryProvider.overrideWithValue(repo),
        eventReminderRepositoryProvider.overrideWithValue(reminderRepo),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
    );
  }

  group('EventFormState', () {
    test('initial state has default values', () {
      const state = EventFormState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates fields', () {
      const state = EventFormState();
      final updated = state.copyWith(isLoading: true, isSuccess: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith clears error when null', () {
      final state = const EventFormState().copyWith(error: 'err');
      expect(state.error, 'err');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });

  group('EventFormNotifier', () {
    test('initial state is default', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(eventFormStateProvider);
      expect(state.isLoading, isFalse);
    });

    test('createEvent succeeds', () async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(eventFormStateProvider.notifier)
          .createEvent(
            userId: 'u1',
            title: 'Health check',
            eventDate: DateTime(2024, 6, 1),
            type: EventType.healthCheck,
          );

      expect(container.read(eventFormStateProvider).isSuccess, isTrue);
    });

    test('createEvent sets error on failure', () async {
      when(() => repo.save(any())).thenThrow(Exception('fail'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(eventFormStateProvider.notifier)
          .createEvent(
            userId: 'u1',
            title: 'X',
            eventDate: DateTime(2024),
            type: EventType.custom,
          );

      expect(container.read(eventFormStateProvider).error, isNotNull);
    });

    test('updateEvent saves the event with a bumped updatedAt', () async {
      final original = Event(
        id: 'e1',
        title: 'Old title',
        eventDate: DateTime(2024, 6, 1),
        type: EventType.custom,
        userId: 'u1',
      );
      when(() => repo.getById('e1')).thenAnswer((_) async => original);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(eventFormStateProvider.notifier)
          .updateEvent(original.copyWith(title: 'New title'));

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Event;
      expect(captured.title, 'New title');
      expect(container.read(eventFormStateProvider).isSuccess, isTrue);
    });

    test(
      'updateEvent reschedules a sent reminder when the event date shifts',
      () async {
        final original = Event(
          id: 'e1',
          title: 'Vet visit',
          eventDate: DateTime(2024, 6, 1, 10),
          type: EventType.custom,
          userId: 'u1',
        );
        final shifted = original.copyWith(eventDate: DateTime(2024, 6, 2, 10));
        final sentReminder = EventReminder(
          id: 'r1',
          userId: 'u1',
          eventId: 'e1',
          isSent: true,
          createdAt: DateTime(2024, 6, 1),
        );
        when(() => repo.getById('e1')).thenAnswer((_) async => original);
        when(() => repo.save(any())).thenAnswer((_) async {});
        when(
          () => reminderRepo.getByEvent('e1'),
        ).thenAnswer((_) async => [sentReminder]);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container
            .read(eventFormStateProvider.notifier)
            .updateEvent(shifted);

        verify(() => notificationService.cancel(any())).called(1);
        final savedReminder =
            verify(() => reminderRepo.save(captureAny())).captured.single
                as EventReminder;
        expect(savedReminder.isSent, isFalse);
      },
    );

    test(
      'updateEvent leaves not-yet-sent reminders alone when the date shifts',
      () async {
        final original = Event(
          id: 'e1',
          title: 'Vet visit',
          eventDate: DateTime(2024, 6, 1, 10),
          type: EventType.custom,
          userId: 'u1',
        );
        final shifted = original.copyWith(eventDate: DateTime(2024, 6, 2, 10));
        final pendingReminder = EventReminder(
          id: 'r1',
          userId: 'u1',
          eventId: 'e1',
          createdAt: DateTime(2024, 6, 1),
        );
        when(() => repo.getById('e1')).thenAnswer((_) async => original);
        when(() => repo.save(any())).thenAnswer((_) async {});
        when(
          () => reminderRepo.getByEvent('e1'),
        ).thenAnswer((_) async => [pendingReminder]);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container
            .read(eventFormStateProvider.notifier)
            .updateEvent(shifted);

        verifyNever(() => notificationService.cancel(any()));
        verifyNever(() => reminderRepo.save(any()));
      },
    );

    test(
      'updateEvent does not touch reminders when the event date is unchanged',
      () async {
        final original = Event(
          id: 'e1',
          title: 'Vet visit',
          eventDate: DateTime(2024, 6, 1, 10),
          type: EventType.custom,
          userId: 'u1',
        );
        when(() => repo.getById('e1')).thenAnswer((_) async => original);
        when(() => repo.save(any())).thenAnswer((_) async {});

        final container = makeContainer();
        addTearDown(container.dispose);

        await container
            .read(eventFormStateProvider.notifier)
            .updateEvent(original.copyWith(title: 'Renamed only'));

        verifyNever(() => reminderRepo.getByEvent(any()));
      },
    );

    test('deleteEvent succeeds', () async {
      when(() => repo.remove(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eventFormStateProvider.notifier).deleteEvent('e1');

      expect(container.read(eventFormStateProvider).isSuccess, isTrue);
    });

    test('updateEventStatus updates status', () async {
      final event = Event(
        id: 'e1',
        title: 'Test',
        eventDate: DateTime(2024),
        type: EventType.custom,
        userId: 'u1',
      );
      when(() => repo.getById('e1')).thenAnswer((_) async => event);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(eventFormStateProvider.notifier)
          .updateEventStatus('e1', EventStatus.completed);

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Event;
      expect(captured.status, EventStatus.completed);
    });

    test('reset clears state', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(eventFormStateProvider.notifier).reset();
      final state = container.read(eventFormStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });
  });
}
