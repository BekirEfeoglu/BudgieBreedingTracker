# RevenueCat Fiyatlandırma Kurulumu

## Planlar

| Plan | Süre | Fiyat (USD) | RevenueCat Package Type |
|------|------|-------------|------------------------|
| Semi-Annual | 6 ay | $15.00 | `$rc_six_month` |
| Yearly | 1 yıl | $25.00 | `$rc_annual` |

Tasarruf: Yıllık plan, 6 aylığa göre **%17** daha avantajlı ($30 vs $25).

## 1. App Store Connect

1. **App Store Connect** > App > Subscriptions
2. Subscription Group oluştur: `budgie_premium`
3. İki ürün ekle:

| Product ID | Reference Name | Duration | Price |
|------------|---------------|----------|-------|
| `budgie_premium_semi_annual` | Premium 6 Months | 6 Month | $15.00 |
| `budgie_premium_yearly` | Premium Yearly | 1 Year | $25.00 |

4. Her ürün için localizations ekle (TR, EN, DE)
5. Review Information > Screenshot ekle
6. Gerekiyorsa introductory offer (7 gün free trial) ekle

## 2. Google Play Console

1. **Google Play Console** > App > Monetize > Subscriptions
2. Subscription oluştur: `budgie_premium`
3. İki base plan ekle:

| Base Plan ID | Billing Period | Price |
|-------------|---------------|-------|
| `semi-annual` | 6 months | $15.00 |
| `yearly` | 1 year | $25.00 |

4. Her plan için offer ekle (varsa free trial)
5. Tüm ülke fiyatlarını auto-convert et

## 3. RevenueCat Dashboard

1. **RevenueCat** > Project > Products
2. App Store ve Google Play ürünlerini import et
3. **Entitlements** > `premium` entitlement oluştur
4. Her iki platform ürününü `premium` entitlement'a bağla
5. **Offerings** > `default` offering oluştur
6. İki package ekle:

| Package | Type | App Store Product | Google Play Product |
|---------|------|-------------------|---------------------|
| `$rc_six_month` | Six Month | `budgie_premium_semi_annual` | `budgie_premium:semi-annual` |
| `$rc_annual` | Annual | `budgie_premium_yearly` | `budgie_premium:yearly` |

7. `default` offering'i current olarak ayarla

## 4. Uygulama Tarafı

Dart-define ile API key'leri set et:

```
REVENUECAT_API_KEY_IOS=appl_xxxxx
REVENUECAT_API_KEY_ANDROID=goog_xxxxx
```

Kod otomatik olarak:
- `matchPackageForPlan()` ile `$rc_six_month` / `$rc_annual` package'ları eşleştirir
- Store'dan gerçek fiyatı (`storeProduct.priceString`) çeker
- Store unavailable ise fallback fiyatları gösterir ($15 / $25)

## 5. Test

- **iOS**: Sandbox hesabı ile test et (Settings > App Store > Sandbox Account)
- **Android**: License testers ekle (Google Play Console > Setup > License testing)
- RevenueCat Dashboard > Customers'dan satın alma akışını doğrula
