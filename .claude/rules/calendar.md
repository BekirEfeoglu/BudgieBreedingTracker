# Calendar & Reminders

Etkinlik takvimi: kuluçka milestone'ları, yumurta çevirme hatırlatması, breeding ramping, custom user event'ler. `CalendarEventGenerator` (`lib/domain/services/calendar/`) ve `lib/features/calendar/`.

## Stack
| Bileşen | Yer |
|---------|-----|
| Service | `CalendarEventGenerator` (`lib/domain/services/calendar/calendar_event_generator.dart`) |
| Feature | `lib/features/calendar/` |
| Reminder service | `NotificationScheduler` (`lib/domain/services/notifications/notification_scheduler.dart`) |
| Local notification | `flutter_local_notifications` (notifications.md) |
| Storage | Drift `events` + `event_reminders` tables |
| Sync | ValidatedSyncMixin ile parent FK kontrol |

## Event Tipleri
Tek kaynak `EventType` (`lib/core/enums/event_enums.dart`) — **18 üye**:
`unknown, custom, breeding, health, feeding, cleaning, mating, egg, chick,
hatching, eggLaying, healthCheck, medication, vaccination, weightCheck,
cageChange, banding, other`.

Serileştirme `toJson() => name` / `fromJson => values.byName(...)` olduğu için
değerler **camelCase**'tir; `health_check`/`egg_turn` gibi snake_case bir string
`byName` ile eşleşmez ve `EventType.unknown`'a düşer. Doküman/payload yazarken
enum adını birebir kullan.

`CalendarEventGenerator`'ın gerçekten ürettiği tipler:

