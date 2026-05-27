# Home Widget (iOS & Android)

iOS WidgetKit ve Android App Widgets üzerinden home screen + lock screen widget'ları. `HomeWidgetService` (`lib/domain/services/home_widget/`) ile Flutter ↔ native bridge.

## Stack
| Platform | Native | Bridge |
|----------|--------|--------|
| iOS 14+ | SwiftUI + WidgetKit | `home_widget` Flutter paket |
| Android API 21+ | RemoteViews + AppWidgetProvider | `home_widget` Flutter paket |
| Lock screen (iOS 16+) | WidgetKit family `.accessory*` | Same bridge |

## Widget Family
| Family | Boyut | Kullanım |
|--------|-------|----------|
| `systemSmall` | 2x2 | Aktif kuluçka sayacı |
| `systemMedium` | 4x2 | Aktif kuluçka + bugünün hatırlatması |
| `systemLarge` | 4x4 | Detaylı dashboard (aktif kuluçka listesi) |
| `accessoryCircular` | iOS lock screen circular | Kuluçka kalan gün |
| `accessoryRectangular` | iOS lock screen wide | Bugünün etkinliği |
| `accessoryInline` | iOS lock screen text | Tek satır status |

## Data Flow
```
Flutter app -> HomeWidgetService.write(key, value)
  -> Shared UserDefaults (iOS) / SharedPreferences (Android)
  -> Native widget reads on refresh
  -> Renders SwiftUI / RemoteViews
```

- Bridge sadece KEY-VALUE storage (JSON serialize edilebilir primitive)
- Native widget kendi UI'ını çizer (SwiftUI iOS, RemoteViews Android)
- Async fetch widget'ta YOK (sync read from shared storage)

## Refresh Triggers
- iOS: `WidgetCenter.shared.reloadAllTimelines()` — app içinden çağrı
- Android: `HomeWidget.updateWidget()` — broadcast intent
- Trigger noktaları:
  - Yeni kuluçka başlatma
  - Egg status değişimi
  - App resume (önemli değişiklik varsa)
  - Daily scheduled refresh (00:01 local time — gün geçişi)

## Update Frequency
- iOS WidgetKit budget: ~40 timeline update/day (Apple limit)
- Android: AppWidgetProvider configurable, default 30 dakika
- Over-refresh anti-pattern: her data change'de refresh ETME (battery + budget)
- Debounce: 1 dakika minimum interval

## Shared Storage Schema
```json
{
  "activeIncubationCount": 3,
  "nextHatchDate": "2026-05-30T08:00:00Z",
  "nextHatchBird": "Maviş",
  "todayEvents": [
    {"time": "10:00", "label": "Egg turn"},
    {"time": "18:00", "label": "Health check"}
  ],
  "syncStatus": "synced" // synced | syncing | offline
}
```

Native side aynı schema'yı parse eder. Field ekleme: hem Flutter hem native side update (release strategy).

## Empty State
- Aktif kuluçka yok: "Yeni kuluçka başlat" CTA → deeplink
- Tap → deeplink `/breeding/new` (router'da handle edilmeli)
- Network olmadan da görünür (cached data)

## Localization
- Native widget kendi locale'inden okur (iOS `Locale.current`, Android `Resources.getSystem().getConfiguration().locale`)
- Flutter app dili native'e push edilir (shared storage `locale` key)
- Çakışma: app dili sistem dilinden farklıysa app dili tercih

## Performance
- Shared storage write < 10ms
- Native widget render < 100ms (Apple guideline)
- Image asset: native bundled (Flutter assets erişilmez — copy to native side)
- Memory: native widget ~10MB max (Apple sınır)

## Tap Deeplink
- Widget tap → app açılır + route'a git
- iOS: `widgetURL(URL(string: "budgie://eggs/123"))`
- Android: `PendingIntent` with deeplink
- Router'da deeplink handler (notifications.md pattern ile aynı)

## Limitations
- Interactive widget YOK (iOS 17 desteği app-specific gerek — scope dışı)
- Real-time data YOK (timeline-based update)
- Animation kısıtlı (SwiftUI subset, RemoteViews simple)
- Push'tan widget update YOK (push → app open → app refresh widget)

## Testing
- Unit (Dart): `HomeWidgetService` write/read round-trip
- Manual (iOS): Simulator widget gallery → add widget → verify render
- Manual (Android): Widget picker → add → verify
- Snapshot widget asset (golden) YOK — native render, Flutter test scope dışı

## Anti-Patterns
1. Her data change'de widget refresh (timeline budget tükenir)
2. Async fetch widget render'da (UI bloklar, Apple reject)
3. Flutter asset'i native widget'ta erişmeye çalışmak (bundle ayrı)
4. Locale'i shared storage'a yazmayı unutmak (widget yanlış dil)
5. Tap deeplink'i validate etmeden navigate (crash riski, notifications.md aynı kural)
6. Lock screen widget'a hassas bilgi yazmak (PII — locked phone'da görünür)
7. Widget refresh'i background sync olmadan yapmak (offline'da stale data)
8. Shared storage'a büyük JSON yazmak (>1MB Apple budget aşar)
9. Native widget'ta network call (Apple guideline ihlali)
10. Real-time data beklemek (timeline-based, snapshot model)

> **İlgili**: notifications.md (deeplink payload), datetime-format.md (UTC + local display), background-sync.md (refresh trigger), assets-images.md (native bundle), localization.md (locale push)
