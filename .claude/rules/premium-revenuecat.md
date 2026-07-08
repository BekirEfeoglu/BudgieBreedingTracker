# Premium & RevenueCat

Premium abonelik akışı RevenueCat üzerinden yönetilir, ama yetkilendirme **sunucu tarafından doğrulanır**. İstemcide premium durumu cache'lenebilir; ödeme kararına asla istemci-only kanıt yeterli değildir.

## Stack
| Katman | Araç |
|--------|------|
| Store | App Store + Google Play |
| Aggregator | RevenueCat (`purchases_flutter ^10.2.3`) |
| Server verify | Supabase Edge Function `sync-premium-status` |
| Client state | `isPremiumProvider` / `premiumGracePeriodProvider` / `effectivePremiumProvider` (`lib/domain/services/premium/premium_providers.dart`) |
| Route guard | `PremiumGuard` (`lib/router/guards/premium_guard.dart`) |

## Entitlement Flow
```
User purchases (RevenueCat) -> RevenueCat webhook -> sync-premium-status edge fn
  -> Server validates with REVENUECAT_SECRET_API_KEY
  -> Updates user.is_premium + entitlement metadata in Supabase
  -> Client refreshes premium providers on app resume (ResumeThrottle: max 1/5dk) / push
```

İstemci RevenueCat SDK'sını **sadece purchase UX'i için** kullanır. Premium gate kararı her zaman sunucu kaynaklı (`profiles.is_premium`) okumadan verilir.

## Grace Period
- `premiumGracePeriodProvider` ödeme yenileme hatası sonrası kısa süreli erişim verir
- Guard'lar `GracePeriodStatus.gracePeriod` durumunu **passing** kabul etmelidir, sadece `isPremium == true` değil
- Grace dolduğunda UI banner ile kullanıcıyı bilgilendir (l10n: `premium.grace_period_ending`)

```dart
// CORRECT - grace period saygısı
final status = ref.watch(premiumGracePeriodProvider);
if (status == GracePeriodStatus.expired) {
  return PremiumUpsellScreen();
}

// WRONG - grace period'u atlar, ödeyen kullanıcıyı kapatır
final isPremium = ref.watch(isPremiumProvider);
if (!isPremium) return PremiumUpsellScreen();
```

## Free Tier Limits
- Limitler **sunucu tarafında** `validate-free-tier-limit` edge function ile uygulanır
- İstemci limit'i bilebilir (UX için "3/5 kuş eklediniz") ama bypass edemez
- Entity insert path'i edge function'ı çağırır; başarısız olursa `FreeTierLimitException` fırlat
- Hardcoded limit istemci kodda yok — edge function tek kaynak

```dart
// Limit gösterimi (UX), kararı değil
final usage = ref.watch(freeTierUsageProvider);
Text('${usage.current}/${usage.limit} ${'birds.birds'.tr()}')

// Karar her zaman insert'te edge function'dan döner
try {
  await birdRepository.insert(bird);
} on FreeTierLimitException {
  showUpsellDialog();
}
```

## PremiumGuard
Gerçek imza `bool` alır — provider okuma çağıran route builder'da yapılır, guard içinde değil (`lib/router/guards/premium_guard.dart`):
```dart
class PremiumGuard {
  static String? redirect(bool hasEffectiveAccess) {
    return hasEffectiveAccess ? null : AppRoutes.premium;
  }
}
```
`GracePeriodStatus` enum değerleri: `active`, `gracePeriod`, `expired`, `free`, `unknown` (`lib/core/enums/subscription_enums.dart`) — `none` diye bir değer YOK.

`PremiumGuard.redirect` şu an sadece `/genealogy` route'unda kullanılıyor. `/statistics` ve `/genetics` gibi diğer premium route'lar `effectivePremiumProvider` **VEYA** geçici rewarded-ad erişimi (`isStatisticsRewardActiveProvider`, `isGeneticsRewardActiveProvider`) ile ayrı ayrı gate'lenir (`app_router.dart` içinde inline) — bkz. statistics.md § Premium Features.

## Subscription Plan Restrictions
- Sadece **iki** premium plan aktif (314c274 commit, 2026-05-14)
- Yeni plan eklemek: hem RevenueCat dashboard hem `lib/domain/services/premium/premium_plan_utilities.dart` güncellenmeli
- Trial period: sadece App Store free trial — Android tarafında "intro pricing" kullan
- Eski plan'a sahip kullanıcılar entitlement süresi dolana kadar korunur, kod path silinmez

## Environment
| Var | Tür | Nerede |
|-----|-----|--------|
| `REVENUECAT_API_KEY_IOS` | dart-define | İstemci, public |
| `REVENUECAT_API_KEY_ANDROID` | dart-define | İstemci, public |
| `REVENUECAT_SECRET_API_KEY` | Edge Function secret | Sunucu only, asla istemcide |

## Restore Purchases
- iOS App Store policy: "Restore Purchases" butonu zorunlu (`Settings > Premium`)
- `Purchases.restorePurchases()` → RevenueCat → sync-premium-status → provider invalidate
- Restore akışında loading + success/failure feedback ver (l10n: `premium.restore_success`, `premium.restore_failed`)

## Testing
- Unit: RevenueCat `Purchases` çağrıları mock'lanır, gerçek çağrı YOK
- Integration: edge function test'i `sync-premium-status/test.ts` içinde
- Manual QA: TestFlight sandbox + Play internal testing track
- Paywall ekranı golden test edilebilir

## Anti-Patterns
1. İstemci-only premium check (`isPremium` flag'i kandırılabilir — server doğrulama zorunlu)
2. Grace period'u görmezden gelmek (ödeyen kullanıcıyı kapatır)
3. Free tier limit'i istemcide hardcode etmek (edge function source of truth)
4. `REVENUECAT_SECRET_API_KEY`'i istemci koduna sızdırmak
5. Restore Purchases butonunu kaldırmak (App Store rejection)
6. Eski plan'lara sahip kullanıcı için kod path'i hemen silmek (entitlement bitimine kadar bekle)
7. RevenueCat webhook'unu test edip edge function'ı atlatmak (race condition)

> **İlgili**: security.md (env vars), edge-functions.md (sync-premium-status, validate-free-tier-limit), error-handling.md (FreeTierLimitException), release-ops.md (store policies)
