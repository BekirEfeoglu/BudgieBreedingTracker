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
4. `inDays` without UTC midnight normalize (23:59 → 0 days)
5. UTC `DateTime` displayed directly (user expects local timezone)
6. `.toIso8601String()` without `.toUtc()` first

## See Also

- [[domain/notification-service]] — tz.TZDateTime usage
- [[data-layer/supabase]] — .toSupabase() UTC handling
- [[patterns/l10n]] — DateFormat locale
