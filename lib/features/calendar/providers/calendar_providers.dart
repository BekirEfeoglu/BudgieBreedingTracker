import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppPreferences.keyCalendarViewMode);
    if (value != null && !_hasLoadedFromPrefs) {
      _hasLoadedFromPrefs = true;
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

/// Events for the selected date.
final eventsForSelectedDateProvider = Provider<List<Event>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final eventsAsync = ref.watch(eventsStreamProvider(userId));
  final selectedDate = ref.watch(selectedDateProvider);

  return eventsAsync.whenData((events) {
        return events.where((e) {
          final eventDate = e.eventDate;
          return eventDate.year == selectedDate.year &&
              eventDate.month == selectedDate.month &&
              eventDate.day == selectedDate.day;
        }).toList();
      }).value ??
      [];
});

/// Events grouped by day for a specific month (for calendar dots).
final eventsForMonthProvider =
    Provider.family<Map<DateTime, List<Event>>, DateTime>((ref, month) {
      final userId = ref.watch(currentUserIdProvider);
      final eventsAsync = ref.watch(eventsStreamProvider(userId));

      final events = eventsAsync.value ?? [];
      final map = <DateTime, List<Event>>{};
      for (final event in events) {
        final d = event.eventDate;
        if (d.month == month.month && d.year == month.year) {
          final key = DateTime(d.year, d.month, d.day);
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

  final events = eventsAsync.value ?? [];
  // Get Monday of the selected date's week
  final monday = selectedDate.subtract(
    Duration(days: (selectedDate.weekday - 1)),
  );

  final map = <DateTime, List<Event>>{};
  for (var i = 0; i < 7; i++) {
    final day = monday.add(Duration(days: i));
    final key = DateTime(day.year, day.month, day.day);
    map[key] = events.where((e) {
      final d = e.eventDate;
      return d.year == key.year && d.month == key.month && d.day == key.day;
    }).toList();
  }
  return map;
});

