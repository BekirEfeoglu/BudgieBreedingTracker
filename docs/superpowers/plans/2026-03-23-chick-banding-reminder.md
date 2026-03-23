# Chick Banding Reminder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add configurable banding day reminders with push notifications and completion tracking for chicks.

**Architecture:** Extend existing Event + NotificationScheduler + CalendarEventGenerator chain. Add `bandingDay`/`bandingDate` fields to Chick model, `chickId` to Event model, new `scheduleBandingReminders()`/`cancelBandingReminders()` methods, and UI for marking banding complete from chick detail and calendar.

**Tech Stack:** Flutter/Dart, Drift (SQLite migration v15), Freezed 3, Riverpod 3, flutter_local_notifications, easy_localization

**Spec:** `docs/superpowers/specs/2026-03-23-chick-banding-reminder-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `lib/core/enums/event_enums.dart:1-28` | Add `banding` to EventType enum |
| Modify | `lib/data/models/chick_model.dart:12-35` | Add `bandingDay`, `bandingDate` fields |
| Modify | `lib/data/models/event_model.dart:10-28` | Add `chickId` field |
| Modify | `lib/data/local/database/tables/chicks_table.dart:6-23` | Add `bandingDay`, `bandingDate` columns |
| Modify | `lib/data/local/database/tables/events_table.dart:6-20` | Add `chickId` column |
| Modify | `lib/data/local/database/mappers/chick_mapper.dart:5-49` | Add bandingDay/bandingDate mapping |
| Modify | `lib/data/local/database/mappers/event_mapper.dart:5-43` | Add chickId mapping |
| Modify | `lib/data/local/database/app_database.dart:118,129-156` | Schema v15 migration |
| Modify | `lib/domain/services/notifications/notification_ids.dart:7-18` | Add `bandingBaseId = 500000` |
| Modify | `lib/domain/services/notifications/notification_toggle_settings.dart:7-62` | Add `banding` toggle |
| Modify | `lib/domain/services/notifications/notification_scheduler.dart:21-357` | Add `scheduleBandingReminders()` |
| Modify | `lib/domain/services/notifications/notification_scheduler_cancel.dart:9-112` | Add `cancelBandingReminders()` |
| Modify | `lib/domain/services/notifications/notification_service.dart:343-363` | Add `banding` payload routing |
| Modify | `lib/domain/services/calendar/calendar_event_generator.dart:127-166` | Add `chickId` + `bandingDay` params |
| Modify | `lib/features/chicks/providers/chick_form_providers.dart:36-278` | Wire banding to create/update/delete/deceased |
| Modify | `lib/features/chicks/providers/chick_providers.dart` | Add `markBandingComplete` provider action |
| Modify | `lib/features/chicks/screens/chick_form_screen.dart:32-353` | Add bandingDay form field |
| Modify | `lib/features/chicks/widgets/chick_detail_info.dart:16-155` | Add banding InfoCard |
| Modify | `lib/features/eggs/providers/egg_providers.dart:176-230` | Pass chickId/bandingDay to generator |
| Modify | `assets/translations/tr.json` | Add banding keys |
| Modify | `assets/translations/en.json` | Add banding keys |
| Modify | `assets/translations/de.json` | Add banding keys |
| Modify | `lib/features/calendar/widgets/` | Add "Tamamla" button for banding events |

**Supabase DDL (manual, not automated):** The remote Supabase `chicks` table needs `banding_day` (int4, default 10) and `banding_date` (timestamptz, nullable) columns. The `events` table needs `chick_id` (uuid, nullable, FK to chicks). These must be applied via Supabase dashboard or migration SQL before sync will work. Local development works without this (offline-first).

**Prerequisite check:** `AppIcons.ring` constant exists at `app_icons.dart:16` pointing to `assets/icons/birds/ring.svg`. Both `ChicksTable` and `EventsTable` are already registered in `@DriftDatabase(tables: [...])`.

---

## Task 1: EventType Enum — Add `banding` value

**Files:**
- Modify: `lib/core/enums/event_enums.dart:1-28`
- Test: `test/core/enums/event_enums_test.dart`

- [ ] **Step 1: Write test for EventType.banding serialization**

```dart
// test/core/enums/event_enums_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';

