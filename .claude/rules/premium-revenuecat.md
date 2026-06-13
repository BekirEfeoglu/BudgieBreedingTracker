# Premium & RevenueCat

Premium abonelik akışı RevenueCat üzerinden yönetilir, ama yetkilendirme **sunucu tarafından doğrulanır**. İstemcide premium durumu cache'lenebilir; ödeme kararına asla istemci-only kanıt yeterli değildir.

## Stack
| Katman | Araç |
|--------|------|
| Store | App Store + Google Play |
| Aggregator | RevenueCat (`purchases_flutter ^10.0.2`) |
| Server verify | Supabase Edge Function `sync-premium-status` |
| Client state | `premiumStatusProvider` (Riverpod) |
| Route guard | `PremiumGuard` (`lib/router/guards/`) |

## Entitlement Flow
```
User purchases (RevenueCat) -> RevenueCat webhook -> sync-premium-status edge fn
  -> Server validates with REVENUECAT_SECRET_API_KEY
  -> Updates user.is_premium + entitlement metadata in Supabase
  -> Client refreshes premiumStatusProvider on app resume / push
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
```dart
class PremiumGuard {
  static FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context);
    final status = container.read(premiumGracePeriodProvider);
    return switch (status) {
      GracePeriodStatus.active || GracePeriodStatus.gracePeriod => null,
      GracePeriodStatus.expired || GracePeriodStatus.none => AppRoutes.premiumUpsell,
    };
  }
}
```

## Subscription Plan Restrictions
- Sadece **iki** premium plan aktif (314c274 commit, 2026-05-14)
- Yeni plan eklemek: hem RevenueCat dashboard hem `PremiumPlanConfig` Dart sabiti güncellenmeli
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
- Unit: `PremiumService` mock'lanır, gerçek RevenueCat çağrısı YOK
- Integration: edge function test'i `sync-premium-status/test.ts` içinde
- Manual QA: TestFlight sandbox + Play internal testing track
- `RevenueCatPaywall` golden test edilebilir

## Anti-Patterns
1. İstemci-only premium check (`isPremium` flag'i kandırılabilir — server doğrulama zorunlu)
2. Grace period'u görmezden gelmek (ödeyen kullanıcıyı kapatır)
3. Free tier limit'i istemcide hardcode etmek (edge function source of truth)
4. `REVENUECAT_SECRET_API_KEY`'i istemci koduna sızdırmak
5. Restore Purchases butonunu kaldırmak (App Store rejection)
6. Eski plan'lara sahip kullanıcı için kod path'i hemen silmek (entitlement bitimine kadar bekle)
7. RevenueCat webhook'unu test edip edge function'ı atlatmak (race condition)

> **İlgili**: security.md (env vars), edge-functions.md (sync-premium-status, validate-free-tier-limit), error-handling.md (FreeTierLimitException), release-ops.md (store policies)
