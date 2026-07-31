import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_providers.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/mocks.dart';

Event _event({
  required String id,
  required DateTime eventDate,
  String title = 'Test Event',
  EventType type = EventType.custom,
}) {
  return Event(
    id: id,
    title: title,
    eventDate: eventDate,
    type: type,
    userId: 'user-1',
  );
}

void _stubVisibleEventStream(
  MockEventRepository repository,
  Stream<List<Event>> stream,
) {
  when(
    () => repository.watchByDateRange('user-1', any(), any()),
  ).thenAnswer((_) => stream);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime.utc(2025));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SelectedDateNotifier', () {
    test('default is today', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Bracket the provider read so a midnight rollover between the provider's
      // internal DateTime.now() and the test's cannot flake the assertion: the
      // provider's now is between `before` and `after`, so its calendar day is
      // one of those two ends.
      final before = DateTime.now();
      final date = container.read(selectedDateProvider);
      final after = DateTime.now();

      DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
      expect(dayOf(date), anyOf(equals(dayOf(before)), equals(dayOf(after))));
    });

    test('can change selected date', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedDateProvider.notifier).state = DateTime(
        2025,
        6,
        15,
      );
      expect(container.read(selectedDateProvider), DateTime(2025, 6, 15));
    });

    test('can set different month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedDateProvider.notifier).state = DateTime(
        2025,
        12,
        25,
      );
      final date = container.read(selectedDateProvider);
      expect(date.month, 12);
      expect(date.day, 25);
    });
  });

  group('DisplayedMonthNotifier', () {
    test('default is current month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final month = container.read(displayedMonthProvider);
      final now = DateTime.now();
      expect(month.year, now.year);
      expect(month.month, now.month);
      expect(month.day, 1);
    });

    test('can navigate to a specific month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(displayedMonthProvider.notifier).state = DateTime(2025, 7);
      expect(container.read(displayedMonthProvider), DateTime(2025, 7));
    });

    test('can navigate backward to previous month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(displayedMonthProvider.notifier).state = DateTime(2025, 1);
      expect(container.read(displayedMonthProvider).month, 1);
    });
  });

  group('CalendarViewNotifier', () {
    test('default view is month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(calendarViewProvider), CalendarViewMode.month);
    });

    test('can change to week view', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(calendarViewProvider.notifier).state =
          CalendarViewMode.week;
      expect(container.read(calendarViewProvider), CalendarViewMode.week);
    });

    test('can change to day view', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(calendarViewProvider.notifier).state =
          CalendarViewMode.day;
      expect(container.read(calendarViewProvider), CalendarViewMode.day);
    });
  });

  group('visibleCalendarRangeProvider', () {
    test('uses half-open month, week, and day bounds in UTC', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(displayedMonthProvider.notifier).state = DateTime(2025, 3);
      container.read(selectedDateProvider.notifier).set(DateTime(2025, 3, 12));

      container.read(calendarViewProvider.notifier).state =
          CalendarViewMode.month;
      expect(container.read(visibleCalendarRangeProvider), (
        startInclusive: DateTime(2025, 3).toUtc(),
        endExclusive: DateTime(2025, 4).toUtc(),
      ));

      container.read(calendarViewProvider.notifier).state =
          CalendarViewMode.week;
      expect(container.read(visibleCalendarRangeProvider), (
        startInclusive: DateTime(2025, 3, 10).toUtc(),
        endExclusive: DateTime(2025, 3, 17).toUtc(),
      ));

      container.read(calendarViewProvider.notifier).state =
          CalendarViewMode.day;
      expect(container.read(visibleCalendarRangeProvider), (
        startInclusive: DateTime(2025, 3, 12).toUtc(),
        endExclusive: DateTime(2025, 3, 13).toUtc(),
      ));
    });
  });

  group('eventsStreamProvider', () {
    late MockEventRepository mockEventRepo;

    setUp(() {
      mockEventRepo = MockEventRepository();
    });

    test('delegates the visible range to the repository', () async {
      final event = _event(id: 'evt-1', eventDate: DateTime(2025, 3, 10));
      _stubVisibleEventStream(mockEventRepo, Stream.value([event]));

      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockEventRepo)],
      );
      addTearDown(container.dispose);

      container.read(displayedMonthProvider.notifier).state = DateTime(2025, 3);
      container.listen(eventsStreamProvider('user-1'), (_, __) {});
      final result = await container.read(
        eventsStreamProvider('user-1').future,
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'evt-1');

      verify(
        () => mockEventRepo.watchByDateRange(
          'user-1',
          DateTime(2025, 3).toUtc(),
          DateTime(2025, 4).toUtc(),
        ),
      ).called(1);
    });

    test('returns empty list when no events', () async {
      _stubVisibleEventStream(mockEventRepo, Stream.value([]));

      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockEventRepo)],
      );
      addTearDown(container.dispose);

      container.listen(eventsStreamProvider('user-1'), (_, __) {});
      final result = await container.read(
        eventsStreamProvider('user-1').future,
      );
      expect(result, isEmpty);
    });

    test('returns multiple events from stream', () async {
      final events = [
        _event(id: 'e1', eventDate: DateTime(2025, 3, 10)),
        _event(id: 'e2', eventDate: DateTime(2025, 3, 11)),
        _event(id: 'e3', eventDate: DateTime(2025, 3, 12)),
      ];
      _stubVisibleEventStream(mockEventRepo, Stream.value(events));

      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockEventRepo)],
      );
      addTearDown(container.dispose);

      container.listen(eventsStreamProvider('user-1'), (_, __) {});
      final result = await container.read(
        eventsStreamProvider('user-1').future,
      );
      expect(result, hasLength(3));
    });
  });

  group('eventsForSelectedDateProvider', () {
    late MockEventRepository mockEventRepo;

    setUp(() {
      mockEventRepo = MockEventRepository();
    });

    test('returns events matching the selected date', () async {
      final targetDate = DateTime(2025, 6, 15);
      final matching = _event(
        id: 'evt-1',
        eventDate: DateTime(2025, 6, 15, 10, 30),
      );
      final nonMatching = _event(id: 'evt-2', eventDate: DateTime(2025, 6, 16));

      _stubVisibleEventStream(
        mockEventRepo,
        Stream.value([matching, nonMatching]),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(eventsStreamProvider('user-1'), (_, __) {});
      container.read(selectedDateProvider.notifier).state = targetDate;
      // Wait for the stream to emit and derived provider to update
      await container.read(eventsStreamProvider('user-1').future);
      await Future<void>.microtask(() {});

      final result = container.read(eventsForSelectedDateProvider);
      expect(result, hasLength(1));
      expect(result.first.id, 'evt-1');
    });

    test('returns empty list when no events match the selected date', () async {
      _stubVisibleEventStream(mockEventRepo, Stream.value([]));

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
        ],
      );
      addTearDown(container.dispose);

      container.read(selectedDateProvider.notifier).state = DateTime(
        2025,
        6,
        15,
      );
      await Future<void>.microtask(() {});

      final result = container.read(eventsForSelectedDateProvider);
      expect(result, isEmpty);
    });

    test('returns empty list before stream emits', () {
      _stubVisibleEventStream(mockEventRepo, const Stream.empty());

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
        ],
      );
      addTearDown(container.dispose);

      // Provider returns empty list while loading (before stream emits)
      final result = container.read(eventsForSelectedDateProvider);
      expect(result, isEmpty);
    });

    test('filters selected date to incubation events when enabled', () async {
      final targetDate = DateTime(2025, 6, 15);
      final breeding = _event(
        id: 'breeding',
        eventDate: targetDate,
        type: EventType.breeding,
      );
      final egg = _event(id: 'egg', eventDate: targetDate, type: EventType.egg);
      final health = _event(
        id: 'health',
        eventDate: targetDate,
        type: EventType.health,
      );
      final custom = _event(
        id: 'custom',
        eventDate: targetDate,
        type: EventType.custom,
      );

      _stubVisibleEventStream(
        mockEventRepo,
        Stream.value([breeding, egg, health, custom]),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
        ],
      );
      addTearDown(container.dispose);

      container.read(selectedDateProvider.notifier).state = targetDate;
      container.read(calendarEventFilterProvider.notifier).state =
          CalendarEventFilter.incubation;
      container.listen(eventsStreamProvider('user-1'), (_, __) {});
      await container.read(eventsStreamProvider('user-1').future);
      await Future<void>.microtask(() {});

      final result = container.read(eventsForSelectedDateProvider);
      expect(result.map((event) => event.id), ['breeding', 'egg']);
    });
  });

  group('filteredCalendarEventsProvider', () {
    late MockEventRepository mockEventRepo;

    setUp(() {
      mockEventRepo = MockEventRepository();
    });

    test('returns all events under CalendarEventFilter.all', () async {
      final breeding = _event(
        id: 'breeding',
        eventDate: DateTime(2025, 6, 15),
        type: EventType.breeding,
      );
      final custom = _event(
        id: 'custom',
        eventDate: DateTime(2025, 6, 16),
        type: EventType.custom,
      );

      _stubVisibleEventStream(mockEventRepo, Stream.value([breeding, custom]));

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(eventsStreamProvider('user-1'), (_, __) {});
      await container.read(eventsStreamProvider('user-1').future);
      await Future<void>.microtask(() {});

      final result = container.read(filteredCalendarEventsProvider);
      expect(result.map((event) => event.id), ['breeding', 'custom']);
    });

    test(
      'returns only incubation events after switching to CalendarEventFilter.incubation',
      () async {
        final breeding = _event(
          id: 'breeding',
          eventDate: DateTime(2025, 6, 15),
          type: EventType.breeding,
        );
        final custom = _event(
          id: 'custom',
          eventDate: DateTime(2025, 6, 16),
          type: EventType.custom,
        );

        _stubVisibleEventStream(
          mockEventRepo,
          Stream.value([breeding, custom]),
        );

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
          ],
        );
        addTearDown(container.dispose);

        container.listen(eventsStreamProvider('user-1'), (_, __) {});
        await container.read(eventsStreamProvider('user-1').future);
        await Future<void>.microtask(() {});

        container
            .read(calendarEventFilterProvider.notifier)
            .setFilter(CalendarEventFilter.incubation);

        final result = container.read(filteredCalendarEventsProvider);
        expect(result.map((event) => event.id), ['breeding']);
      },
    );

    test(
      'eventsForMonthProvider derives from the shared filtered source',
      () async {
        final month = DateTime(2025, 6);
        final breeding = _event(
          id: 'breeding',
          eventDate: DateTime(2025, 6, 15),
          type: EventType.breeding,
        );
        final custom = _event(
          id: 'custom',
          eventDate: DateTime(2025, 6, 16),
          type: EventType.custom,
        );

        _stubVisibleEventStream(
          mockEventRepo,
          Stream.value([breeding, custom]),
        );

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
          ],
        );
        addTearDown(container.dispose);

        container.listen(eventsStreamProvider('user-1'), (_, __) {});
        await container.read(eventsStreamProvider('user-1').future);
        await Future<void>.microtask(() {});

        // Unfiltered: both events show up grouped by day.
        final unfiltered = container.read(eventsForMonthProvider(month));
        expect(
          unfiltered.values.expand((events) => events).map((e) => e.id).toSet(),
          {'breeding', 'custom'},
        );

        // After switching the shared filter, the month provider must reflect
        // it too — proving it reads from filteredCalendarEventsProvider
        // instead of re-filtering its own copy of the stream.
        container
            .read(calendarEventFilterProvider.notifier)
            .setFilter(CalendarEventFilter.incubation);

        final filtered = container.read(eventsForMonthProvider(month));
        expect(
          filtered.values.expand((events) => events).map((e) => e.id).toSet(),
          {'breeding'},
        );
      },
    );

    test(
      'eventsForSelectedDateProvider derives from the shared filtered source',
      () async {
        final targetDate = DateTime(2025, 6, 15);
        final breeding = _event(
          id: 'breeding',
          eventDate: targetDate,
          type: EventType.breeding,
        );
        final custom = _event(
          id: 'custom',
          eventDate: targetDate,
          type: EventType.custom,
        );

        _stubVisibleEventStream(
          mockEventRepo,
          Stream.value([breeding, custom]),
        );

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
          ],
        );
        addTearDown(container.dispose);

        container.read(selectedDateProvider.notifier).set(targetDate);
        container.listen(eventsStreamProvider('user-1'), (_, __) {});
        await container.read(eventsStreamProvider('user-1').future);
        await Future<void>.microtask(() {});

        final unfiltered = container.read(eventsForSelectedDateProvider);
        expect(unfiltered.map((e) => e.id).toSet(), {'breeding', 'custom'});

        container
            .read(calendarEventFilterProvider.notifier)
            .setFilter(CalendarEventFilter.incubation);

        final filtered = container.read(eventsForSelectedDateProvider);
        expect(filtered.map((e) => e.id).toSet(), {'breeding'});
      },
    );
  });
}