void main() {
  group('EventType', () {
    test('banding serializes to "banding"', () {
      expect(EventType.banding.toJson(), 'banding');
    });

    test('banding deserializes from "banding"', () {
      expect(EventType.fromJson('banding'), EventType.banding);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/enums/event_enums_test.dart -v`
Expected: Compilation error — `EventType.banding` does not exist

- [ ] **Step 3: Add `banding` to EventType enum**

In `lib/core/enums/event_enums.dart`, add `banding` before `other` (line 18):

```dart
  cageChange,
  banding,
  other;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/enums/event_enums_test.dart -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/enums/event_enums.dart test/core/enums/event_enums_test.dart
git commit -m "feat(enums): add banding to EventType enum"
```

---

## Task 2: Chick Model — Add `bandingDay` and `bandingDate` fields

**Files:**
- Modify: `lib/data/models/chick_model.dart:12-57`
- Test: `test/data/models/chick_model_test.dart`

- [ ] **Step 1: Write tests for new fields and computed properties**

```dart
// test/data/models/chick_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

void main() {
  group('Chick banding fields', () {
    test('bandingDay defaults to 10', () {
      final chick = Chick(id: '1', userId: 'u1');
      expect(chick.bandingDay, 10);
    });

    test('bandingDate defaults to null', () {
      final chick = Chick(id: '1', userId: 'u1');
      expect(chick.bandingDate, isNull);
    });

    test('isBanded returns false when bandingDate is null', () {
      final chick = Chick(id: '1', userId: 'u1');
      expect(chick.isBanded, false);
    });

    test('isBanded returns true when bandingDate is set', () {
      final chick = Chick(id: '1', userId: 'u1', bandingDate: DateTime(2026, 3, 20));
      expect(chick.isBanded, true);
    });

    test('plannedBandingDate calculates correctly', () {
      final chick = Chick(id: '1', userId: 'u1', hatchDate: DateTime(2026, 3, 10), bandingDay: 10);
      expect(chick.plannedBandingDate, DateTime(2026, 3, 20));
    });

    test('plannedBandingDate returns null when hatchDate is null', () {
      final chick = Chick(id: '1', userId: 'u1');
      expect(chick.plannedBandingDate, isNull);
    });

    test('bandingDay JSON round-trip', () {
      final chick = Chick(id: '1', userId: 'u1', bandingDay: 8);
      final json = chick.toJson();
      final restored = Chick.fromJson(json);
      expect(restored.bandingDay, 8);
    });

    test('bandingDate JSON round-trip', () {
      final date = DateTime(2026, 3, 20, 10, 30);
      final chick = Chick(id: '1', userId: 'u1', bandingDate: date);
      final json = chick.toJson();
      final restored = Chick.fromJson(json);
      expect(restored.bandingDate, date);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/chick_model_test.dart -v`
Expected: Compilation errors — `bandingDay`, `bandingDate`, `isBanded`, `plannedBandingDate` do not exist

- [ ] **Step 3: Add fields to Chick model and extension**

In `lib/data/models/chick_model.dart`, add after `ringNumber` (line 25):

```dart
    @Default(10) int bandingDay,
    DateTime? bandingDate,
```

Add computed properties to `ChickX` extension (after line 56):

```dart
  bool get isBanded => bandingDate != null;

  DateTime? get plannedBandingDate =>
      hatchDate != null ? hatchDate!.add(Duration(days: bandingDay)) : null;
```

- [ ] **Step 4: Run build_runner to regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/data/models/chick_model_test.dart -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/chick_model.dart test/data/models/chick_model_test.dart
git commit -m "feat(chick): add bandingDay and bandingDate fields to Chick model"
```

---

## Task 3: Event Model — Add `chickId` field

**Files:**
- Modify: `lib/data/models/event_model.dart:10-28`
- Test: `test/data/models/event_model_test.dart`

- [ ] **Step 1: Write test for chickId field**

```dart
// test/data/models/event_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';

void main() {
  group('Event chickId field', () {
    test('chickId defaults to null', () {
      final event = Event(id: '1', title: 'Test', eventDate: DateTime.now(), type: EventType.banding, userId: 'u1');
      expect(event.chickId, isNull);
    });

    test('chickId can be set', () {
      final event = Event(id: '1', title: 'Test', eventDate: DateTime.now(), type: EventType.banding, userId: 'u1', chickId: 'chick-1');
      expect(event.chickId, 'chick-1');
    });

    test('chickId JSON round-trip', () {
      final event = Event(id: '1', title: 'Test', eventDate: DateTime.now(), type: EventType.banding, userId: 'u1', chickId: 'chick-1');
      final json = event.toJson();
      final restored = Event.fromJson(json);
      expect(restored.chickId, 'chick-1');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/event_model_test.dart -v`
Expected: Compilation error — `chickId` not found

- [ ] **Step 3: Add chickId to Event model**

In `lib/data/models/event_model.dart`, add after `breedingPairId` (line 21):

```dart
    String? chickId,
```

- [ ] **Step 4: Run build_runner to regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/data/models/event_model_test.dart -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/event_model.dart test/data/models/event_model_test.dart
git commit -m "feat(event): add chickId field to Event model"
```

---

## Task 4: Drift Tables + Mappers — Add new columns

**Files:**
- Modify: `lib/data/local/database/tables/chicks_table.dart:6-23`
- Modify: `lib/data/local/database/tables/events_table.dart:6-20`
- Modify: `lib/data/local/database/mappers/chick_mapper.dart:5-49`
- Modify: `lib/data/local/database/mappers/event_mapper.dart:5-43`

- [ ] **Step 1: Add columns to ChicksTable**

In `lib/data/local/database/tables/chicks_table.dart`, add after `ringNumber` (line 14):

```dart
  IntColumn get bandingDay => integer().withDefault(const Constant(10))();
  DateTimeColumn get bandingDate => dateTime().nullable()();
```

- [ ] **Step 2: Add column to EventsTable**

In `lib/data/local/database/tables/events_table.dart`, add after `breedingPairId` (line 14):

```dart
  TextColumn get chickId => text().nullable()();
```

- [ ] **Step 3: Update chick mapper — toModel**

In `lib/data/local/database/mappers/chick_mapper.dart`, add inside `toModel()` after `ringNumber: ringNumber,` (line 15):

```dart
    bandingDay: bandingDay,
    bandingDate: bandingDate,
```

- [ ] **Step 4: Update chick mapper — toCompanion**

In `lib/data/local/database/mappers/chick_mapper.dart`, add inside `toCompanion()` after `ringNumber: Value(ringNumber),` (line 38):

```dart
    bandingDay: Value(bandingDay),
    bandingDate: Value(bandingDate),
```

- [ ] **Step 5: Update event mapper — toModel**

In `lib/data/local/database/mappers/event_mapper.dart`, add inside `toModel()` after `breedingPairId: breedingPairId,` (line 15):

```dart
    chickId: chickId,
```

- [ ] **Step 6: Update event mapper — toCompanion**

In `lib/data/local/database/mappers/event_mapper.dart`, add inside `toCompanion()` after `breedingPairId: Value(breedingPairId),` (line 35):

```dart
    chickId: Value(chickId),
```

- [ ] **Step 7: Run build_runner to regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 8: Run flutter analyze to verify**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors. Mapper correctness is validated by the model JSON round-trip tests in Tasks 2 and 3.

- [ ] **Step 9: Commit**

```bash
git add lib/data/local/database/tables/chicks_table.dart lib/data/local/database/tables/events_table.dart lib/data/local/database/mappers/chick_mapper.dart lib/data/local/database/mappers/event_mapper.dart
git commit -m "feat(database): add banding columns to chicks and events tables"
```

---

## Task 5: Database Migration v14 → v15

**Files:**
- Modify: `lib/data/local/database/app_database.dart:118,129-156`

- [ ] **Step 1: Increment schemaVersion to 15**

In `lib/data/local/database/app_database.dart`, change line 118:

```dart
  int get schemaVersion => 15;
```

- [ ] **Step 2: Add case 15 to migration switch**

After `case 14:` (line 155), add:

```dart
          case 15:
            await _migrateV14ToV15(m);
```

- [ ] **Step 3: Add migration helper method**

Add after the existing migration methods (find `_migrateV13ToV14` and add after it):

```dart
  Future<void> _migrateV14ToV15(Migrator m) async {
    // Add banding fields to chicks table
    await m.addColumn(chicksTable, chicksTable.bandingDay);
    await m.addColumn(chicksTable, chicksTable.bandingDate);

    // Add chickId to events table
    await m.addColumn(eventsTable, eventsTable.chickId);
  }
```

- [ ] **Step 4: Run build_runner to regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run flutter analyze to verify**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/data/local/database/app_database.dart
git commit -m "feat(database): add schema v15 migration for banding fields"
```

---

## Task 6: NotificationIds + ToggleSettings — Add banding constants

**Files:**
- Modify: `lib/domain/services/notifications/notification_ids.dart:7-18`
- Modify: `lib/domain/services/notifications/notification_toggle_settings.dart:7-62`
- Test: `test/domain/services/notifications/notification_ids_test.dart`

- [ ] **Step 1: Write test for banding notification ID generation**

```dart
// test/domain/services/notifications/notification_ids_test.dart — add to existing or create
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';

void main() {
  group('NotificationIds banding', () {
    test('bandingBaseId is 500000', () {
      expect(NotificationIds.bandingBaseId, 500000);
    });

    test('generates banding IDs within range', () {
      final id = NotificationIds.generate(NotificationIds.bandingBaseId, 'chick-123', 0);
      expect(id, greaterThanOrEqualTo(500000));
      expect(id, lessThan(600000));
    });

    test('generates 4 distinct offsets for one chick', () {
      final ids = List.generate(4, (i) => NotificationIds.generate(NotificationIds.bandingBaseId, 'chick-abc', i));
      expect(ids.toSet().length, 4);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/services/notifications/notification_ids_test.dart -v`
Expected: Compilation error — `bandingBaseId` not found

- [ ] **Step 3: Add bandingBaseId to NotificationIds**

In `lib/domain/services/notifications/notification_ids.dart`, add after line 18 (`chickCareBaseId`):

```dart
  /// Base ID offset for banding reminder notifications. Range: 500000–599999
  static const bandingBaseId = 500000;
```

- [ ] **Step 4: Add banding toggle to NotificationToggleSettings**

In `lib/domain/services/notifications/notification_toggle_settings.dart`:

Add to constructor (after `this.healthCheck = true,` line 14):
```dart
    this.banding = true,
```

Add field declaration (after `final bool healthCheck;` line 34):
```dart
  /// Whether banding reminders are enabled.
  final bool banding;
```

Update `allEnabled` getter (line 40):
```dart
  bool get allEnabled => eggTurning && incubation && chickCare && healthCheck && banding;
```

Add to `copyWith` — parameter (after `bool? healthCheck,` line 49):
```dart
    bool? banding,
```

Add to `copyWith` — body (after `healthCheck: healthCheck ?? this.healthCheck,` line 58):
```dart
      banding: banding ?? this.banding,
```

- [ ] **Step 5: Add backward-compatible static accessor to NotificationScheduler**

In `lib/domain/services/notifications/notification_scheduler.dart`, add after line 34:

```dart
  static const bandingBaseId = NotificationIds.bandingBaseId;
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/domain/services/notifications/notification_ids_test.dart -v`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/domain/services/notifications/notification_ids.dart lib/domain/services/notifications/notification_toggle_settings.dart lib/domain/services/notifications/notification_scheduler.dart test/domain/services/notifications/notification_ids_test.dart
git commit -m "feat(notifications): add banding base ID and toggle setting"
```

---

## Task 7: NotificationScheduler — Add `scheduleBandingReminders()`

**Files:**
- Modify: `lib/domain/services/notifications/notification_scheduler.dart`
- Test: `test/domain/services/notifications/notification_scheduler_banding_test.dart`

- [ ] **Step 1: Write tests for scheduleBandingReminders**

```dart
// test/domain/services/notifications/notification_scheduler_banding_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockNotificationRateLimiter extends Mock implements NotificationRateLimiter {}

void main() {
  late MockNotificationService mockService;
  late MockNotificationRateLimiter mockRateLimiter;
  late NotificationScheduler scheduler;

  setUp(() {
    mockService = MockNotificationService();
    mockRateLimiter = MockNotificationRateLimiter();
    scheduler = NotificationScheduler(mockService, mockRateLimiter);

    when(() => mockService.scheduleNotification(
      id: any(named: 'id'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      scheduledDate: any(named: 'scheduledDate'),
      channelId: any(named: 'channelId'),
      payload: any(named: 'payload'),
    )).thenAnswer((_) async {});
  });

  group('scheduleBandingReminders', () {
    test('schedules 4 notifications for future banding day', () async {
      final now = DateTime(2026, 3, 1, 8, 0);
      final hatchDate = DateTime(2026, 3, 1);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-1',
        chickLabel: 'Chick A',
        hatchDate: hatchDate,
        bandingDay: 10,
        now: now,
      );

      verify(() => mockService.scheduleNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        channelId: NotificationService.chickCareChannelId,
        payload: 'banding:chick-1',
      )).called(4);
    });

    test('skips past notifications', () async {
      final now = DateTime(2026, 3, 12, 10, 0); // After banding day (day 10)
      final hatchDate = DateTime(2026, 3, 1);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-2',
        chickLabel: 'Chick B',
        hatchDate: hatchDate,
        bandingDay: 10,
        now: now,
      );

      // Only follow-up 2 (day 10+3 = March 14) is in the future
      verify(() => mockService.scheduleNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        channelId: any(named: 'channelId'),
        payload: any(named: 'payload'),
      )).called(1);
    });

    test('respects banding toggle setting when disabled', () async {
      final settings = const NotificationToggleSettings(banding: false);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-3',
        chickLabel: 'Chick C',
        hatchDate: DateTime(2026, 3, 1),
        bandingDay: 10,
        settings: settings,
      );

      verifyNever(() => mockService.scheduleNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        channelId: any(named: 'channelId'),
        payload: any(named: 'payload'),
      ));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/services/notifications/notification_scheduler_banding_test.dart -v`
Expected: Compilation error — `scheduleBandingReminders` not found

- [ ] **Step 3: Implement scheduleBandingReminders**

In `lib/domain/services/notifications/notification_scheduler.dart`, add before `showImmediateNotification` (before line 332):

```dart
  /// Schedules banding reminder notifications for a chick.
  ///
  /// Creates 4 notifications: pre-reminder (day-1), main (banding day),
  /// follow-up 1 (day+1), follow-up 2 (day+3). All at 09:00.
  /// Respects [NotificationToggleSettings.banding] toggle.
  Future<void> scheduleBandingReminders({
    required String chickId,
    required String chickLabel,
    required DateTime hatchDate,
    required int bandingDay,
    NotificationToggleSettings? settings,
    @visibleForTesting DateTime? now,
  }) async {
    if (settings != null && !settings.banding) {
      AppLogger.info(
        '[NotificationScheduler] Banding disabled, skipping $chickLabel',
      );
      return;
    }

    final now0 = now ?? DateTime.now();
    final futures = <Future<void>>[];

    // Offsets relative to bandingDay: -1, 0, +1, +3
    final offsets = <int, ({String titleKey, String bodyKey})>{
      -1: (titleKey: 'notifications.banding_pre_title', bodyKey: 'notifications.banding_pre_body'),
      0: (titleKey: 'notifications.banding_main_title', bodyKey: 'notifications.banding_main_body'),
      1: (titleKey: 'notifications.banding_followup_title', bodyKey: 'notifications.banding_followup_body'),
      3: (titleKey: 'notifications.banding_followup_title', bodyKey: 'notifications.banding_followup_body'),
    };

    var index = 0;
    for (final entry in offsets.entries) {
      final scheduledDate = DateTime(
        hatchDate.year,
        hatchDate.month,
        hatchDate.day + bandingDay + entry.key,
        9, // 09:00
      );

      if (scheduledDate.isBefore(now0)) {
        index++;
        continue;
      }

      final id = NotificationIds.generate(
        NotificationIds.bandingBaseId,
        chickId,
        index,
      );

      futures.add(
        _service.scheduleNotification(
          id: id,
          title: entry.value.titleKey.tr(),
          body: entry.value.bodyKey.tr(args: [chickLabel]),
          scheduledDate: scheduledDate,
          channelId: NotificationService.chickCareChannelId,
          payload: 'banding:$chickId',
        ),
      );
      index++;
    }
    await Future.wait(futures);

    AppLogger.info(
      '[NotificationScheduler] Banding reminders scheduled for $chickLabel',
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/services/notifications/notification_scheduler_banding_test.dart -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/notifications/notification_scheduler.dart test/domain/services/notifications/notification_scheduler_banding_test.dart
git commit -m "feat(notifications): add scheduleBandingReminders method"
```

---

## Task 8: NotificationSchedulerCancel — Add `cancelBandingReminders()`

**Files:**
- Modify: `lib/domain/services/notifications/notification_scheduler_cancel.dart`
- Modify: `lib/domain/services/notifications/notification_service.dart:352-363`

- [ ] **Step 1: Add cancelBandingReminders to mixin**

In `lib/domain/services/notifications/notification_scheduler_cancel.dart`, add before `cancelAll()` (before line 108):

```dart
  /// Cancels banding reminder notifications for a specific chick.
  Future<void> cancelBandingReminders(String chickId) async {
    final futures = <Future<void>>[];
    for (var i = 0; i < 4; i++) {
      final id = NotificationIds.generate(
        NotificationIds.bandingBaseId,
        chickId,
        i,
      );
      futures.add(notificationService.cancel(id));
    }
    await Future.wait(futures);
    AppLogger.info(
      '[NotificationScheduler] Banding reminders cancelled for $chickId',
    );
  }
```

- [ ] **Step 2: Write test for cancelBandingReminders**

```dart
// Add to test/domain/services/notifications/notification_scheduler_banding_test.dart
  group('cancelBandingReminders', () {
    test('cancels 4 notifications for a chick', () async {
      when(() => mockService.cancel(any())).thenAnswer((_) async {});

      await scheduler.cancelBandingReminders('chick-1');

      verify(() => mockService.cancel(any())).called(4);
    });
  });
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/domain/services/notifications/notification_scheduler_banding_test.dart -v`
Expected: FAIL — `cancelBandingReminders` not found

- [ ] **Step 4: Add banding payload routing**

In `lib/domain/services/notifications/notification_service.dart`, update the switch (line 352-362). Add `'banding'` to the chick routing case:

```dart
      'chick' || 'chick_care' || 'banding' => '/chicks/$id',
```

- [ ] **Step 5: Run tests to verify cancelBandingReminders passes**

Run: `flutter test test/domain/services/notifications/notification_scheduler_banding_test.dart -v`
Expected: PASS

- [ ] **Step 6: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 7: Commit**

```bash
git add lib/domain/services/notifications/notification_scheduler_cancel.dart lib/domain/services/notifications/notification_service.dart
git commit -m "feat(notifications): add cancelBandingReminders and banding payload routing"
```

---

## Task 9: CalendarEventGenerator — Add `chickId` + `bandingDay` params

**Files:**
- Modify: `lib/domain/services/calendar/calendar_event_generator.dart:127-166`

- [ ] **Step 1: Update generateChickEvents signature and implementation**

In `lib/domain/services/calendar/calendar_event_generator.dart`, replace the `generateChickEvents` method (lines 127-166):

```dart
  /// Generates chick care milestone events.
  ///
  /// Creates events for first week check, banding day, and weaning target.
  /// The banding event uses [EventType.banding] with [chickId] for linkage.
  Future<void> generateChickEvents({
    required String userId,
    required DateTime hatchDate,
    required String chickLabel,
    String? chickId,
    int bandingDay = 10,
  }) async {
    try {
      final milestones = <int, (String, EventType, String?)>{
        7: ('calendar.milestone_first_week'.tr(), EventType.chick, null),
        bandingDay: ('calendar.milestone_banding'.tr(), EventType.banding, chickId),
        35: ('calendar.milestone_weaning'.tr(), EventType.chick, null),
      };

      for (final entry in milestones.entries) {
        final eventDate = hatchDate.add(Duration(days: entry.key));
        if (eventDate.isBefore(DateTime.now())) continue;

        final (label, type, eventChickId) = entry.value;

        final event = Event(
          id: _uuid.v4(),
          title: '$label - $chickLabel',
          eventDate: eventDate,
          type: type,
          userId: userId,
          chickId: eventChickId,
          description: 'calendar.day_milestone'.tr(
            args: ['${entry.key}', label],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _eventRepo.save(event);
      }

      AppLogger.info(
        '[CalendarEventGenerator] Chick events created for $chickLabel',
      );
    } catch (e, st) {
      AppLogger.error('[CalendarEventGenerator]', e, st);
      Sentry.captureException(e, stackTrace: st);
    }
  }
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/domain/services/calendar/calendar_event_generator.dart
git commit -m "feat(calendar): add chickId and bandingDay params to generateChickEvents"
```

---

## Task 10: ChickFormProviders — Wire banding to create/update/delete/deceased

**Files:**
- Modify: `lib/features/chicks/providers/chick_form_providers.dart:36-278`

- [ ] **Step 1: Update createChick to accept and pass bandingDay**

In `lib/features/chicks/providers/chick_form_providers.dart`, add `bandingDay` parameter to `createChick` (line 41):

```dart
  Future<void> createChick({
    required String userId,
    String? name,
    BirdGender gender = BirdGender.unknown,
    ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
    String? clutchId,
    String? eggId,
    required DateTime hatchDate,
    double? hatchWeight,
    String? ringNumber,
    String? notes,
    int bandingDay = 10,
  }) async {
```

Add `bandingDay: bandingDay` to the Chick constructor (after `notes: notes,` around line 67):

```dart
        bandingDay: bandingDay,
```

Update `generateChickEvents` call (around line 96) to pass `chickId` and `bandingDay`:

```dart
        await calendarGen.generateChickEvents(
          userId: userId,
          hatchDate: hatchDate,
          chickLabel: /* existing label logic */,
          chickId: chick.id,
          bandingDay: bandingDay,
        );
```

Add banding reminder scheduling after chick care reminders block (after line 91):

```dart
      // Schedule banding reminders
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final settings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleBandingReminders(
          chickId: chick.id,
          chickLabel:
              name ??
              'chicks.unnamed_chick'.tr(
                args: [ringNumber ?? chick.id.substring(0, 6)],
              ),
          hatchDate: hatchDate,
          bandingDay: bandingDay,
          settings: settings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule banding reminders: $e');
      }
```

- [ ] **Step 2: Update updateChick to handle bandingDay reschedule**

Replace `updateChick` method (lines 122-133) with:

```dart
  Future<void> updateChick(Chick chick, {Chick? previous}) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(chickRepositoryProvider);
      await repo.save(chick.copyWith(updatedAt: DateTime.now()));

      // Reschedule banding reminders if bandingDay changed
      if (previous != null && previous.bandingDay != chick.bandingDay && !chick.isBanded) {
        try {
          final scheduler = ref.read(notificationSchedulerProvider);
          final settings = ref.read(notificationToggleSettingsProvider);
          await scheduler.cancelBandingReminders(chick.id);
          if (chick.hatchDate != null) {
            await scheduler.scheduleBandingReminders(
              chickId: chick.id,
              chickLabel: chick.name ?? chick.id.substring(0, 6),
              hatchDate: chick.hatchDate!,
              bandingDay: chick.bandingDay,
              settings: settings,
            );
          }
        } catch (e) {
          AppLogger.warning('Failed to reschedule banding reminders: $e');
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('ChickFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
```

- [ ] **Step 3: Add cancelBandingReminders to deleteChick**

In `deleteChick` method (line 136-146), add banding cancellation after `await repo.remove(id);`:

```dart
      // Cancel banding reminders
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        await scheduler.cancelBandingReminders(id);
      } catch (e) {
        AppLogger.warning('Failed to cancel banding reminders: $e');
      }
```

- [ ] **Step 4: Add cancelBandingReminders to markAsDeceased**

In `markAsDeceased` method (line 169-189), add banding cancellation after the save (inside the `if (chick != null)` block):

```dart
        // Cancel banding reminders for deceased chick
        try {
          final scheduler = ref.read(notificationSchedulerProvider);
          await scheduler.cancelBandingReminders(id);
        } catch (e) {
          AppLogger.warning('Failed to cancel banding reminders: $e');
        }
```

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/features/chicks/providers/chick_form_providers.dart
git commit -m "feat(chick-form): wire banding reminders to create/update/delete/deceased"
```

---

## Task 11: EggProviders — Update auto-hatch flow

**Files:**
- Modify: `lib/features/eggs/providers/egg_providers.dart:176-230`

- [ ] **Step 1: Update _createChickFromHatchedEgg**

In `lib/features/eggs/providers/egg_providers.dart`, update the `generateChickEvents` call (around line 226) to pass `chickId` and `bandingDay`:

```dart
        await calendarGen.generateChickEvents(
          userId: egg.userId,
          hatchDate: hatchDate,
          chickLabel: chickLabel,
          chickId: chick.id,
          bandingDay: 10,
        );
```

Add banding reminder scheduling after the calendar events block (after the catch block around line 234):

```dart
      // Schedule banding reminders for auto-created chick
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final chickSettings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleBandingReminders(
          chickId: chick.id,
          chickLabel: chickLabel,
          hatchDate: hatchDate,
          bandingDay: 10,
          settings: chickSettings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule banding reminders: $e');
      }
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/eggs/providers/egg_providers.dart
git commit -m "feat(eggs): wire banding reminders to auto-hatch chick creation"
```

---

## Task 12: ChickProviders — Add `markBandingComplete` action

**Files:**
- Modify: `lib/features/chicks/providers/chick_providers.dart`

- [ ] **Step 1: Add markBandingComplete provider**

In `lib/features/chicks/providers/chick_providers.dart`, add at the end of the file (before any closing brackets). First add the needed imports at the top:

```dart
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
```

Then add the notifier class and provider:

```dart
/// Notifier for marking banding as complete.
class BandingActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Marks a chick as banded: updates chick, completes event, cancels notifications.
  Future<void> markBandingComplete(String chickId) async {
    state = const AsyncLoading();
    try {
      final chickRepo = ref.read(chickRepositoryProvider);
      final eventRepo = ref.read(eventRepositoryProvider);
      final scheduler = ref.read(notificationSchedulerProvider);

      // 1. Update chick with bandingDate
      final chick = await chickRepo.getById(chickId);
      if (chick == null) {
        state = AsyncError('Chick not found', StackTrace.current);
        return;
      }
      await chickRepo.save(chick.copyWith(
        bandingDate: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 2. Complete banding event (filter in memory — no DAO method for chickId)
      final allEvents = await eventRepo.getAll(chick.userId);
      final bandingEvents = allEvents.where(
        (e) => e.chickId == chickId && e.type == EventType.banding && e.status == EventStatus.active,
      );
      for (final event in bandingEvents) {
        await eventRepo.save(event.copyWith(
          status: EventStatus.completed,
          updatedAt: DateTime.now(),
        ));
      }

      // 3. Cancel remaining banding notifications
      await scheduler.cancelBandingReminders(chickId);

      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('BandingActionNotifier', e, st);
      state = AsyncError(e, st);
    }
  }
}

final bandingActionProvider =
    NotifierProvider<BandingActionNotifier, AsyncValue<void>>(BandingActionNotifier.new);
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/chicks/providers/chick_providers.dart
git commit -m "feat(chick-providers): add markBandingComplete action"
```

---

## Task 13: Chick Form Screen — Add bandingDay field

**Files:**
- Modify: `lib/features/chicks/screens/chick_form_screen.dart:32-353`

- [ ] **Step 1: Add bandingDay controller and state**

In `_ChickFormScreenState`, add after `_notesController` (line 37):

```dart
  final _bandingDayController = TextEditingController(text: '10');
```

Add to `dispose()` (line 67):
```dart
    _bandingDayController.dispose();
```

Add to `_populateFromExisting()` (after line 62):
```dart
    _bandingDayController.text = chick.bandingDay.toString();
```

- [ ] **Step 2: Add bandingDay form field to UI**

In `_buildFormScaffold`, add after the Hatch Date `DatePickerField` and its `SizedBox` (after line 232):

```dart
                  // Banding Day
                  TextFormField(
                    controller: _bandingDayController,
                    enabled: _existingChick?.isBanded != true,
                    decoration: InputDecoration(
                      labelText: 'chicks.banding_day_label'.tr(),
                      hintText: 'chicks.banding_day_hint'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const AppIcon(AppIcons.ring),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'validation.required'.tr();
                      }
                      final parsed = int.tryParse(value.trim());
                      if (parsed == null || parsed < 5 || parsed > 21) {
                        return 'chicks.banding_day_validation'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
```

- [ ] **Step 3: Update _submit to pass bandingDay**

In `_submit()`, update the `createChick` call (line 333) to include `bandingDay`:

```dart
    notifier.createChick(
      userId: userId,
      name: _nameController.text.isEmpty ? null : _nameController.text.trim(),
      gender: _gender,
      healthStatus: _healthStatus,
      hatchDate: _hatchDate!,
      hatchWeight: _parseOptional(_hatchWeightController.text),
      ringNumber: _ringController.text.isEmpty ? null : _ringController.text.trim(),
      notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
      bandingDay: int.tryParse(_bandingDayController.text.trim()) ?? 10,
    );
```

Update the edit path (line 313) to pass `previous` for reschedule detection:

```dart
      notifier.updateChick(
        _existingChick!.copyWith(
          name: _nameController.text.isEmpty ? null : _nameController.text.trim(),
          gender: _gender,
          healthStatus: _healthStatus,
          hatchDate: _hatchDate,
          hatchWeight: _parseOptional(_hatchWeightController.text),
          ringNumber: _ringController.text.isEmpty ? null : _ringController.text.trim(),
          notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
          bandingDay: int.tryParse(_bandingDayController.text.trim()) ?? 10,
        ),
        previous: _existingChick,
      );
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/features/chicks/screens/chick_form_screen.dart
git commit -m "feat(chick-form): add bandingDay input field with validation"
```

---

## Task 14: Chick Detail Info — Add banding InfoCard

**Files:**
- Modify: `lib/features/chicks/widgets/chick_detail_info.dart:16-155`

- [ ] **Step 1: Add banding InfoCard**

In `lib/features/chicks/widgets/chick_detail_info.dart`, add after the weaning row (after line 120, before the death date section):

```dart
          // Banding status
          const SizedBox(height: AppSpacing.sm),
          if (chick.isBanded)
            InfoCard(
              icon: const AppIcon(AppIcons.ring),
              title: dateFormat.format(chick.bandingDate!),
              subtitle: 'chicks.banding_completed'.tr(),
              trailing: Icon(LucideIcons.checkCircle2, color: theme.colorScheme.primary),
            )
          else if (chick.plannedBandingDate != null)
            InfoCard(
              icon: const AppIcon(AppIcons.ring),
              title: 'chicks.banding_planned'.tr(args: [dateFormat.format(chick.plannedBandingDate!)]),
              subtitle: 'chicks.banding_not_yet'.tr(),
              onTap: () => _confirmBanding(context, ref),
            ),
```

Add the `_confirmBanding` helper method to `ChickDetailInfo`:

```dart
  Future<void> _confirmBanding(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'chicks.banding_confirm_title'.tr(),
      message: 'chicks.banding_confirm_message'.tr(),
    );
    if (confirmed == true) {
      await ref.read(bandingActionProvider.notifier).markBandingComplete(chick.id);
      if (!context.mounted) return;
      final state = ref.read(bandingActionProvider);
      state.when(
        data: (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('chicks.banding_success'.tr())),
        ),
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'common.error'.tr()}: $e')),
        ),
        loading: () {},
      );
    }
  }
```

Add imports at top of file:

```dart
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/chicks/widgets/chick_detail_info.dart
git commit -m "feat(chick-detail): add banding status InfoCard with confirm action"
```

---

## Task 15: Calendar Widget — Add "Tamamla" button for banding events

**Files:**
- Modify: Calendar event detail widget (find via `lib/features/calendar/widgets/`)

- [ ] **Step 1: Identify the calendar event detail widget**

Use `Glob` and `Grep` to find the calendar widget that shows event details when tapped. Look for where `EventType` or event `status` is checked in calendar widgets.

- [ ] **Step 2: Add "Tamamla" button for banding events**

In the calendar event detail/popup widget, add a condition:

```dart
// Show "Tamamla" button for active banding events
if (event.type == EventType.banding && event.status == EventStatus.active && event.chickId != null)
  PrimaryButton(
    label: 'common.complete'.tr(),
    onPressed: () async {
      await ref.read(bandingActionProvider.notifier).markBandingComplete(event.chickId!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('chicks.banding_success'.tr())),
        );
      }
    },
  ),
// Show "Tamamlandı" badge for completed banding events
if (event.type == EventType.banding && event.status == EventStatus.completed)
  StatusBadge(
    icon: Icon(LucideIcons.checkCircle2, color: theme.colorScheme.primary),
    label: 'common.completed'.tr(),
  ),
```

Add required imports for `bandingActionProvider`, `EventType`, `EventStatus`.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/
git commit -m "feat(calendar): add complete button for banding events"
```

---

## Task 16: Localization — Add all banding keys

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add keys to tr.json**

Add under `"chicks"` section:
```json
    "banding_day_label": "Halka Takma Günü",
    "banding_day_hint": "Çıkış tarihinden itibaren kaçıncı gün (varsayılan: 10)",
    "banding_day_validation": "5 ile 21 arasında bir değer girin",
    "banding_status": "Halka Durumu",
    "banding_planned": "Planlanan: {}",
    "banding_completed": "Halka Takıldı",
    "banding_not_yet": "Henüz takılmadı",
    "banding_confirm_title": "Halka Takıldı mı?",
    "banding_confirm_message": "Bu yavruya halka takıldığını onaylıyor musunuz?",
    "banding_success": "Halka takma kaydedildi"
```

Add under `"notifications"` section:
```json
    "banding_pre_title": "Yarın Halka Takma Günü",
    "banding_pre_body": "{} için yarın halka takma günü",
    "banding_main_title": "Halka Takma Günü!",
    "banding_main_body": "{} için bugün halka takılmalı",
    "banding_followup_title": "Halka Hatırlatma",
    "banding_followup_body": "{} için halka henüz takılmadı"
```

- [ ] **Step 2: Add keys to en.json**

Add matching keys under `"chicks"`:
```json
    "banding_day_label": "Banding Day",
    "banding_day_hint": "Days after hatch (default: 10)",
    "banding_day_validation": "Enter a value between 5 and 21",
    "banding_status": "Banding Status",
    "banding_planned": "Planned: {}",
    "banding_completed": "Banded",
    "banding_not_yet": "Not yet banded",
    "banding_confirm_title": "Banding Complete?",
    "banding_confirm_message": "Confirm this chick has been banded?",
    "banding_success": "Banding recorded"
```

Add matching keys under `"notifications"`:
```json
    "banding_pre_title": "Banding Day Tomorrow",
    "banding_pre_body": "Banding day for {} is tomorrow",
    "banding_main_title": "Banding Day!",
    "banding_main_body": "{} should be banded today",
    "banding_followup_title": "Banding Reminder",
    "banding_followup_body": "{} has not been banded yet"
```

- [ ] **Step 3: Add keys to de.json**

Add matching keys under `"chicks"`:
```json
    "banding_day_label": "Tag der Beringung",
    "banding_day_hint": "Tage nach dem Schlupf (Standard: 10)",
    "banding_day_validation": "Geben Sie einen Wert zwischen 5 und 21 ein",
    "banding_status": "Beringungsstatus",
    "banding_planned": "Geplant: {}",
    "banding_completed": "Beringt",
    "banding_not_yet": "Noch nicht beringt",
    "banding_confirm_title": "Beringung abgeschlossen?",
    "banding_confirm_message": "Bestätigen Sie, dass dieser Küken beringt wurde?",
    "banding_success": "Beringung gespeichert"
```

Add matching keys under `"notifications"`:
```json
    "banding_pre_title": "Morgen Beringungstag",
    "banding_pre_body": "Morgen ist Beringungstag für {}",
    "banding_main_title": "Beringungstag!",
    "banding_main_body": "{} sollte heute beringt werden",
    "banding_followup_title": "Beringungserinnerung",
    "banding_followup_body": "{} wurde noch nicht beringt"
```

- [ ] **Step 4: Run L10n sync check**

Run: `python scripts/check_l10n_sync.py`
Expected: All 3 files in sync

- [ ] **Step 5: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(l10n): add banding reminder localization keys for tr/en/de"
```

---

## Task 17: Final Verification

- [ ] **Step 1: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: No errors

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors or warnings

- [ ] **Step 3: Run all tests**

Run: `flutter test --exclude-tags golden`
Expected: All tests pass

- [ ] **Step 4: Run code quality check**

Run: `python scripts/verify_code_quality.py`
Expected: No anti-pattern violations

- [ ] **Step 5: Run L10n sync check**

Run: `python scripts/check_l10n_sync.py`
Expected: All 3 files in sync

- [ ] **Step 6: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: address verification issues from banding feature"
```
