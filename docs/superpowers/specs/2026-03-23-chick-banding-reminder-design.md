# Chick Banding Reminder Feature Design

**Date:** 2026-03-23
**Status:** Approved
**Approach:** Extend existing Event system (CalendarEventGenerator + NotificationScheduler + EventReminder)

## Problem

Users forget to band/ring chicks at the optimal age window. The calendar already generates a 10th-day "Halka Takma Gunu" event via `CalendarEventGenerator`, but no push notification or reminder is sent, and there is no way to track whether banding was completed.

## Requirements

1. Configurable banding day per chick (default 10, range 5-21) set in chick form
2. Push notifications: 1 day before, same day, +1 day if not banded, +3 days final reminder
3. "Halka Takildi" (Banded) action from both chick detail screen and calendar event
4. Track banding completion date on chick model
5. Cancel remaining reminders once banding is marked complete

## Design

### 1. Data Model Changes

#### Chick Model — 2 new fields

```dart
// chick_model.dart
@Default(10) int bandingDay,   // Configurable banding day (default 10, user can change per chick)
DateTime? bandingDate,          // When banding was completed (null = not yet banded)
```

Computed property via extension:

```dart
extension ChickBandingX on Chick {
  bool get isBanded => bandingDate != null;
  DateTime? get plannedBandingDate =>
      hatchDate != null ? hatchDate!.add(Duration(days: bandingDay)) : null;
}
```

#### Event Model — new chickId field

The Event model currently has `birdId` and `breedingPairId` for entity linkage but no `chickId`. A new nullable `chickId` field is required to associate banding events with specific chicks.

```dart
// event_model.dart — new field
String? chickId,  // Links event to a chick (used by banding events)
```

This also requires:
- `events_table.dart`: add `chickId` text column (nullable)
- `event_mapper.dart`: include chickId in toModel/toCompanion
- `supabase_extensions.dart`: include chickId in Event.toSupabase()
- Supabase `events` table: add `chick_id` column (uuid, nullable, FK to chicks)
- DB migration (schema v15): add `chick_id` column to events table

#### EventType Enum — new value

```dart
enum EventType {
  // ... existing values
  banding,  // Chick banding event
}
```

The existing `eventTypeConverter` auto-handles new enum values — no converter change needed.

#### Database Migration — schema version 15

Add to `chicks` table:
- `banding_day`: integer, default 10
- `banding_date`: text, nullable

Add to `events` table:
- `chick_id`: text, nullable

### 2. Event & Notification Flow

#### On Chick Creation

```
ChickFormNotifier.createChick()
  -> DAO.insertItem()                                    # Existing
  -> CalendarEventGenerator.generateChickEvents()        # Existing (now passes bandingDay + chickId)
  -> NotificationScheduler.scheduleBandingReminders()    # NEW
```

#### Notification Schedule

All 4 notifications are scheduled at chick creation time via `flutter_local_notifications`. There is no delivery-time state check — the OS fires scheduled notifications directly. When banding is marked complete, `cancelBandingReminders()` explicitly cancels any remaining scheduled notifications.

| Notification | Timing | Cancelled when banded? |
|---|---|---|
| Pre-reminder | hatchDate + bandingDay - 1, 09:00 | Yes |
| Main reminder | hatchDate + bandingDay, 09:00 | Yes |
| Follow-up 1 | hatchDate + bandingDay + 1, 09:00 | Yes |
| Follow-up 2 | hatchDate + bandingDay + 3, 09:00 | Yes |

All 4 are always scheduled. When user marks banding complete, all remaining (unfired) notifications are cancelled via `cancelBandingReminders(chickId)`.

#### NotificationIds

Following the existing 100,000-partitioned range convention:

```dart
static const bandingBaseId = 500000; // Next available slot after chickCare (400000)
// 4 notifications per chick: offsets 0 (pre), 1 (main), 2 (follow-up-1), 3 (follow-up-2)
```

#### NotificationToggleSettings — new toggle

Add `banding` toggle to `NotificationToggleSettings`:

```dart
final bool banding; // default: true — controls banding reminder notifications
```

`scheduleBandingReminders()` checks `settings.banding` before scheduling, consistent with existing pattern where each scheduler method accepts `NotificationToggleSettings`.

#### Notification Channel

Reuse existing `chick_care` channel for banding notifications. Banding is chick-related and doesn't warrant a separate Android notification channel. Payload type: `banding:{chickId}`.

Add `'banding'` case to `payloadToRoute()` mapping → navigates to `/chicks/{chickId}`.

#### Banding Completion Flow

