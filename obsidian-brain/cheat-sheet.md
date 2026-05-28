# Cheat Sheet

Task-oriented navigation. Find your task on the left, jump to the page on
the right. Use this when you don't know which section of the wiki to
start from.

## "How do I…"

| Question | Start Here |
|----------|-----------|
| Add a brand-new entity (model → DB → repo → UI)? | [[features/_features-index]] → entity lifecycle, then [[data-layer/repositories]] |
| Add a localization key? | [[patterns/l10n]] — Turkish first, then en/de, then `check_l10n_sync.py` |
| Add a new route? | [[architecture/folder-structure]] + [[patterns/ui-patterns]] (specific before `:id`) |
| Add a custom SVG icon? | [[patterns/assets-images]] — `AppIcons` constants, `AppIcon` widget |
| Change a Drift table or column? | [[data-layer/migrations]] — bump `schemaVersion`, write `onUpgrade`, mirror in Supabase SQL |
| Write a new sync repository? | [[data-layer/repositories]] + [[data-layer/sync-strategy]] — `BaseRepository`, `ValidatedSyncMixin` if FK parent |
| Decide if a class should be `*Repository`? | [[architecture/online-first-exemption]] — offline-first OR rename to `*RemoteSource` |
| Schedule a notification? | [[domain/notification-service]] + [[patterns/datetime-format]] — `tz.TZDateTime` mandatory |
| Compute incubation day? | [[domain/incubation-service]] + [[patterns/datetime-format]] — `DateUtils.dayDiff` |
| Gate a feature behind premium? | [[domain/premium-service]] — `effectivePremiumProvider`, `PremiumGuard` |
| Add a Riverpod provider? | [[patterns/providers]] — pick the right type, `ref.watch` vs `read` rules |
| Handle an error in UI? | [[patterns/error-handling]] + [[patterns/empty-loading-error-states]] |
| Upload a photo? | [[patterns/assets-images]] — 10 MB guard, `scan-image-safety`, compress |
| Write a widget test? | [[patterns/testing]] — pump helpers, `addTearDown(container.dispose)` |
| Style with theme? | [[patterns/ui-patterns]] — `Theme.of(context)`, `AppSpacing`, `withValues(alpha:)` |
| Avoid an anti-pattern? | [[patterns/anti-patterns]] — 24 rules + audit-flagged extras |
| Deploy an Edge Function? | [[infrastructure/edge-functions]] + [[infrastructure/ci-cd]] |
| Configure a kill switch? | [[patterns/feature-flags]] — runtime / compile / entitlement / server kill switch |
| Verify code quality before commit? | [[infrastructure/scripts]] — quality gates |

## "Where does X live?"

| Concept | Location |
|---------|----------|
| Tables (Drift) | `lib/data/local/database/tables/` — [[data-layer/tables-catalog]] |
| DAOs | `lib/data/local/database/daos/` — [[data-layer/drift]] |
| Mappers | `lib/data/local/database/mappers/` |
| Repositories | `lib/data/repositories/` — [[data-layer/repositories]] |
| Remote sources | `lib/data/remote/api/` — [[data-layer/supabase]] |
| Domain services | `lib/domain/services/` — [[domain/services-index]] |
| Routes | `lib/router/routes/` |
| Route guards | `lib/router/guards/` |
| Shared widgets | `lib/core/widgets/` — [[patterns/ui-patterns]] |
| SVG icon constants | `lib/core/constants/app_icons.dart` — [[patterns/assets-images]] |
| Theme + spacing | `lib/core/theme/` |
| L10n keys | `assets/translations/{tr,en,de}.json` — [[patterns/l10n]] |
| Edge Functions | `supabase/functions/` — [[infrastructure/edge-functions]] |
| Migrations | `supabase/migrations/` — [[data-layer/migrations]] |
| Rules (source of truth for policy) | `.claude/rules/` — [[sources/rules-index]] |
| Quality scripts | `scripts/` — [[infrastructure/scripts]] |

## "When does X fire?"

| Trigger | What runs |
|---------|-----------|
| App cold start | Splash → session refresh → deep link → home / auth ([[features/splash]]) |
| App resume (foreground) | Sync pull, profile refresh, presence heartbeat ([[domain/sync-service]] + [[domain/presence-service]]) |
| Connectivity online | Sync push pending dirty records ([[data-layer/sync-strategy]]) |
| Egg → hatched | Auto-create chick + reminder reschedule + incubation closure check ([[domain/eggs-service]]) |
| All eggs in incubation terminal | Auto-close incubation + maybe pair ([[domain/eggs-service]]) |
| Bird / breeding / chick added | XP awarded + badge progress + verified-breeder check ([[domain/gamification-service]]) |
| Photo uploaded | 10 MB guard → compress → `scan-image-safety` → bucket upload ([[patterns/assets-images]]) |
| Message received | FCM push + deeplink + read receipt ([[features/messaging]]) |
| Sync conflict detected | `conflictNotifierProvider` notify + UI banner ([[data-layer/sync-strategy]]) |
| Migration runs | Drift `onUpgrade` (local) or Supabase SQL (remote) ([[data-layer/migrations]]) |
| `min_supported_build` bump | All users below version see non-dismissible blocking dialog ([[features/app_update]]) |

## "Which Edge Function does this?"

| Need | Function |
|------|----------|
| Premium status validation | `sync-premium-status` |
| Free-tier limit enforcement | `validate-free-tier-limit` |
| Push notification delivery | `send-push` |
| Photo NSFW / CSAM scan | `scan-image-safety` |
| Community text moderation | `moderate-content` |
| MFA brute-force lockout | `mfa-lockout` |
| OAuth token revocation on logout | `revoke-oauth-token` |
| Admin system health | `system-health` |

All require JWT verification — see [[infrastructure/edge-functions]].

## See Also

- [[README]] — quick navigation by section
- [[index]] — full page catalog
- [[overview]] — high-level synthesis
- [[sources/rules-index]] — rules → wiki mapping
