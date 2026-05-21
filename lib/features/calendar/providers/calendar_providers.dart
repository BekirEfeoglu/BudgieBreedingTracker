import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

/// Selected date on the calendar.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
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

/// Events for the current user (all events).
final eventsStreamProvider = StreamProvider.family<List<Event>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.watchAll(userId);
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

/// Events for the selected date.
final eventsForSelectedDateProvider = Provider<List<Event>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final eventsAsync = ref.watch(eventsStreamProvider(userId));
  final selectedDate = ref.watch(selectedDateProvider);
  final filter = ref.watch(calendarEventFilterProvider);

  final selectedDay = _localDateOnly(selectedDate);
  return eventsAsync.whenData((events) {
        return filterCalendarEvents(events, filter).where((e) {
          return _localDateOnly(e.eventDate) == selectedDay;
        }).toList();
      }).value ??
      [];
});

/// Events grouped by day for a specific month (for calendar dots).
final eventsForMonthProvider =
    Provider.family<Map<DateTime, List<Event>>, DateTime>((ref, month) {
      final userId = ref.watch(currentUserIdProvider);
      final eventsAsync = ref.watch(eventsStreamProvider(userId));
      final filter = ref.watch(calendarEventFilterProvider);

      final events = filterCalendarEvents(eventsAsync.value ?? [], filter);
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
}

final displayedMonthProvider =
    NotifierProvider<DisplayedMonthNotifier, DateTime>(
      DisplayedMonthNotifier.new,
    );

/// Events for the week containing the selected date.
final eventsForWeekProvider = Provider<Map<DateTime, List<Event>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final eventsAsync = ref.watch(eventsStreamProvider(userId));
  final selectedDate = ref.watch(selectedDateProvider);
  final filter = ref.watch(calendarEventFilterProvider);

  final events = filterCalendarEvents(eventsAsync.value ?? [], filter);
  // Get Monday of the selected date's week (ISO 8601: Monday=1).
  // Locale-aware firstDayOfWeek requires BuildContext; Monday-first is
  // correct for TR/DE locales. Future: add firstDayOfWeek provider.
  // We build week keys via DateTime year/month/day arithmetic to avoid
  // DST 23h/25h skew that `subtract`/`add(Duration(days:))` introduces.
  final selectedLocal = selectedDate.toLocal();
  final mondayY = selectedLocal.year;
  final mondayM = selectedLocal.month;
  final mondayD = selectedLocal.day - (selectedLocal.weekday - 1);

  final map = <DateTime, List<Event>>{};
  for (var i = 0; i < 7; i++) {
    final key = DateTime(mondayY, mondayM, mondayD + i);
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
// offline-first contract is maintained — the DAO stream ([watchAll])
// auto-emits updated data, no manual invalidation needed.
final eventRealtimeSyncProvider = Provider.family<void, String>((ref, userId) {
  if (userId == 'anonymous') return;

  final repo = ref.watch(eventRepositoryProvider);
  final channel = repo.subscribeToEvents(userId);

  ref.onDispose(() {
    repo.unsubscribeFromEvents(channel);
  });
});