When user taps "Halka Takildi":

1. `Chick.bandingDate = DateTime.now()` -> DAO + sync
2. Query banding event by `chickId` + `EventType.banding` -> set `Event.status = EventStatus.completed` -> DAO + sync
3. Cancel remaining notifications -> `NotificationScheduler.cancelBandingReminders(chickId)`

### 3. UI Changes

#### Chick Form (ChickFormScreen)

New field below `hatchDate`, above `ringNumber`:
- **"Halka Takma Gunu"** — numeric TextFormField
- Default: 10, validator: 5-21 range
- Label: `'chicks.banding_day_label'.tr()`
- Hint: `'chicks.banding_day_hint'.tr()`
- Disabled when `bandingDate != null` (already banded)

#### Chick Detail Screen (ChickDetailScreen)

**Not banded (bandingDate == null):**
- InfoCard with `AppIcon(AppIcons.ring)` icon
- Title: "Halka Takma"
- Subtitle: "Planlanan: {planned date}"
- Trailing: PrimaryButton "Halka Takildi"
- On tap -> showConfirmDialog -> update chick + complete event + cancel notifications

**Banded (bandingDate != null):**
- InfoCard with `AppIcon(AppIcons.ring)` icon
- Title: "Halka Takildi"
- Subtitle: "{banding date}"
- Trailing: green check icon

#### Calendar Event

- Tapping banding event shows "Tamamla" button when `status == active`
- "Tamamla" triggers same flow: update chick + complete event + cancel notifications
- When completed: button hidden, "Tamamlandi" badge shown

#### Notification Tap

Notification payload `banding:{chickId}` routes to `/chicks/{chickId}` where user can see and tap "Halka Takildi" button.

### 4. CalendarEventGenerator Update

Replace hardcoded `10` in milestone map with dynamic `bandingDay` parameter. Also pass `chickId` so the generated event links to the chick:

```dart
generateChickEvents({
  required String userId,
  required DateTime hatchDate,
  required String chickLabel,
  required String chickId,   // NEW — stored in Event.chickId for banding event
  int bandingDay = 10,       // NEW — replaces hardcoded 10
})
```

The banding milestone event is created with `EventType.banding` (instead of `EventType.chick`) and `chickId` set. Other milestone events (day 7, day 35) remain `EventType.chick` with no chickId.

**Caller updates:**
- `ChickFormNotifier.createChick()` in `chick_form_providers.dart` — pass `chickId` and `bandingDay`
- `EggProviders` auto-hatch flow in `egg_providers.dart` — pass `chickId` and `bandingDay` (default 10), also schedule banding reminders for auto-created chicks

### 5. Edge Cases

| Case | Behavior |
|---|---|
| Chick deceased | Cancel all banding notifications, set banding event to cancelled. Add `cancelBandingReminders()` call to `ChickFormNotifier.markAsDeceased()` |
| Chick soft-deleted | Cancel all banding notifications. Add `cancelBandingReminders()` call to `ChickFormNotifier.deleteChick()` |
| hatchDate in past (old chick added) | Only schedule future notifications, skip past ones (existing pattern in NotificationScheduler) |
| bandingDay changed (chick edit) | In `ChickFormNotifier.updateChick()`: detect bandingDay change, cancel old banding reminders, reschedule with new bandingDay, update/regenerate banding calendar event |
| Already banded + form edit | bandingDay field disabled (not editable) |
| App closed at notification time | OS delivers via flutter_local_notifications (existing pattern) |

### 6. Migration for Existing Chicks

- DB migration sets `banding_day = 10` as default for existing rows
- `bandingDate` remains null (no notifications scheduled for existing chicks)
- User can edit an existing chick to trigger the banding reminder flow

### 7. Localization Keys

New keys under `chicks.` category (TR / EN / DE):

```json
{
  "chicks": {
    "banding_day_label":        "Halka Takma Gunu"       / "Banding Day"              / "Tag der Beringung",
    "banding_day_hint":         "Cikis tarihinden itibaren kacinci gun (varsayilan: 10)" / "Days after hatch (default: 10)" / "Tage nach dem Schlupf (Standard: 10)",
    "banding_day_validation":   "5 ile 21 arasinda bir deger girin" / "Enter a value between 5 and 21" / "Geben Sie einen Wert zwischen 5 und 21 ein",
    "banding_status":           "Halka Durumu"            / "Banding Status"           / "Beringungsstatus",
    "banding_planned":          "Planlanan: {}"           / "Planned: {}"              / "Geplant: {}",
    "banding_completed":        "Halka Takildi"           / "Banded"                   / "Beringt",
    "banding_not_yet":          "Henuz takilmadi"         / "Not yet banded"           / "Noch nicht beringt",
    "banding_confirm_title":    "Halka Takildi mi?"       / "Banding Complete?"        / "Beringung abgeschlossen?",
    "banding_confirm_message":  "Bu yavruya halka takildigini onayliyor musunuz?" / "Confirm this chick has been banded?" / "Bestaetigen Sie, dass dieser Kueken beringt wurde?",
    "banding_success":          "Halka takma kaydedildi"  / "Banding recorded"         / "Beringung gespeichert"
  }
}
```

