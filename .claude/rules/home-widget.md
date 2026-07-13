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
Flutter app -> HomeWidgetService.syncDashboardSnapshot(HomeWidgetDashboardSnapshot)
  -> HomeWidgetGateway.saveInt/saveString/saveBool (tipli key-value)
  -> Shared UserDefaults (iOS app group) / SharedPreferences (Android)
  -> gateway.updateWidget(...) native refresh tetikler
  -> Renders SwiftUI / RemoteViews
```

- Tek public API `syncDashboardSnapshot` — serbest `write(key, value)` YOK; key'ler `AppHomeWidgetConstants` sabitleridir
- Native widget kendi UI'ını çizer (SwiftUI iOS, RemoteViews Android)
- Async fetch widget'ta YOK (sync read from shared storage)
- Sync hatası best-effort: `AppLogger.error`, app akışını bozmaz

## Refresh Triggers (gerçek)
- Flutter tarafı: `home_screen.dart`'taki `ref.listen(homeWidgetDashboardSnapshotProvider(userId))` — snapshot değişince `syncDashboardSnapshot` çağrılır (o da native `updateWidget`'ı tetikler)
- iOS ayrıca timeline self-refresh: `nextRefreshDate()` ~+30 dk (`BudgieDashboardWidget.swift`)
- "00:01 daily scheduled refresh" diye ayrı bir zamanlayıcı YOK

## Update Frequency
- iOS WidgetKit budget: ~40 timeline update/day (Apple limit)
- Android: AppWidgetProvider configurable, default 30 dakika
- Over-refresh anti-pattern: her data change'de refresh ETME (battery + budget)
- Debounce: 1 dakika minimum interval

## Shared Storage Schema (gerçek — `AppHomeWidgetConstants`, tipli key-value)
| Key | Tip | İçerik |
|-----|-----|--------|
| `egg_turning_count` | int | Bugün çevrilecek yumurta sayısı |
| `active_breedings_count` | int | Aktif kuluçka/çift sayısı |
| `next_turning_label` | string | Sıradaki çevirme etiketi |
| `has_work_today` | bool | Bugün iş var mı |
| `last_updated_label` | string | Son güncelleme etiketi |
| `last_updated_epoch_seconds` | int | Son güncelleme zamanı |

JSON blob YOK — her alan ayrı tipli key. Field ekleme: `AppHomeWidgetConstants` + `HomeWidgetDashboardSnapshot` + native side (Swift/Kotlin) birlikte güncellenir (release strategy).

## Empty State
- Aktif kuluçka yok: "Yeni kuluçka başlat" CTA → deeplink
- Tap → deeplink `/breeding/new` (router'da handle edilmeli)
- Network olmadan da görünür (cached data)

## Localization (gerçek — sistem locale)
- Native widget SİSTEM dilini kullanır (iOS `NSLocalizedString` — `BudgieDashboardWidget.swift` `WidgetCopy.t`; Android resources)
- Shared storage'a `locale` key'i YAZILMAZ — app-dili push mekanizması yok. App dili sistem dilinden farklıysa widget sistem dilinde kalır (bilinen sınırlama); app-locale push eklenirse bu bölüm + snapshot şeması birlikte güncellenmeli

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
4. Widget metnini Flutter'dan localize edilmiş string olarak yollarken sistem-locale ayrımını unutmak (label snapshot'ta app dilinde, statik copy native'de sistem dilinde — karışım tutarsız dil üretir)
5. Tap deeplink'i validate etmeden navigate (crash riski, notifications.md aynı kural)
6. Lock screen widget'a hassas bilgi yazmak (PII — locked phone'da görünür)
7. Widget refresh'i background sync olmadan yapmak (offline'da stale data)
8. Shared storage'a büyük JSON yazmak (>1MB Apple budget aşar)
9. Native widget'ta network call (Apple guideline ihlali)
10. Real-time data beklemek (timeline-based, snapshot model)

> **İlgili**: notifications.md (deeplink payload), datetime-format.md (UTC + local display), background-sync.md (refresh trigger), assets-images.md (native bundle), localization.md (locale push)
