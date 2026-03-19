import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockEventRepository repo;

  setUp(() {
    repo = MockEventRepository();
    registerFallbackValue(
      Event(
        id: '',
        title: '',
        eventDate: DateTime(2024),
        type: EventType.unknown,
        userId: '',
      ),
    );
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [eventRepositoryProvider.overrideWithValue(repo)],
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
