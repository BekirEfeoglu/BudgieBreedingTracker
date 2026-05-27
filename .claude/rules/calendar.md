# Calendar & Reminders

Etkinlik takvimi: kuluçka milestone'ları, yumurta çevirme hatırlatması, breeding ramping, custom user event'ler. `CalendarService` (`lib/domain/services/calendar/`) ve `lib/features/calendar/`.

## Stack
| Bileşen | Yer |
|---------|-----|
| Service | `CalendarService` (`lib/domain/services/calendar/`) |
| Feature | `lib/features/calendar/` |
| Reminder service | `IncubationReminderService` |
| Local notification | `flutter_local_notifications` (notifications.md) |
| Storage | Drift `events` + `event_reminders` tables |
| Sync | ValidatedSyncMixin ile parent FK kontrol |

## Event Tipleri
| Tip | Kaynak | Otomatik mi? |
|-----|--------|--------------|
| `incubation_start` | Kuluçka başlatma | Otomatik |
| `egg_turn` | Yumurta çevirme | Otomatik (incubation tarihi + species config) |
| `incubation_milestone` | Fertile check, hatch day | Otomatik |
| `breeding_pair_introduction` | Pair oluşturma | Otomatik |
| `chick_milestone` | Yavru gelişim aşamaları | Otomatik |
| `health_check` | Kullanıcı tarafından | Manuel |
| `custom` | Kullanıcı | Manuel |

## Generation Logic
- Otomatik event'ler `species_incubation_config.dart` species'e göre offset hesaplar
- Manual event: kullanıcı form ile (form-validation.md pattern)
- Event create → ilgili reminder schedule (notifications.md `tz.TZDateTime`)
- Parent entity (incubation, breeding pair) silinince ilişkili event'ler cancel

## Reminder Schedule
```
Event create
  -> Calculate reminder triggers (örn. egg_turn: günde 4 kez)
  -> Schedule local notifications (tz.TZDateTime)
  -> Persist event_reminders row (sync için)
  -> Server timestamp UTC, display local (datetime-format.md)
```

Reminder timing kullanıcı ayarlanabilir:
- "1 saat önce", "1 gün önce", "exact time"
- Default: incubation = günde 2 kez, milestone = 1 saat önce
- Quiet hours (notifications.md) honored

## ID Stability
Notification ID deterministik:
- `egg_turn`: `'egg_turn_${eggId}_${dayIndex}_${slotIndex}'.hashCode`
- `incubation_milestone`: `'milestone_${incubationId}_${type}'.hashCode`
- Aynı event re-schedule'da eski ID cancel + yeni ID add

Re-generation pattern:
```dart
Future<void> reschedule(Incubation incubation) async {
  await _cancelAllForIncubation(incubation.id);
  final events = _generateEvents(incubation);
  for (final event in events) {
    await _scheduleNotification(event);
    await _persistEvent(event);
  }
}
```

## Deeplink Payload
Notification tap → app open + route:
```json
{
  "type": "egg_turn",
  "entity_id": "uuid",
  "route": "/eggs/uuid",
  "extra": "{\"action\":\"mark_turned\"}"
}
```

Validation zorunlu (notifications.md): unknown type → warning + home fallback.

## Calendar View
- Month view: `TableCalendar` widget (paket: `table_calendar`)
- Day detail: o gün eventlerinin listesi (chronological)
- Filter: event type checkbox (multi-select)
- Color coding: event type'a göre theme color

## Empty / Error State
- Empty day: "Bugün için etkinlik yok" + add event CTA
- Empty filter: "Bu filtrede etkinlik yok" + clear filter
- Network error (Supabase offline): cached events göster + offline banner (sync)

## Performance
- Month view fetch: tek query (range filter on `start_at`)
- Caching: 5dk TTL per month
- Notification schedule: batch (10+ event tek loop)
- Memory: 30 günden eski event'ler lazy load

## Sync Integration
- `event_reminders` ValidatedSyncMixin → parent (incubation, breeding_pair) silinmişse push iptal
- Conflict: server reminder time > local → re-schedule
- Notification ID re-compute on remote pull (re-schedule)

## Timezone
- Storage: UTC (datetime-format.md)
- Schedule: `tz.TZDateTime.from(eventTime, tz.local)` ZORUNLU
- DST sınırı: incubation_service türünden hesap kullanır (UTC midnight normalize)
- Multi-device: kullanıcı timezone değiştirirse local re-schedule

## Localization
- Event title l10n: `'calendar.event_${type}'.tr(namedArgs: {'name': entityName})`
- Date format: `DateFormat.yMMMd(locale)` + `DateFormat.Hm(locale)`
- Recurrence (örn. günde 4 kez): "Her gün 4 kez" → `.tr()`

## Recurrence (Basic)
- Şu an sadece basit recurrence: günlük (egg_turn), tek seferlik (milestone)
- iCalendar RRULE YOK (over-engineering)
- Custom event'lerde recurrence eklemek scope dışı

## Testing
- Unit: event generation deterministic (aynı input → aynı output)
- Unit: notification ID collision (farklı egg → farklı ID hash)
- Integration: reschedule on parent change (incubation start_date update)
- E2E: tap notification → correct route navigation

```dart
test('regenerates events when incubation date changes', () async {
  final original = Incubation(startDate: DateTime(2026, 5, 14));
  await service.scheduleAll(original);
  final originalReminderIds = await mockNotifications.scheduledIds();

  final updated = original.copyWith(startDate: DateTime(2026, 5, 16));
  await service.rescheduleAll(updated);

  final newIds = await mockNotifications.scheduledIds();
  expect(newIds, isNot(equals(originalReminderIds))); // ID'ler değişti
});
```

## Anti-Patterns
1. `DateTime.now()` ile schedule (notifications.md `tz.TZDateTime` zorunlu)
2. Notification ID random/timestamp (collision + re-schedule duplicate)
3. Parent silindiğinde reminder cancel etmemek (zombie notification)
4. Quiet hours honor etmemek
5. Recurrence için custom RRULE engine yazmak (over-engineering)
6. Calendar render'da UI thread'de event sıralama (büyük listede jank)
7. Deeplink payload validate etmeden navigate (crash riski)
8. Locale-agnostic date format (`DateFormat('dd/MM/yyyy')`)
9. Past event'leri Storage'tan silmeyi unutmak (DB bloat — 1 yıl üstü archive)
10. Event multi-time-zone'da `DateTime` UTC dönüşümünü atlamak (sync data corruption)

> **İlgili**: notifications.md (local notification, deeplink), datetime-format.md (UTC + tz.TZDateTime), background-sync.md (event_reminders ValidatedSyncMixin), breeding-eggs.md (auto event generation), forms-validation.md (custom event create)
