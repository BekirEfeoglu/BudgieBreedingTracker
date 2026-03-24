# Premium System Improvements Design

**Date:** 2026-03-23
**Status:** Approved
**Scope:** 3 improvements to premium subscription system

---

## Problem Statement

The premium system has three gaps:

1. **No sync retry:** `_syncPremiumToSupabase()` fails silently — user pays but Supabase never learns
2. **Client-only limits:** Free tier limits (15 birds, 5 pairs, 3 incubations) are only enforced in form notifiers — repository calls bypass them
3. **No grace period:** When premium expires, users with 15+ birds hit a wall with no transition period

---

## 1. Supabase Sync Retry Mechanism

### Current Behavior
`_syncPremiumToSupabase()` catches errors, logs them, and moves on. If Supabase is unreachable at purchase time, the server never knows the user is premium.

### Design

**Storage:** SharedPreferences key `pending_premium_sync_{userId}` stores a JSON payload.
Using SharedPreferences directly (not AppPreferences) — consistent with existing PremiumNotifier pattern that already uses `SharedPreferences.getInstance()`.

```json
{
  "isPremium": true,
  "retryCount": 0,
  "timestamp": "2026-03-23T10:00:00Z"
}
```

**Retry flow:**
```
purchase/restore → _syncPremiumToSupabase()
  ├─ success → done (clear any pending)
  └─ failure → _savePendingSync()
                 ↓
refresh() / _load() (app resume / periodic)
  → _retryPendingSync()
    ├─ success → clear pending
    ├─ failure + retryCount < 3 → increment retryCount, save
    └─ failure + retryCount >= 3 → Sentry.captureException(), clear pending
```

**Constants:**
- Max retries: 3 (`_maxSyncRetries`)
- No backoff delay (retry only happens on natural app events: resume, refresh)

**Affected file:** `lib/features/premium/providers/premium_notifier.dart`

### New Methods
- `_savePendingSync(String userId, bool isPremium)` — saves pending sync to SharedPreferences
- `_retryPendingSync(String userId)` — checks for pending sync and retries
- `_clearPendingSync(String userId)` — removes pending sync entry

### Integration Points
- `_syncPremiumToSupabase()` catch block → call `_savePendingSync()` on non-unavailable errors
- `_syncPremiumToSupabase()` success path → call `_clearPendingSync()` to clear any stale pending
- `refresh()` → call `_retryPendingSync()` at the end
- `_load()` → call `_retryPendingSync()` after RevenueCat check

---

## 2. Domain-Layer Premium Limit Validation

### Current Behavior
Limits checked only in `BirdFormNotifier.createBird()` and `BreedingFormNotifier.createBreeding()`. Any code calling `repository.save()` directly bypasses limits.

### Architecture Decision
**Limit checks belong in the domain layer, NOT the data layer.** Per architecture.md:
- `data/` (repositories) must NOT import from `features/`
- `domain/` CAN import from `data/`
- Form notifiers (features layer) call domain service for validation

### Design

**A) FreeTierLimitException**

New exception in `lib/core/errors/app_exception.dart`:
```dart
class FreeTierLimitException extends AppException {
  final String entityType;
  final int limit;
  FreeTierLimitException(this.entityType, this.limit);
}
```

**B) FreeTierLimitService (Domain Layer)**

New service in `lib/domain/services/premium/free_tier_limit_service.dart`:
```dart
class FreeTierLimitService {
  final BirdRepository _birdRepo;
  final BreedingPairRepository _breedingPairRepo;
  final IncubationRepository _incubationRepo;

  Future<void> guardBirdLimit(String userId) async {
    final count = (await _birdRepo.getAll(userId)).length;
    if (count >= AppConstants.freeTierMaxBirds) {
      throw FreeTierLimitException('bird', AppConstants.freeTierMaxBirds);
    }
  }

  Future<void> guardBreedingPairLimit(String userId) async {
    final pairs = await _breedingPairRepo.getAll(userId);
    final activeCount = pairs.where((p) =>
      p.status == BreedingStatus.active || p.status == BreedingStatus.ongoing
    ).length;
    if (activeCount >= AppConstants.freeTierMaxBreedingPairs) {
      throw FreeTierLimitException('breeding', AppConstants.freeTierMaxBreedingPairs);
    }
  }

  Future<void> guardIncubationLimit(String userId) async {
    final incubations = await _incubationRepo.getAll(userId);
    final activeCount = incubations.where((i) =>
      i.status == IncubationStatus.active
    ).length;
    if (activeCount >= AppConstants.freeTierMaxActiveIncubations) {
      throw FreeTierLimitException('incubation', AppConstants.freeTierMaxActiveIncubations);
    }
  }
}
```

**C) Provider + Form Notifier Integration**

Provider in `lib/domain/services/premium/free_tier_limit_providers.dart`:
```dart
final freeTierLimitServiceProvider = Provider<FreeTierLimitService>((ref) {
  return FreeTierLimitService(
    ref.watch(birdRepositoryProvider),
    ref.watch(breedingPairRepositoryProvider),
    ref.watch(incubationRepositoryProvider),
  );
});
```

