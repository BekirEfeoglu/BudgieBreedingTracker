import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

/// Selected date on the calendar.
///
/// Stored as a date-only (local midnight) `DateTime`. Storing a time-of-day
/// here makes equality comparisons in the grid/widgets ambiguous — sibling
/// providers (eventsForSelectedDateProvider) already normalize via
/// `_localDateOnly`, so make this provider the single source of truth and
/// drop time information at the write boundary as well.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Sets the selected date, dropping any time-of-day so equality checks
  /// against grid-computed `DateTime(y,m,d)` instances stay stable.
  void set(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

/// Calendar view mode.
enum CalendarViewMode { month, week, day }

enum CalendarEventFilter { all, incubation }

class CalendarEventFilterNotifier extends Notifier<CalendarEventFilter> {
  @override
  CalendarEventFilter build() => CalendarEventFilter.all;

  /// Sets the active event filter (mirrors [CalendarViewNotifier.setViewMode]).
  void setFilter(CalendarEventFilter filter) {
    state = filter;
  }
}

final calendarEventFilterProvider =
    NotifierProvider<CalendarEventFilterNotifier, CalendarEventFilter>(
      CalendarEventFilterNotifier.new,
    );

/// Current calendar view mode, persisted in SharedPreferences.
///
/// Uses [SharedPreferences] directly (same pattern as settings notifiers)
/// with [AppPreferences] key constants for consistency.
class CalendarViewNotifier extends Notifier<CalendarViewMode> {
  bool _hasLoadedFromPrefs = false;

  @override
  CalendarViewMode build() {
    _loadFromPrefs();
    return CalendarViewMode.month;
  }

  Future<void> _loadFromPrefs() async {
    if (_hasLoadedFromPrefs) return;
    _hasLoadedFromPrefs = true;
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppPreferences.keyCalendarViewMode);
    if (value != null && ref.mounted) {
      state = switch (value) {
        'week' => CalendarViewMode.week,
        'day' => CalendarViewMode.day,
        _ => CalendarViewMode.month,
      };
    }
  }

  Future<void> setViewMode(CalendarViewMode mode) async {
    _hasLoadedFromPrefs = true;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPreferences.keyCalendarViewMode, mode.name);
  }
}

final calendarViewProvider =
    NotifierProvider<CalendarViewNotifier, CalendarViewMode>(
      CalendarViewNotifier.new,
    );

typedef CalendarQueryRange = ({DateTime startInclusive, DateTime endExclusive});

/// Visible local-calendar period converted to half-open UTC query bounds.
///
/// A half-open range avoids end-of-day precision bugs and makes adjacent
/// periods meet without overlapping.
final visibleCalendarRangeProvider = Provider<CalendarQueryRange>((ref) {
  final viewMode = ref.watch(calendarViewProvider);
  late final DateTime localStart;
  late final DateTime localEnd;

  switch (viewMode) {
    case CalendarViewMode.month:
      final month = ref.watch(displayedMonthProvider);
      localStart = DateTime(month.year, month.month);
      localEnd = DateTime(month.year, month.month + 1);
    case CalendarViewMode.week:
      final monday = ref.watch(_weekStartProvider);
      localStart = monday;
      localEnd = DateTime(monday.year, monday.month, monday.day + 7);
    case CalendarViewMode.day:
      final selected = ref.watch(selectedDateProvider);
      localStart = DateTime(selected.year, selected.month, selected.day);
      localEnd = DateTime(selected.year, selected.month, selected.day + 1);
  }

  return (startInclusive: localStart.toUtc(), endExclusive: localEnd.toUtc());
});

/// Events for the current user's visible calendar period.
final eventsStreamProvider = StreamProvider.family<List<Event>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(eventRepositoryProvider);
  final range = ref.watch(visibleCalendarRangeProvider);
  return repo.watchByDateRange(
    userId,
    range.startInclusive,
    range.endExclusive,
  );
});

/// Normalizes a (possibly UTC) [DateTime] to the local-calendar day.
///
/// `DateUtils.dateOnly` keeps the original timezone, so a UTC event at
/// 23:30Z would land on the wrong local day for positive-offset timezones.
/// Converting to local first ensures the user-facing calendar grouping
/// matches what they actually see on the clock.
DateTime _localDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Single source of truth for filter application — month/week/day views all
/// derive from this so the O(n) filter pass runs once per (stream, filter)
/// change instead of once per view provider.
final filteredCalendarEventsProvider = Provider<List<Event>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final eventsAsync = ref.watch(eventsStreamProvider(userId));
  final filter = ref.watch(calendarEventFilterProvider);
  return filterCalendarEvents(eventsAsync.value ?? [], filter);
});

