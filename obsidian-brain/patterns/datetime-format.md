# Date & Time

Source: `.claude/rules/datetime-format.md`

**Rule**: Storage UTC · Display local · Math UTC

## Storage/Wire/Display

| Where | Format | Type |
|-------|--------|------|
| Drift DB | ISO-8601 UTC | `DateTime` with `.toUtc()` |
| Supabase | `timestamptz` UTC | JSON ISO-8601 string |
| Edge function | UTC | `new Date().toISOString()` |
| Notification schedule | `tz.TZDateTime` | timezone-aware |
| UI display | Local timezone | `DateFormat` + locale |
| Form input | Local | `showDatePicker` returns local |

## UTC at Boundary

```dart
// CORRECT
'hatch_date': bird.hatchDate.toUtc().toIso8601String()

// WRONG — local timezone leaks to server
'hatch_date': bird.hatchDate.toIso8601String()
```

`.toSupabase()` extension handles this automatically — never manually build JSON maps.

## Display Formatting

```dart
final locale = context.locale.toString();  // 'tr', 'en', 'de'
Text(DateFormat.yMMMd(locale).format(bird.hatchDate))  // "14 Mayıs 2026"
Text(DateFormat.Hm(locale).format(event.time))          // "14:30"
```

Never hardcode `DateFormat('dd.MM.yyyy')` — use locale-aware format.

## Incubation Day Math (Critical)

```dart
// CORRECT — normalize to UTC midnight before diff
int incubationDay(DateTime layDate, DateTime today) {
  final start = DateTime.utc(layDate.year, layDate.month, layDate.day);
  final now = DateTime.utc(today.year, today.month, today.day);
  return now.difference(start).inDays + 1;  // day 1 = lay day
}

// WRONG — inDays can be 0 at 23:59 across timezone boundaries
today.difference(layDate).inDays + 1
```

## DateUtils.dayDiff Helper (Canonical)

All day-count math goes through `lib/core/utils/date_utils.dart` → `DateUtils.dayDiff(start, end)`. UTC-midnight normalization built in.

```dart
// Import MUST be prefixed — Flutter material exports its own DateUtils
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart' as date_utils;

// CORRECT
final age = date_utils.DateUtils.dayDiff(bird.birthDate!, DateTime.now());

// WRONG — ambiguous_import, `flutter analyze` fails
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart';
DateUtils.dayDiff(...)
```

Mixing both `DateUtils` classes in one file: prefix the local one, leave Flutter's unprefixed (see `calendar_providers.dart`).

## Notification Scheduling

```dart
import 'package:timezone/timezone.dart' as tz;

final scheduled = tz.TZDateTime.from(targetDateTime, tz.local);
await notifications.zonedSchedule(id, title, body, scheduled, ...);
```

`tz.initializeTimeZones()` and `tz.setLocalLocation(...)` called in `main.dart`.

Naive `DateTime` for scheduling → timezone bug. **Always `tz.TZDateTime`.**

## Anti-Patterns

1. Naive `DateTime` for notification schedule (timezone bug)
2. Local timezone written to Supabase (multi-device sync breaks)
3. Hardcoded locale `DateFormat('dd.MM.yyyy')` (German format differs)
4. `inDays` without UTC midnight normalize (23:59 → 0 days) — use `date_utils.DateUtils.dayDiff(...)`
5. `DateUtils` imported without prefix (collides with Flutter material — `as date_utils` required)
6. UTC `DateTime` displayed directly (user expects local timezone)
7. `.toIso8601String()` without `.toUtc()` first

## See Also

- [[domain/notification-service]] — tz.TZDateTime usage
- [[data-layer/supabase]] — .toSupabase() UTC handling
- [[patterns/l10n]] — DateFormat locale
