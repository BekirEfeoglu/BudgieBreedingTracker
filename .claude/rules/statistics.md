# Statistics & Charts

Kuluçka analitiği, başarı oranları, mutasyon dağılımı, breeding pair performansı. `lib/features/statistics/` + `fl_chart ^1.2.0` ile render. Veri Drift query'lerinden gelir (offline-first).

## Stack
| Bileşen | Yer |
|---------|-----|
| Feature | `lib/features/statistics/` (providers, screens, widgets) |
| Chart lib | `fl_chart ^1.2.0` |
| Models | `statistics_models.dart` (Freezed) |
| Providers | `statistics_breeding_providers.dart`, `statistics_*_providers.dart` |
| Data source | Drift query'leri (local-first) |

## Chart Tipleri
| Tip | Kullanım |
|-----|----------|
| LineChart | Zaman serisi (aylık kuluçka, başarı oranı trend) |
| BarChart | Kategorik karşılaştırma (mutasyon dağılımı, türlere göre) |
| PieChart | Yüzdesel dağılım (gender ratio, fertile/infertile) |
| ScatterChart | Korelasyon (parent genotype × hatch success) — rare use |
| RadarChart | Multi-axis profil (yetenek skoru) — premium feature |

## Tasarım Prensipleri
- Theme.of(context).colorScheme kullan (hardcoded renk YOK — exception: phenotype color)
- Dark mode test edilmiş (axis label kontrast)
- Touch interaction: tap → tooltip, drag → range select
- Accessibility: semantic label per data point
- L10n: axis label, legend, tooltip — `.tr()`

## Veri Hesaplama
- Aggregation Drift'te (`groupBy`, `sum`, `count`) — büyük listeyi UI'a getirip orada hesap YAPMA
- Cache: hesap sonucu Riverpod provider'da, dependency değişince invalidate
- TTL: 5dk (statistics değişim sıklığı düşük)
- Realtime gereksiz — manuel refresh + pull-to-refresh yeterli

```dart
@riverpod
Future<HatchSuccessByMonth> hatchSuccessByMonth(Ref ref) async {
  ref.keepAlive(); // expensive — keep
  final dao = ref.read(eggDaoProvider);
  return dao.aggregateHatchByMonth(); // SQL: GROUP BY month
}
```

## Performans Budget
| İşlem | Budget |
|-------|--------|
| Initial chart render | < 200ms |
| Data fetch (cached) | < 50ms |
| Data fetch (cold) | < 500ms |
| Interaction (tap tooltip) | < 16ms (60fps) |
| Memory: chart screen | < 30MB |

100+ data point'li chart → downsample (LTTB algorithm) UI'da. Chart limit: 50 görünür point ideal, daha fazla data zoom-required.

## Filtre & Zaman Aralığı
- Default: son 6 ay (`StatsPeriod.sixMonths`)
- Preset: 3/6/12 ay (`StatsPeriod.threeMonths/sixMonths/twelveMonths`) — gün bazlı preset veya custom range YOK
- Species filter: opsiyonel, `null` = tüm türler
- Filter state: `Notifier` provider, SharedPreferences'a persist edilir (`AppPreferences.keyStatsPeriod`/`keyStatsSpeciesFilter`) — session-only DEĞİL, oturumlar arası korunur

## Empty / Insufficient Data
- Yeni kullanıcı: "İstatistikler için en az 1 kuluçka tamamlayın" + CTA
- Filter empty (range içinde data yok): "Bu aralıkta veri yok" + range reset CTA
- Insufficient (< 3 data point): chart yerine table göster (chart yanıltıcı olur)

## Export (Premium)
- PDF export: `lib/domain/services/export/pdf_export_service.dart`, `StatisticsScreen` app bar aksiyonu
- Excel export YOK — sadece PDF (personal records + season comparison + health trend summary)
- Export'un kendi ayrı gate'i YOK — `/statistics` rotasına giren herkes (premium abone VEYA aktif reward) export'a erişir; free preview modu YOK (bkz. Premium Features)

## Realtime Update
- Statistics realtime YOK (pull model)
- Bird/Egg insert → provider invalidate (dependent stats refresh)
- Background sync sonrası batch invalidate

## Premium Features
`/statistics` rotası all-or-nothing gate'lidir — kısmi free preview YOK:

- Route guard (`app_router.dart`): `effectivePremiumProvider` **VEYA** aktif
  `isStatisticsRewardActiveProvider` (ödüllü reklam ile geçici erişim)
  gerekir; ikisi de yoksa `AppRoutes.premium`'a redirect.
- Reward ile geçici giren kullanıcı ekran içinde premium abone ile **aynı**
  erişime sahiptir — PDF export, season comparison (compare period), 3/6/12
  ay preset'lerinin hepsi reward süresi boyunca kısıtlamasız çalışır.
- Custom date range, "AI insight" ve chart-sayısı bazlı free/premium ayrımı
  (örn. "3 chart free") **implement edilmemiştir** — bu tablo önceki bir
  tasarım hedefiydi, gerçek kodla eşleşmiyordu (2026-07-01 audit).
- Reward-tier ile paid-premium arasında ekran içi ayrım isteniyorsa (örn.
  export'u sadece paid-premium'a kısıtlamak) bu ayrı bir ürün kararı ve ayrı
  bir gate gerektirir — henüz yok.

## L10n Considerations
- Sayı formatı locale-aware (`NumberFormat.decimalPercentPattern(locale: 'tr')`)
- Tarih: `DateFormat.MMM(locale)` ay isimleri (Oca, Şub vs Jan, Feb)
- RTL safe (gelecek): `EdgeInsetsDirectional`

## Accessibility
- Chart için tabular view alternatifi (screen reader)
- Color-blind safe palette (ColorBrewer Set2 veya benzeri)
- Sadece renk ile bilgi iletme — pattern + icon + value combo

## Anti-Patterns
1. Aggregation'ı UI thread'de yapmak (1000+ row → jank)
2. Hardcoded chart color (theme aware değil, dark mode bozulur)
3. Realtime subscription chart screen'de (gereksiz network + battery)
4. Insufficient data'da yanıltıcı chart çizmek (1 point line chart anlamsız)
5. Export'u free user'a vermek (premium UVP düşer)
6. Chart tooltip'inde locale-aware number format atlama
7. fl_chart `LineChart` constructor'da tüm data'yı re-pass (rebuild jank)
8. PNG export için widget'ı invisible olarak render etmek (memory leak + race)
9. AI insight'ı statistics ile aynı provider'da bundle (local-ai.md ayrı path)
10. Chart screen'i `ConsumerStatefulWidget` yerine `ConsumerWidget` (filter state nereye?)

> **İlgili**: data-layer.md (Drift aggregation), local-ai.md (insight), premium-revenuecat.md (gating), data-io.md (export), datetime-format.md (locale format), performance.md (chart budget)