/// Events for the selected date.
final eventsForSelectedDateProvider = Provider<List<Event>>((ref) {
  final events = ref.watch(filteredCalendarEventsProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  final selectedDay = _localDateOnly(selectedDate);
  return events.where((e) {
    return _localDateOnly(e.eventDate) == selectedDay;
  }).toList();
});

/// Events grouped by day for a specific month (for calendar dots).
final eventsForMonthProvider =
    Provider.family<Map<DateTime, List<Event>>, DateTime>((ref, month) {
      final events = ref.watch(filteredCalendarEventsProvider);

      final map = <DateTime, List<Event>>{};
      for (final event in events) {
        final local = event.eventDate.toLocal();
        if (local.month == month.month && local.year == month.year) {
          final key = DateTime(local.year, local.month, local.day);
          map.putIfAbsent(key, () => []).add(event);
        }
      }
      return map;
    });

/// Currently displayed month on the calendar.
class DisplayedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Displays [month] and keeps the selected day inside that month.
  ///
  /// When no explicit [selectedDate] is supplied, the previous day-of-month
  /// is retained and clamped (for example, January 31 -> February 28/29).
  void show(DateTime month, {DateTime? selectedDate}) {
    final normalizedMonth = DateTime(month.year, month.month);
    final DateTime currentSelection =
        selectedDate ?? ref.read(selectedDateProvider);
    final lastDay = DateTime(
      normalizedMonth.year,
      normalizedMonth.month + 1,
      0,
    ).day;
    final targetDay = currentSelection.day <= lastDay
        ? currentSelection.day
        : lastDay;

    state = normalizedMonth;
    ref
        .read(selectedDateProvider.notifier)
        .set(DateTime(normalizedMonth.year, normalizedMonth.month, targetDay));
  }

  void changeBy(int monthDelta) {
    show(DateTime(state.year, state.month + monthDelta));
  }
}

final displayedMonthProvider =
    NotifierProvider<DisplayedMonthNotifier, DateTime>(
      DisplayedMonthNotifier.new,
    );

/// Monday (local date-only) of the week containing the selected date.
///
/// Derived separately so [eventsForWeekProvider] only recomputes when the
/// week actually changes — selecting another day in the *same* week yields
/// an equal [DateTime] here, so Riverpod skips the downstream grouping.
///
/// Get Monday of the selected date's week (ISO 8601: Monday=1). Locale-aware
/// firstDayOfWeek requires BuildContext; Monday-first is correct for TR/DE
/// locales. We build the date via DateTime year/month/day arithmetic to avoid
/// DST 23h/25h skew that `subtract`/`add(Duration(days:))` introduces.
final _weekStartProvider = Provider<DateTime>((ref) {
  final selectedLocal = ref.watch(selectedDateProvider).toLocal();
  return DateTime(
    selectedLocal.year,
    selectedLocal.month,
    selectedLocal.day - (selectedLocal.weekday - 1),
  );
});

/// Events for the week containing the selected date.
final eventsForWeekProvider = Provider<Map<DateTime, List<Event>>>((ref) {
  final events = ref.watch(filteredCalendarEventsProvider);
  final monday = ref.watch(_weekStartProvider);

  final map = <DateTime, List<Event>>{};
  for (var i = 0; i < 7; i++) {
    final key = DateTime(monday.year, monday.month, monday.day + i);
    map[key] = events.where((e) {
      return _localDateOnly(e.eventDate) == key;
    }).toList();
  }
  return map;
});

bool isIncubationCalendarEvent(Event event) {
  return switch (event.type) {
    EventType.breeding ||
    EventType.mating ||
    EventType.egg ||
    EventType.eggLaying ||
    EventType.hatching ||
    EventType.chick => true,
    EventType.unknown ||
    EventType.custom ||
    EventType.health ||
    EventType.feeding ||
    EventType.cleaning ||
    EventType.healthCheck ||
    EventType.medication ||
    EventType.vaccination ||
    EventType.weightCheck ||
    EventType.cageChange ||
    EventType.banding ||
    EventType.other => false,
  };
}

List<Event> filterCalendarEvents(
  List<Event> events,
  CalendarEventFilter filter,
) {
  return switch (filter) {
    CalendarEventFilter.all => events,
    CalendarEventFilter.incubation =>
      events.where(isIncubationCalendarEvent).toList(growable: false),
  };
}

// Realtime subscription for cross-device event updates.
// Routes changes through the local Drift DB via the repository so the
// offline-first contract is maintained — the visible-range DAO stream
// auto-emits updated data, no manual invalidation needed.
final eventRealtimeSyncProvider = Provider.family<void, String>((ref, userId) {
  if (userId == 'anonymous') return;

  final repo = ref.watch(eventRepositoryProvider);
  final channel = repo.subscribeToEvents(userId);

  ref.onDispose(() {
    repo.unsubscribeFromEvents(channel);
  });
});
