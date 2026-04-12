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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SelectedDateNotifier', () {
    test('default is today', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final date = container.read(selectedDateProvider);
      final now = DateTime.now();
      expect(date.year, now.year);
      expect(date.month, now.month);
      expect(date.day, now.day);
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

  group('eventsStreamProvider', () {
    late MockEventRepository mockEventRepo;

    setUp(() {
      mockEventRepo = MockEventRepository();
    });

    test('delegates to repo.watchAll and returns events', () async {
      final event = _event(id: 'evt-1', eventDate: DateTime(2025, 3, 10));
      when(
        () => mockEventRepo.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value([event]));

      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockEventRepo)],
      );
      addTearDown(container.dispose);

      container.listen(eventsStreamProvider('user-1'), (_, __) {});
      final result = await container.read(
        eventsStreamProvider('user-1').future,
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'evt-1');
    });

    test('returns empty list when no events', () async {
      when(
        () => mockEventRepo.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value([]));

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
      when(
        () => mockEventRepo.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value(events));

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

      when(
        () => mockEventRepo.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value([matching, nonMatching]));

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
      when(
        () => mockEventRepo.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value([]));

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
      when(
        () => mockEventRepo.watchAll('user-1'),
      ).thenAnswer((_) => const Stream.empty());

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
  });
}
