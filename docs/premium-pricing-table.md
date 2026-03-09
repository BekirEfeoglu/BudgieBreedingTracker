# Premium Pricing Table

Updated: 2026-03-08

## Onerilen Fiyatlar

| Plan | RevenueCat Package | iOS Product ID | Android Product | TR Fiyat | USD Fiyat | Not |
|---|---|---|---|---:|---:|---|
| Monthly | `$rc_monthly` | `budgie_premium_monthly` | `budgie_premium:monthly` | `TRY 129.99 / month` | `USD 4.99 / month` | Giris plani |
| Yearly | `$rc_annual` | `budgie_premium_yearly` | `budgie_premium:yearly` | `TRY 799.99 / year` | `USD 34.99 / year` | Ana plan, one cikacak plan |
| Lifetime | `$rc_lifetime` | `budgie_premium_lifetime` | `budgie_premium_lifetime` | `TRY 1999.99` | `USD 89.99` | Tek seferlik satin alim |

## App Store

| Storefront | Plan | Urun Tipi | Product ID | Fiyat | Teklif |
|---|---|---|---|---:|---|
| TR | Monthly | Auto-renewable subscription | `budgie_premium_monthly` | `TRY 129.99` | Trial yok |
| TR | Yearly | Auto-renewable subscription | `budgie_premium_yearly` | `TRY 799.99` | `7 gun free trial` |
| TR | Lifetime | Non-consumable | `budgie_premium_lifetime` | `TRY 1999.99` | Tek seferlik |
| US | Monthly | Auto-renewable subscription | `budgie_premium_monthly` | `USD 4.99` | Trial yok |
| US | Yearly | Auto-renewable subscription | `budgie_premium_yearly` | `USD 34.99` | `7 day free trial` |
| US | Lifetime | Non-consumable | `budgie_premium_lifetime` | `USD 89.99` | Tek seferlik |

## Google Play

| Storefront | Plan | Urun Tipi | Product ID | Fiyat | Teklif |
|---|---|---|---|---:|---|
| TR | Monthly | Subscription base plan | `budgie_premium:monthly` | `TRY 129.99` | Trial yok |
| TR | Yearly | Subscription base plan | `budgie_premium:yearly` | `TRY 799.99` | `7 gun free trial offer` |
| TR | Lifetime | One-time product | `budgie_premium_lifetime` | `TRY 1999.99` | Tek seferlik |
| US | Monthly | Subscription base plan | `budgie_premium:monthly` | `USD 4.99` | Trial yok |
| US | Yearly | Subscription base plan | `budgie_premium:yearly` | `USD 34.99` | `7 day free trial offer` |
| US | Lifetime | One-time product | `budgie_premium_lifetime` | `USD 89.99` | Tek seferlik |

## Hizli Karsilastirma

| Karsilastirma | TR | USD |
|---|---:|---:|
| Monthly x12 | `TRY 1559.88` | `USD 59.88` |
| Yearly | `TRY 799.99` | `USD 34.99` |
| Yearly tasarruf | `yaklasik 49%` | `yaklasik 42%` |
| Lifetime / Yearly carpani | `2.5x` | `2.57x` |

## RevenueCat Esleme

| RevenueCat Offering | Package | iOS Product | Android Product |
|---|---|---|---|
| `default` | `$rc_monthly` | `budgie_premium_monthly` | `budgie_premium:monthly` |
| `default` | `$rc_annual` | `budgie_premium_yearly` | `budgie_premium:yearly` |
| `default` | `$rc_lifetime` | `budgie_premium_lifetime` | `budgie_premium_lifetime` |

## Notlar

- `premium` entitlement bu 3 urune bagli kalmali.
- `7 gun trial` sadece yearly planda acilmali.
- Android tarafinda `budgie_premium` subscription altinda `monthly` ve `yearly` base plan acilmali.
- iOS tarafinda `Monthly` ve `Yearly` ayni subscription group icinde olmali; `Lifetime` ayri non-consumable olmali.
