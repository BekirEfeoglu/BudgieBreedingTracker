# Premium & RevenueCat

Premium abonelik akışı RevenueCat üzerinden yönetilir, ama yetkilendirme **sunucu tarafından doğrulanır**. İstemcide premium durumu cache'lenebilir; ödeme kararına asla istemci-only kanıt yeterli değildir.

## Stack
| Katman | Araç |
|--------|------|
| Store | App Store + Google Play |
| Aggregator | RevenueCat (`purchases_flutter ^10.4.2`) |
| Server verify | Supabase Edge Function `sync-premium-status` |
| Client state | `isPremiumProvider` / `premiumGracePeriodProvider` / `effectivePremiumProvider` (`lib/domain/services/premium/premium_providers.dart`) |
| Route guard | `PremiumGuard` (`lib/router/guards/premium_guard.dart`) |

## Entitlement Flow
```
User purchases (RevenueCat SDK) -> sync-premium-status edge fn
  -> Server validates with REVENUECAT_SECRET_API_KEY
  -> Atomically updates profile + subscription metadata in Supabase
  -> Verified response is applied to Drift without creating pending client writes

RevenueCat webhook -> refetches the full subscriber state
  -> uses the same atomic status RPC -> client receives the change on pull/stream
```

İstemci RevenueCat SDK'sını **sadece purchase UX'i için** kullanır. Premium gate kararı her zaman sunucu kaynaklı (`profiles.is_premium`) okumadan verilir.

- Satın alma/restore, `sync-premium-status` başarılı olmadan UI'da başarı sayılmaz.
- RevenueCat satın alma/restore sonucu aktif entitlement döndürür fakat sunucu
  mutabakatı henüz aynı receipt'i görmezse istemci premium iddiası göndermez;
  500 ms ve 1500 ms bekleyerek en fazla iki kez daha
  `sync-premium-status` çağırır. Yalnızca doğrulanmış sunucu yanıtı erişimi açar.
- `Profile.toSupabase()`; `is_premium`, `subscription_status`, `role`,
  `premium_expires_at` ve `grace_period_until` alanlarını hiçbir client upsert'ine
  dahil etmez.
- RevenueCat init/login/logout işlemleri tek bir seri kuyrukta çalışır; kullanıcı
  değişimi sırasında eski kullanıcının tamamlanan init sonucu yeni kimliğe sızmaz.
- Webhook geçici DB/profil yarışlarında `503 + Retry-After` döndürür. Tekrar
  teslim güvenlidir; handler tam subscriber durumunu yeniden okuyup kullanıcı
  bazlı atomik RPC uygular.

### Admin Manual Override
- `user_subscriptions.provider = 'manual'`, admin tarafından verilmiş açık bir
  premium kararıdır. `status = active|trial` premium açık; diğer durumlar kapalıdır.
- `sync-premium-status` ve `revenuecat-webhook`, founder/admin rol kontrolünden
  sonra bu kaydı RevenueCat'e gitmeden okur ve manuel kararı korur.
- RevenueCat kaynaklı upsert/update'ler `provider = 'revenuecat'` yazar; kaynak
  belirsiz bırakılmaz.
- `admin_grant_premium` ve `admin_revoke_premium` profile + subscription + audit
  değişikliklerini tek server-side RPC içinde yapar. Kapatma RPC'si satır olmasa
  bile `provider = manual`, `status = canceled` kaydı upsert ederek kararı kalıcı
  hale getirir.
- RevenueCat pull/webhook sonucu yalnızca service-role erişimli
  `apply_verified_premium_status` RPC'siyle yazılır. Bu RPC admin grant/revoke ile
  aynı kullanıcı-bazlı advisory lock'u alır ve kilit altında `provider = manual`
  kontrolünü tekrarlar; uzun RevenueCat isteği sırasında gelen admin kararı bu
  nedenle yarışta kaybolmaz.
- Admin kapatması store aboneliğini veya billing'i iptal etmez. UI confirm metni
  bunu bildirir; gerçek mağaza iptali kullanıcı/store yönetim akışındadır.

