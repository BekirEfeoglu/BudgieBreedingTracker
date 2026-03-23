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

#### EventType Enum — new value

```dart
enum EventType {
  // ... existing values
  banding,  // Chick banding event
}
```

#### Database Migration — schema version 15

Add to `chicks` table:
- `banding_day`: integer, default 10
- `banding_date`: text, nullable

Add enum converter for `EventType.banding`.

### 2. Event & Notification Flow

#### On Chick Creation

```
ChickFormNotifier.createChick()
  -> DAO.insertItem()                                    # Existing
  -> CalendarEventGenerator.generateChickEvents()        # Existing (uses bandingDay instead of hardcoded 10)
  -> NotificationScheduler.scheduleBandingReminders()    # NEW
```

#### Notification Schedule

| Notification | Timing | Condition |
|---|---|---|
| Pre-reminder | hatchDate + bandingDay - 1, 09:00 | Always scheduled |
| Main reminder | hatchDate + bandingDay, 09:00 | Always scheduled |
| Follow-up 1 | hatchDate + bandingDay + 1, 09:00 | Sent only if bandingDate == null |
| Follow-up 2 | hatchDate + bandingDay + 3, 09:00 | Sent only if bandingDate == null |

Pre-reminder and main reminder are always scheduled at chick creation. Follow-up 1 and 2 are also scheduled but check `bandingDate` at delivery time; if banding is complete, the notification is suppressed and cancelled.

#### NotificationIds

```dart
static const bandingBaseId = 5000; // Next available slot
// 4 notifications per chick: offsets 0 (pre), 1 (main), 2 (follow-up-1), 3 (follow-up-2)
```

#### Banding Completion Flow

When user taps "Halka Takildi":

1. `Chick.bandingDate = DateTime.now()` -> DAO + sync
2. `Event.status = EventStatus.completed` -> DAO + sync
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

Notification tap navigates to `/chicks/{chickId}` where user can see and tap "Halka Takildi" button.

### 4. CalendarEventGenerator Update

Replace hardcoded `10` in milestone map with dynamic `bandingDay` parameter:

```dart
generateChickEvents({
  required String userId,
  required DateTime hatchDate,
  required String chickLabel,
  int bandingDay = 10,  // NEW parameter
})
```

Milestone map uses `bandingDay` instead of hardcoded `10`.

### 5. Edge Cases

| Case | Behavior |
|---|---|
| Chick deceased | Cancel all banding notifications, set event to cancelled |
| Chick soft-deleted | Cancel all banding notifications |
| hatchDate in past (old chick added) | Only schedule future notifications, skip past ones |
| bandingDay changed (chick edit) | Cancel old notifications, reschedule with new bandingDay |
| Already banded + form edit | bandingDay field disabled |
| App closed at notification time | OS delivers via flutter_local_notifications (existing pattern) |

### 6. Migration for Existing Chicks

- DB migration sets `banding_day = 10` as default
- `bandingDate` remains null (no notifications scheduled for existing chicks)
- User can edit an existing chick to trigger the banding reminder flow

### 7. Localization Keys

New keys under `chicks.` category:

```json
{
  "chicks": {
    "banding_day_label": "Halka Takma Gunu",
    "banding_day_hint": "Cikis tarihinden itibaren kacinci gun (varsayilan: 10)",
    "banding_day_validation": "5 ile 21 arasinda bir deger girin",
    "banding_status": "Halka Durumu",
    "banding_planned": "Planlanan: {}",
    "banding_completed": "Halka Takildi",
    "banding_not_yet": "Henuz takilmadi",
    "banding_confirm_title": "Halka Takildi mi?",
    "banding_confirm_message": "Bu yavruya halka takildigini onayliyor musunuz?",
    "banding_success": "Halka takma kaydedildi"
  }
}
```

New keys under `notifications.` category:

```json
{
  "notifications": {
    "banding_pre_title": "Yarin Halka Takma Gunu",
    "banding_pre_body": "{} icin yarin halka takma gunu",
    "banding_main_title": "Halka Takma Gunu!",
    "banding_main_body": "{} icin bugun halka takilmali",
    "banding_followup_title": "Halka Hatirlatma",
    "banding_followup_body": "{} icin halka henuz takilmadi"
  }
}
```

### 8. Test Strategy

| Layer | Test | Coverage |
|---|---|---|
| Unit | `scheduleBandingReminders()` | 4 notifications scheduled at correct times |
| Unit | `cancelBandingReminders()` | All notifications cancelled |
| Unit | Edge cases | Past date, deceased chick, bandingDay change |
| Widget | Chick form | bandingDay field validation (5-21 range) |
| Widget | Chick detail | Banded vs not-banded UI states |
| Widget | Calendar event | Complete button visibility |

### 9. Files to Modify

**Data layer:**
- `lib/data/models/chick_model.dart` — add bandingDay, bandingDate fields
- `lib/data/local/database/tables/chicks_table.dart` — add columns
- `lib/data/local/database/mappers/chick_mapper.dart` — update mapping
- `lib/data/local/database/app_database.dart` — schema v15 migration
- `lib/data/models/supabase_extensions.dart` — update toSupabase()
- `lib/core/enums/event_enums.dart` — add banding to EventType
- `lib/data/local/database/converters/enum_converters.dart` — banding converter

**Domain layer:**
- `lib/domain/services/notifications/notification_scheduler.dart` — add scheduleBandingReminders(), cancelBandingReminders()
- `lib/domain/services/notifications/notification_ids.dart` — add bandingBaseId
- `lib/domain/services/calendar/calendar_event_generator.dart` — use dynamic bandingDay

**Feature layer:**
- `lib/features/chicks/providers/chick_form_providers.dart` — pass bandingDay, schedule banding reminders
- `lib/features/chicks/providers/chick_providers.dart` — add banding completion action
- `lib/features/chicks/screens/chick_form_screen.dart` — add bandingDay field
- `lib/features/chicks/widgets/chick_detail_info.dart` — add banding InfoCard
- `lib/features/calendar/widgets/` — add complete button for banding events

**Localization:**
- `assets/translations/tr.json` — new keys
- `assets/translations/en.json` — new keys
- `assets/translations/de.json` — new keys

**SVG (if needed):**
- `assets/icons/chicks/ring.svg` — new icon (if not already available)
- `lib/core/constants/app_icons.dart` — add ring icon constant