| `EventType` | Kaynak | Otomatik mi? |
|-------------|--------|--------------|
| `breeding` | Kuluçka milestone'ları (fertile check, hatch day — `incubationId` FK'siyle) | Otomatik |
| `eggLaying` | Yumurta kaydı | Otomatik |
| `hatching` | Beklenen çıkım tarihi | Otomatik |
| `chick` | Yavru gelişim aşamaları (1. hafta, sütten kesme) | Otomatik |
| `banding` | Halkalama günü (`chickId` FK'siyle) | Otomatik |
| Form'da seçilen herhangi bir `EventType` | `EventFormNotifier.createEvent` | Manuel |

`incubation_start`, `egg_turn`, `incubation_milestone`,
`breeding_pair_introduction`, `chick_milestone` diye tip YOKTUR — bunlar önceki
bir tasarım adlandırmasıydı. Yumurta çevirme takvim event'i değil, ayrı bir
local-notification akışıdır (`NotificationScheduler`, `egg_turning` kanalı).

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

Manuel takvim event'lerinde (`EventFormNotifier.createEvent`) hatırlatma
offset'i **kullanıcı seçimlidir** (2026-07-03): event formundaki dropdown
`kReminderOffsetOptions` (`calendar_form_providers.dart`) üzerinden
_hatırlatma yok / etkinlik anında (0) / 30 dk / 1 saat / 1 gün önce_
seçtirir; varsayılan `kDefaultReminderMinutesBefore` (30 dk, eski davranış).
`createEvent`'in `reminderMinutesBefore` parametresi `null` ise hiç reminder
oluşturulmaz. **Edit — shipped (2026-07-09):** dropdown artık düzenlemede de
gösterilir; form açılışında `_loadExistingReminder` mevcut reminder offset'ini
`eventReminderRepository.getByEvent` ile yükler (yoksa "hatırlatma yok").
Kaydetme `updateEvent(..., reminderMinutesBefore:, reconcileReminder: true)`
ile reconcile eder: eski reminder(ler) iptal + silinir (`_cleanupRemindersForEvent`
OS bildirimini de iptal eder), sonra yeni offset seçildiyse yeniden oluşturulur
(cancel+reschedule pattern). `reconcileReminder: false` (diğer caller'lar, örn.
status değişimi) eski davranışı korur: reminder yalnızca tarih kaydığında
re-arm edilir. Otomatik kuluçka/yumurta-çevirme hatırlatmaları ayrı bir sistemdir
(`NotificationScheduler`, `event_reminders` tablosunu kullanmaz — bkz. ID
Stability). Quiet hours (notifications.md) her iki sistemde de honored.

## ID Stability
Notification ID deterministik, `NotificationIds.generate()` (`lib/domain/services/notifications/notification_ids.dart`) ile üretilir — raw `.hashCode` DEĞİL, FNV-1a hash ile kategori başına 100.000 ID'lik, entity başına 100 ID'lik partition'lanmış bir alana dağıtılır (daha iyi collision dağılımı için).
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
Payload bir **`type:id` string**'idir (JSON DEĞİL) ve rota
`NotificationChannelConfig.payloadToRoute` ile ÇÖZÜLÜR — payload'da `route`
alanı taşınmaz. Takvim/kuluçka tarafının ürettiği gerçek payload'lar:
`'incubation:$incubationId'`, `'egg_turning:$eggId'`, `'chick_care:$chickId'`,
`'banding:$chickId'`, `'health_check:$birdId'`.

Eşleme (`payloadToRoute`): `breeding|incubation → /breeding/<id>` ·
`bird → /birds/<id>` · `chick|chick_care|banding → /chicks/<id>` ·
`egg|egg_turning → /breeding` (id'siz — bu payload'lar egg ID'si taşır, pair
ID'si değil; `/eggs/<id>` diye bir rota yoktur) ·
`health_check → /health-records/<id>` · `event|event_reminder|calendar →
/calendar` · `notification → /notifications` · diğer → `null`.

Validation zorunlu (notifications.md): id-enjekte eden rotalarda
`isValidRouteId` kontrolü; bilinmeyen tip → `null` + `AppLogger.warning`.

## Calendar View
- Month view: `CalendarGrid` (custom `lib/features/calendar/widgets/calendar_grid.dart`, 7-column grid — NOT the `table_calendar` package, not a dependency)
- Day detail: o gün eventlerinin listesi (chronological)
- Filter: event type checkbox (multi-select)
- Filtre TEK geçiş: month/week/day provider'ları `filteredCalendarEventsProvider`'dan türetilir (`calendar_providers.dart`) — `filterCalendarEvents` (stream, filtre) değişimi başına BİR kez koşar; view provider'larına yeniden inline filtreleme EKLEME
- Color coding: event type'a göre theme color

## Empty / Error State
- Empty day: "Bugün için etkinlik yok" + add event CTA
- Empty filter: "Bu filtrede etkinlik yok" + clear filter
- Network error (Supabase offline): cached events göster + offline banner (sync)

## Performance
- **Gerçek okuma yolu: range query DEĞİL.** `eventsStreamProvider` kullanıcının
  TÜM event'lerini `EventRepository.watchAll(userId)` Drift stream'iyle çeker;
  ay/gün süzmesi `filteredCalendarEventsProvider` → `eventsForMonthProvider` /
  `eventsForSelectedDateProvider` içinde bellekte yapılır
- Tarih kolonu **`eventDate`** (Supabase `event_date`) — `start_at` diye bir
  kolon yoktur
- `EventRepository.watchByDateRange` / `EventsDao.watchByDateRange` mevcuttur
  ama calendar feature'ında **çağıranı yoktur** (yalnız DAO testleri kullanır).
  Ay bazlı sorguya geçilecekse bu metoda bağlan ve burayı güncelle
- Filtre tek geçiş: `filteredCalendarEventsProvider` (bkz. § Calendar View) —
  view provider'larına inline filtre EKLEME
- TTL'li ay cache'i ve "30 günden eski event lazy load" **shipped DEĞİL**
  (`obsidian-brain/known-gaps.md`); tüm event'ler stream'de tutulur
- Notification schedule: batch (10+ event tek loop)

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
