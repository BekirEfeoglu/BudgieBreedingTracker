# Date & Time

Kuluçka takibi, etkinlik hatırlatma, mesajlaşma timestamp — yanlış timezone hesabı veri bozucu bug üretir. Kural: **Storage UTC, display local, math UTC**.

## Storage / Wire / Display Ayrımı
| Yer | Format | Tür |
|-----|--------|-----|
| Drift DB | ISO-8601 UTC | `DateTime` (Dart) — `.toUtc()` ile yazılır |
| Supabase | `timestamptz` UTC | JSON string ISO-8601 |
| Edge function | UTC | `new Date().toISOString()` |
| Notification schedule | `tz.TZDateTime` | timezone-aware |
| UI display | Local timezone | `DateFormat` + locale |
| Form input | Local | `showDatePicker` döner local |

## UTC at Boundary
Dış sistemle (Supabase, edge fn, push payload) değişen tüm `DateTime` UTC olmalı:
```dart
// CORRECT - server'a yazarken UTC
await client.from('birds').upsert({
  'hatch_date': bird.hatchDate.toUtc().toIso8601String(),
});

// WRONG - local timezone server'a sızar
await client.from('birds').upsert({
  'hatch_date': bird.hatchDate.toIso8601String(),  // local!
});
```

`.toSupabase()` extension bu dönüşümü zorunlu yapar — manuel JSON map'leme yapma.

## Display Formatting
- `intl` paketi (`DateFormat`)
- Locale `easy_localization` context'inden gelir (`Localizations.localeOf(context)`)
- Asla `DateFormat('dd.MM.yyyy')` hardcode locale — `DateFormat.yMd(locale.toString())`

```dart
final locale = context.locale.toString();  // 'tr', 'en', 'de'
Text(DateFormat.yMMMd(locale).format(bird.hatchDate))  // "14 Mayıs 2026"
Text(DateFormat.Hm(locale).format(notification.createdAt))  // "14:30"
```

### Relative Time
- `'now'`, `'5dk önce'`, `'dün'`, `'3 gün önce'`, `'14 Mayıs'`
- Helper: `RelativeTimeFormatter` (`lib/core/utils/relative_time.dart`)
- 1 hafta üstü tam tarih
- L10n key'leri: `time.minutes_ago`, `time.hours_ago`, `time.days_ago`

## Incubation Day Math
Kuluçka gün sayımı KRİTİK — yanlış hesap kullanıcının kuluçka rejimini bozar.

**Kural:** Gün farkı `DateTime.utc(y, m, d)` ile hesaplanır (saat dilimi atlanır), sadece tarih kısmı:
```dart
int incubationDay(DateTime layDate, DateTime today) {
  final start = DateTime.utc(layDate.year, layDate.month, layDate.day);
  final now = DateTime.utc(today.year, today.month, today.day);
  return now.difference(start).inDays + 1;  // +1 because day 1 = lay day
}
```

Saat dilimi sınırında yanlış sonuç vermesin diye `DateTime.utc(...)` ile sadece YIL-AY-GÜN kullan. `inDays` saat farkı 23:59 olduğunda 0 dönebilir — bu yüzden UTC midnight'a normalize et.

### Hatch Date Prediction
- Budgie: 18 gün (varsayılan)
- Hesap: `layDate.add(Duration(days: 18))` — local timezone'a duyarsız çünkü `.add(Duration(days:))` 24h ekler
- DST sınırı: yıl boyu bir kez, %0.1'den az kullanıcıyı etkiler — kabul edilir

## Notification Schedule
- `flutter_local_notifications` için `tz.TZDateTime` ZORUNLU
- Naive `DateTime` ile schedule bug üretir (DST yanlış, timezone yanlış)
```dart
import 'package:timezone/timezone.dart' as tz;

final scheduled = tz.TZDateTime.from(targetDateTime, tz.local);
await notifications.zonedSchedule(id, title, body, scheduled, details, ...);
```

`tz.initializeTimeZones()` ve `tz.setLocalLocation(...)` app start'ta çağrılır (`main.dart`).

## Form Date Pickers
- `showDatePicker` returns local `DateTime` — UTC'ye çevirmeden DB'ye yazma
- Sınırlar: gelecek tarih validation (`isAfter(DateTime.now())`)
- `firstDate` / `lastDate` makul aralık (5 yıl geçmiş, 1 yıl gelecek varsayılan)

## Timezone Display
- Kullanıcının cihaz timezone'unu kullan (DateTime.now() — sistem)
- Profil ayarında manuel timezone seçimi YOK (over-engineering)
- Toplulukta cross-timezone post: server timestamp UTC, her kullanıcı kendi local'inde görür

## Comparison Pitfalls
```dart
// WRONG - mixed timezone comparison
final localDate = DateTime.now();         // local
final dbDate = bird.createdAt;            // UTC from DB
final isToday = localDate.day == dbDate.day;  // BUG!

// CORRECT - normalize before compare
final today = DateTime.now().toUtc();
final isToday = bird.createdAt.year == today.year &&
                bird.createdAt.month == today.month &&
                bird.createdAt.day == today.day;
```

## Duration Math
- `inDays` vs gerçek gün farkı — DST sınırında 23h olabilir
- "23 gün önce" gibi UI metni için: kabul edilir hata payı
- Kritik domain math'i (incubation) için: UTC midnight normalize

## L10n Keys
| Pattern | Örnek |
|---------|-------|
| `time.now` | "Şimdi" |
| `time.minutes_ago` (n) | "{n} dakika önce" |
| `time.days_ago` (n) | "{n} gün önce" |
| `time.tomorrow` | "Yarın" |
| `incubation.day_n` (n) | "{n}. gün" |
| `breeding.duration_days` (n) | "{n} gün sürdü" |

## Testing
```dart
test('incubation day handles DST boundary', () {
  final layDate = DateTime(2026, 3, 28);  // DST sınırı öncesi
  final today = DateTime(2026, 4, 2);     // DST sonrası
  expect(incubationDay(layDate, today), 6);
});

test('hatch prediction adds 18 days regardless of DST', () {
  final layDate = DateTime(2026, 3, 25);
  final hatch = layDate.add(const Duration(days: 18));
  expect(hatch.day, 12);
  expect(hatch.month, 4);
});

test('storage uses UTC ISO string', () {
  final bird = Bird(hatchDate: DateTime(2026, 5, 14, 10, 0));
  final supabase = bird.toSupabase();
  expect(supabase['hatch_date'], endsWith('Z'));  // UTC marker
});
```

## Anti-Patterns
1. Naive `DateTime` schedule (timezone bug — `tz.TZDateTime` zorunlu)
2. Local timezone Supabase'e yazmak (multi-device sync bozulur)
3. Hardcode locale `DateFormat('dd.MM.yyyy')` (Almanca farklı format ister)
4. Saat dilimi atlamadan gün farkı hesabı (`inDays` 23:59'da 0 döner)
5. UTC `DateTime`'ı UI'da olduğu gibi göstermek (kullanıcı kendi timezone'unu bekler)
6. Profil'de manuel timezone alanı (over-engineering)
7. `.toIso8601String()` kullanıp `.toUtc()` atlamak
8. Incubation math'i floating-point veya saat-bazlı yapmak (sadece tarih kısmı)

> **İlgili**: data-layer.md (.toSupabase), notifications.md (tz.TZDateTime schedule), localization.md (DateFormat locale), edge-functions.md (UTC wire)