New keys under `notifications.` category (TR / EN / DE):

```json
{
  "notifications": {
    "banding_pre_title":      "Yarin Halka Takma Gunu"          / "Banding Day Tomorrow"         / "Morgen Beringungstag",
    "banding_pre_body":       "{} icin yarin halka takma gunu"   / "Banding day for {} is tomorrow" / "Morgen ist Beringungstag fuer {}",
    "banding_main_title":     "Halka Takma Gunu!"               / "Banding Day!"                 / "Beringungstag!",
    "banding_main_body":      "{} icin bugun halka takilmali"    / "{} should be banded today"    / "{} sollte heute beringt werden",
    "banding_followup_title": "Halka Hatirlatma"                 / "Banding Reminder"             / "Beringungserinnerung",
    "banding_followup_body":  "{} icin halka henuz takilmadi"    / "{} has not been banded yet"   / "{} wurde noch nicht beringt"
  }
}
```

### 8. Test Strategy

| Layer | Test | Coverage |
|---|---|---|
| Unit | `scheduleBandingReminders()` | 4 notifications scheduled at correct times |
| Unit | `cancelBandingReminders()` | All notifications cancelled |
| Unit | Edge cases | Past date, deceased chick, bandingDay change, reschedule |
| Unit | `markBandingComplete()` | Chick updated + event completed + notifications cancelled |
| Widget | Chick form | bandingDay field validation (5-21), disabled when banded |
| Widget | Chick detail | Banded vs not-banded UI states, confirm dialog |
| Widget | Calendar event | Complete button visibility |

### 9. Files to Modify

**Data layer:**
- `lib/data/models/chick_model.dart` — add bandingDay, bandingDate fields
- `lib/data/models/event_model.dart` — add chickId field
- `lib/data/local/database/tables/chicks_table.dart` — add banding_day, banding_date columns
- `lib/data/local/database/tables/events_table.dart` — add chick_id column
- `lib/data/local/database/mappers/chick_mapper.dart` — update mapping
- `lib/data/local/database/mappers/event_mapper.dart` — update mapping for chickId
- `lib/data/local/database/app_database.dart` — schema v15 migration
- `lib/data/models/supabase_extensions.dart` — update Chick.toSupabase() and Event.toSupabase()
- `lib/core/enums/event_enums.dart` — add banding to EventType

**Domain layer:**
- `lib/domain/services/notifications/notification_scheduler.dart` — add scheduleBandingReminders(), cancelBandingReminders()
- `lib/domain/services/notifications/notification_ids.dart` — add bandingBaseId = 500000
- `lib/domain/services/notifications/notification_toggle_settings.dart` — add banding toggle
- `lib/domain/services/notifications/notification_service.dart` — add banding payload routing
- `lib/domain/services/calendar/calendar_event_generator.dart` — add chickId + bandingDay params

**Feature layer:**
- `lib/features/chicks/providers/chick_form_providers.dart` — pass bandingDay/chickId to generator, schedule banding reminders, handle reschedule on edit, cancel on delete/deceased
- `lib/features/eggs/providers/egg_providers.dart` — update auto-hatch generateChickEvents() call with chickId + bandingDay, schedule banding reminders for auto-created chicks
- `lib/features/chicks/providers/chick_providers.dart` — add markBandingComplete action
- `lib/features/chicks/screens/chick_form_screen.dart` — add bandingDay field
- `lib/features/chicks/widgets/chick_detail_info.dart` — add banding InfoCard with action
- `lib/features/calendar/widgets/` — add complete button for banding events

**Localization:**
- `assets/translations/tr.json` — new keys (chicks.banding_*, notifications.banding_*)
- `assets/translations/en.json` — new keys
- `assets/translations/de.json` — new keys

**SVG (if needed):**
- `assets/icons/chicks/ring.svg` — new icon (if not already available)
- `lib/core/constants/app_icons.dart` — add ring icon constant