## Grace Period
- `premiumGracePeriodProvider` yalnızca sunucunun doğruladığı
  `profiles.grace_period_until` gelecekteyse kısa süreli erişim verir.
- `premium_expires_at + sabit gün` fallback'i yasaktır: normal iptal ile ödeme
  yenileme hatasını istemci ayırt edemez.
- Provider grace bitişinde kendini timer ile invalidate eder; app resume ayrıca
  grace ve premium senkronizasyonunu yeniler.
- Guard'lar `GracePeriodStatus.gracePeriod` durumunu **passing** kabul etmelidir, sadece `isPremium == true` değil
- **Reklam kararı da dahildir (2026-07-25):** grace period'daki abone ödeyen
  müşteridir ve reklam GÖRMEZ. `effectivePremiumProvider` bugün dokuz reklam
  yüzeyinin tamamında kullanılır (ads.md § Premium Etkileşimi). Bu provider'ın
  doc-comment'i eskiden "ad visibility için `isPremiumProvider` kullan" diyordu —
  yanlıştı, düzeltildi
- Grace sürerken UI banner kalan erişim süresini ve ödeme yöntemini güncelleme
  aksiyonunu gösterir.

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
- `validate-free-tier-limit` Edge Function hızlı UX ön kontrolüdür; nihai karar
  değildir.
- Nihai limitler PostgreSQL'deki `private.free_tier_usage` sayacı ve dört tabloya
  bağlı `BEFORE INSERT OR UPDATE OR DELETE` trigger'ı ile atomik uygulanır.
- Trigger doğrudan API yazısını, inactive→active güncellemeyi ve eşzamanlı
  insert yarışını kapsar; premium/admin/founder ve aktif sunucu grace kullanıcıları
  muaftır.
- İstemci limit'i bilebilir (UX için "3/5 kuş eklediniz") ama bypass edemez
- Entity insert path'i edge function'ı çağırır; başarısız olursa `FreeTierLimitException` fırlat
- Hardcoded limit istemci kodda yok — edge function tek kaynak

```dart
// Limit gösterimi (UX), kararı değil
final usage = ref.watch(freeTierUsageProvider);
Text('${usage.current}/${usage.limit} ${'birds.birds'.tr()}')

// Edge Function hızlı UX ön kontrolü sağlar; DB trigger son sözü söyler.
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
- RevenueCat `current` offering'i doluysa tek kaynak odur. Boşsa eski/yanlış
  dashboard sırasına bağlanmadan `Offerings.all` içindeki paketleri
  paket+ürün kimliğine göre birleştir ve tekilleştir; plan filtresi yine yalnızca
  desteklenen iki ürünü UI'a çıkarır.
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
- Debug iOS simülatöründe RevenueCat init atlanmaz. Boş paket sonucu, Xcode'da
  `Runner` scheme'i doğrudan çalıştırma yönlendirmesi ve retry aksiyonu gösterir;
  seçili `Products.storekit` dosyası `flutter run`/CLI `xcodebuild` ile uygulanmaz.
- Paywall ekranı golden test edilebilir

## Anti-Patterns
1. İstemci-only premium check (`isPremium` flag'i kandırılabilir — server doğrulama zorunlu)
2. Grace period'u görmezden gelmek (ödeyen kullanıcıyı kapatır)
3. Free tier limit'i istemcide hardcode etmek (edge function source of truth)
4. `REVENUECAT_SECRET_API_KEY`'i istemci koduna sızdırmak
5. Restore Purchases butonunu kaldırmak (App Store rejection)
6. Eski plan'lara sahip kullanıcı için kod path'i hemen silmek (entitlement bitimine kadar bekle)
7. RevenueCat webhook'unu test edip edge function'ı atlatmak (race condition)
8. `provider = manual` admin kararını RevenueCat pull/webhook sonucuyla ezmek
9. `premium_expires_at` üstüne istemcide sabit grace eklemek
10. Kota güvenliğini yalnızca Edge Function count-then-insert kontrolüne bırakmak

> **İlgili**: security.md (env vars), edge-functions.md (sync-premium-status, validate-free-tier-limit), error-handling.md (FreeTierLimitException), release-ops.md (store policies)