Form notifiers call the service instead of inlining limit logic:
```dart
// In BirdFormNotifier.createBird():
final isPremium = ref.read(effectivePremiumProvider);
if (!isPremium) {
  await ref.read(freeTierLimitServiceProvider).guardBirdLimit(userId);
}
```

**D) Server — Edge Function (defense-in-depth)**

New Supabase Edge Function `validate-free-tier-limit`:
- Called ONLY during remote push in `RemoteSource.upsert()`, NOT during local save
- Checks `COUNT(*)` for user's non-deleted records in target table
- Returns 200 (ok) or 403 (limit exceeded)
- Limits are configurable constants in the function
- Non-blocking: if edge function fails, upsert proceeds (offline-first priority)

**Affected files:**
- `lib/core/errors/app_exception.dart` — add `FreeTierLimitException`
- `lib/domain/services/premium/free_tier_limit_service.dart` — new file
- `lib/domain/services/premium/free_tier_limit_providers.dart` — new file
- `lib/features/birds/providers/bird_form_providers.dart` — use service
- `lib/features/breeding/providers/breeding_form_providers.dart` — use service
- `supabase/functions/validate-free-tier-limit/index.ts` — new edge function

**NOT affected (no change):**
- `lib/data/repositories/bird_repository.dart` — stays as thin data access
- `lib/data/repositories/breeding_pair_repository.dart` — stays as thin data access

---

## 3. Grace Period Strategy

### Current Behavior
`isPremiumProvider` returns bool. When premium expires, user immediately loses access. No transition.

### Data Flow Fix: `premiumExpiresAt`
Currently `_syncPremiumToSupabase()` writes `current_period_end` to `user_subscriptions` but does NOT update `premium_expires_at` on the `profiles` table. This means the Profile model's `premiumExpiresAt` field is never populated.

**Fix:** Update `_syncPremiumToSupabase()` to also write `premium_expires_at` to the profiles table when syncing premium status. This ensures the grace period provider has accurate data from the profile stream.

### Design

**GracePeriodStatus enum** (in `lib/core/enums/subscription_enums.dart` — alongside existing `SubscriptionStatus`):
```dart
enum GracePeriodStatus {
  active,       // Premium is active
  gracePeriod,  // Expired within last 7 days — full access + warning banner
  expired,      // Expired > 7 days — free tier limits apply
  free,         // Never had premium
  unknown,      // Safety fallback (treated as free)
}
```

**premiumGracePeriodProvider** (new Provider<GracePeriodStatus>):
```dart
/// Determines the user's premium grace period status.
///
/// Uses profile data (premiumExpiresAt) to detect grace period.
/// Admin/founder roles always return [GracePeriodStatus.active].
///
/// Usage: Use this provider when you need to distinguish between
/// active premium, grace period, and expired states.
/// For simple "has access?" checks, use [effectivePremiumProvider] instead.
final premiumGracePeriodProvider = Provider<GracePeriodStatus>((ref) {
  // Logic:
  // 1. Admin/founder → always active
  // 2. isPremium == true → active
  // 3. premiumExpiresAt != null && within 7 days of expiry → gracePeriod
  // 4. premiumExpiresAt != null && > 7 days past expiry → expired
  // 5. else → free
});
```

**effectivePremiumProvider** (new Provider<bool>):
```dart
/// Whether the user has effective premium access (active OR grace period).
///
/// Use this provider for:
/// - Free tier limit checks in form notifiers
/// - Premium route guards
///
/// Do NOT use for:
/// - Ad visibility (use [isPremiumProvider] — grace period shows ads as gentle nudge)
/// - Subscription info display (use [premiumGracePeriodProvider] for status details)
final effectivePremiumProvider = Provider<bool>((ref) {
  final status = ref.watch(premiumGracePeriodProvider);
  return status == GracePeriodStatus.active ||
         status == GracePeriodStatus.gracePeriod;
});
```

**Constants:**
- `gracePeriodDays = 7` in `AppConstants`

**UI — Grace Period Banner:**
- New `GracePeriodBanner` widget shown on home screen when status == `gracePeriod`
- Shows days since expiry via `'premium.grace_period_message'.tr(args: [daysAgo.toString()])`
- CTA button navigates to premium screen
- Uses `AppColors.warning` styling (similar to `LimitApproachingBanner`)

**Migration path for existing code:**
- `isPremiumProvider` stays as-is (used for ad hiding — grace period still shows ads)
- All **limit checks** in form notifiers switch to `effectivePremiumProvider`
- Route guards switch to `effectivePremiumProvider`
- `GracePeriodBanner` uses `premiumGracePeriodProvider` for status details

**Affected files:**
- `lib/core/enums/subscription_enums.dart` — add `GracePeriodStatus` enum
- `lib/features/premium/providers/premium_providers.dart` — 2 new providers
- `lib/features/premium/providers/premium_notifier.dart` — write `premium_expires_at` in sync
- `lib/core/constants/app_constants.dart` — `gracePeriodDays = 7`
- `lib/features/home/widgets/grace_period_banner.dart` — new widget
- `lib/features/home/screens/home_screen.dart` — add GracePeriodBanner
- `lib/features/birds/providers/bird_form_providers.dart` — use effectivePremiumProvider
- `lib/features/breeding/providers/breeding_form_providers.dart` — use effectivePremiumProvider
- `lib/router/app_router.dart` — use effectivePremiumProvider for premium guards
- `assets/translations/tr.json`, `en.json`, `de.json` — grace period keys

---

## Localization Keys

### Turkish (tr.json)
```json
{
  "premium": {
    "grace_period_title": "Premium Süreniz Doldu",
    "grace_period_message": "Premium aboneliğiniz {} gün önce sona erdi. Yenileyin!",
    "grace_period_renew": "Şimdi Yenile",
    "sync_failed_warning": "Premium durumunuz sunucuya senkronize edilemedi",
    "free_tier_limit_bird": "Ücretsiz planda en fazla {} kuş ekleyebilirsiniz",
    "free_tier_limit_breeding": "Ücretsiz planda en fazla {} aktif çift oluşturabilirsiniz",
    "free_tier_limit_incubation": "Ücretsiz planda en fazla {} aktif kuluçka başlatabilirsiniz"
  }
}
```

### English (en.json)
```json
{
  "premium": {
    "grace_period_title": "Your Premium Has Expired",
    "grace_period_message": "Your premium subscription expired {} days ago. Renew now!",
    "grace_period_renew": "Renew Now",
    "sync_failed_warning": "Your premium status could not be synced to the server",
    "free_tier_limit_bird": "Free plan allows up to {} birds",
    "free_tier_limit_breeding": "Free plan allows up to {} active breeding pairs",
    "free_tier_limit_incubation": "Free plan allows up to {} active incubations"
  }
}
```

### German (de.json)
```json
{
  "premium": {
    "grace_period_title": "Ihr Premium ist abgelaufen",
    "grace_period_message": "Ihr Premium-Abonnement ist vor {} Tagen abgelaufen. Jetzt erneuern!",
    "grace_period_renew": "Jetzt erneuern",
    "sync_failed_warning": "Ihr Premium-Status konnte nicht mit dem Server synchronisiert werden",
    "free_tier_limit_bird": "Im kostenlosen Plan können Sie bis zu {} Vögel hinzufügen",
    "free_tier_limit_breeding": "Im kostenlosen Plan können Sie bis zu {} aktive Zuchtpaare erstellen",
    "free_tier_limit_incubation": "Im kostenlosen Plan können Sie bis zu {} aktive Bruten starten"
  }
}
```

---

## Testing Plan

### Unit Tests
- `_retryPendingSync()` — pending var/yok, retry count artışı, max retry sonrası Sentry
- `FreeTierLimitService.guardBirdLimit()` — limit altında/üstünde, premium kullanıcı bypass
- `FreeTierLimitService.guardBreedingPairLimit()` — aktif çift sayısı kontrolü
- `FreeTierLimitService.guardIncubationLimit()` — aktif kuluçka sayısı kontrolü
- `premiumGracePeriodProvider` — active/gracePeriod/expired/free/admin durumları
- `effectivePremiumProvider` — active+gracePeriod=true, expired+free=false

### Widget Tests
- `GracePeriodBanner` — gösterilme/gizlenme durumları, gün hesabı, CTA navigasyonu

---

## Out of Scope

- Deleting or hiding existing user data when premium expires
- Supabase RLS policy changes (must be done via Supabase Dashboard)
- RevenueCat webhook integration
- Server-side grace period enforcement (client-only for now)
- Repository-layer limit checks (limits stay in domain/features layer per architecture rules)

---

## File Change Summary

| File | Change Type |
|------|-------------|
| `premium_notifier.dart` | Edit — retry logic + premiumExpiresAt sync |
| `premium_providers.dart` | Edit — 2 new providers (premiumGracePeriodProvider, effectivePremiumProvider) |
| `subscription_enums.dart` | Edit — add GracePeriodStatus enum |
| `app_constants.dart` | Edit — gracePeriodDays = 7 |
| `app_exception.dart` | Edit — FreeTierLimitException |
| `free_tier_limit_service.dart` | New — domain service |
| `free_tier_limit_providers.dart` | New — service provider |
| `grace_period_banner.dart` | New — banner widget |
| `home_screen.dart` | Edit — add GracePeriodBanner |
| `bird_form_providers.dart` | Edit — use service + effectivePremiumProvider |
| `breeding_form_providers.dart` | Edit — use service + effectivePremiumProvider |
| `app_router.dart` | Edit — use effectivePremiumProvider |
| `tr.json` / `en.json` / `de.json` | Edit — new keys |
| `validate-free-tier-limit/index.ts` | New — edge function |
