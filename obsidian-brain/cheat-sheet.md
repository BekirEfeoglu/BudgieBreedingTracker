# Cheat Sheet

Task-oriented navigation. Find your task on the left, jump to the page on
the right. Use this when you don't know which section of the wiki to
start from.

## "How do I…"

| Question | Start Here |
|----------|-----------|
| Add a brand-new entity (model → DB → repo → UI)? | [[features/_features-index]] → entity lifecycle, then [[data-layer/repositories]] |
| Add a localization key? | [[patterns/l10n]] — Turkish first, then en/de, then `check_l10n_sync.py` |
| Add a new route or guard? | [[architecture/router-navigation]] — redirect chain, specific before `:id`, `editId` validation |
| Add a custom SVG icon? | [[patterns/assets-images]] — `AppIcons` constants, `AppIcon` widget |
| Change a Drift table or column? | [[data-layer/migrations]] — bump `schemaVersion`, write `onUpgrade`, mirror in Supabase SQL |
| Write a new sync repository? | [[data-layer/repositories]] + [[data-layer/sync-strategy]] — `BaseRepository`, `ValidatedSyncMixin` if FK parent |
| Decide if a class should be `*Repository`? | [[architecture/online-first-exemption]] — offline-first OR rename to `*RemoteSource` |
| Schedule a notification? | [[domain/notification-service]] + [[patterns/datetime-format]] — `tz.TZDateTime` mandatory |
| Compute incubation day? | [[domain/incubation-service]] + [[patterns/datetime-format]] — `DateUtils.dayDiff` |
| Gate a feature behind premium? | [[domain/premium-service]] — `effectivePremiumProvider`, `PremiumGuard` |
| Add a Riverpod provider? | [[patterns/providers]] — pick the right type, `ref.watch` vs `read` rules |
| Handle an error in UI? | [[patterns/error-handling]] + [[patterns/empty-loading-error-states]] |
| Upload a photo? | [[patterns/assets-images]] — picker sizing, guard/magic bytes, 2 MB effective scan cap, `scan-image-safety` |
| Validate a bird ring number? | [[features/birds]] + [[patterns/forms-validation]] — debounced early check plus submit-time fallback |
| Write a widget test? | [[patterns/testing]] — pump helpers, `addTearDown(container.dispose)` |
| Style with theme? | [[patterns/ui-patterns]] — `Theme.of(context)`, `AppSpacing`, `withValues(alpha:)` |
| Avoid an anti-pattern? | [[patterns/anti-patterns]] — 24 rules + audit-flagged extras |
| Deploy an Edge Function? | [[infrastructure/edge-functions]] + [[infrastructure/ci-cd]] |
| Configure a kill switch? | [[patterns/feature-flags]] — runtime / compile / entitlement (server kill switch is UNSHIPPED, see [[known-gaps]]) |
| Encrypt a sensitive field? | [[domain/encryption-service]] — what-to-encrypt table, AES + HMAC, key rotation |
| Add an XP-earning action? | [[domain/gamification-service]] — XP constants, server-side RLS enforcement, daily limits |
| Moderate user content? | [[domain/moderation-service]] — two-layer fail-closed pipeline, context thresholds |
| Add or check a Supabase migration? | [[data-layer/migrations]] — idempotent SQL, RLS, `private` RPC pattern; deploy is manual (`supabase db push`) |
| Check if a feature is actually shipped? | [[known-gaps]] — latent surfaces, unshipped design goals, deliberate absences |
| Change genetics rates, loci, viability, or naming? | [[domain/genetics-engine]] + `.claude/rules/genetics.md` — evidence + version decision + regression |
| Pick a project-local review/implementation agent? | [[sources/agents-index]] — trigger and read/write mode |
| Resolve a code/rule/wiki/source conflict? | [[CLAUDE.md]] — classify authority by claim type before editing |
| Verify code quality before commit? | [[infrastructure/scripts]] — quality gates |
| Triage a `test` job red under shuffled order? | [[infrastructure/ci-cd]] + [[patterns/testing]] — order-dependency, NOT flakiness; reproduce with the logged seed, split shared state (classic: real-l10n test in a raw-key file) |
| Fix a near-`DateTime.now()` flaky boundary test? | [[patterns/testing]] — inject a clock seam (`syncClockProvider` pattern), never widen the margin to seconds |
| Add a scheduled / streak notification? | [[domain/notification-service]] + [[domain/gamification-service]] — deterministic `NotificationIds`, `tz.TZDateTime`, cancel-then-schedule |

## "Where does X live?"

| Concept | Location |
|---------|----------|
| Tables (Drift) | `lib/data/local/database/tables/` — [[data-layer/tables-catalog]] |
| DAOs | `lib/data/local/database/daos/` — [[data-layer/drift]] |
| Mappers | `lib/data/local/database/mappers/` |
| Repositories | `lib/data/repositories/` — [[data-layer/repositories]] |
| Remote sources | `lib/data/remote/api/` — [[data-layer/supabase]] |
| Domain services | `lib/domain/services/` — [[domain/services-index]] |
| Routes | `lib/router/routes/` — [[architecture/router-navigation]] |
| Route guards | `lib/router/guards/` — [[architecture/router-navigation]] |
| Shared widgets | `lib/core/widgets/` — [[patterns/ui-patterns]] |
| SVG icon constants | `lib/core/constants/app_icons.dart` — [[patterns/assets-images]] |
| Theme + spacing | `lib/core/theme/` |
| L10n keys | `assets/translations/{tr,en,de}.json` — [[patterns/l10n]] |
| Edge Functions | `supabase/functions/` — [[infrastructure/edge-functions]] |
| Migrations | `supabase/migrations/` — [[data-layer/migrations]] |
| Rules (source of truth for policy) | `.claude/rules/` — [[sources/rules-index]] |
| Agent profiles | `.claude/agents/` — [[sources/agents-index]] |
| Project-local skills | `.claude/skills/` — [[sources/skills-index]] |
| Quality scripts | `scripts/` — [[infrastructure/scripts]] |

## "When does X fire?"

| Trigger | What runs |
|---------|-----------|
| App cold start | Splash → session refresh → deep link → home / auth ([[features/splash]]) |
| App resume (foreground) | Lightweight sync push, profile/premium refresh, presence active, realtime resubscribe ([[domain/sync-service]] + [[domain/presence-service]]) |
| Connectivity online | `forceFullSync()` after auto-sync/Wi-Fi guards ([[data-layer/sync-strategy]]) |
| Egg → hatched | Auto-create chick + reminder reschedule + incubation closure check ([[domain/eggs-service]]) |
| All eggs in incubation terminal | Auto-close incubation + maybe pair ([[domain/eggs-service]]) |
| Bird / breeding / chick added | XP awarded + badge progress + verified-breeder check ([[domain/gamification-service]]) |
| Photo selected/uploaded | picker resize/quality → size guard → magic bytes → `scan-image-safety` → bucket ([[patterns/assets-images]]) |
| Message received | FCM push + deeplink + read receipt if enabled — reciprocal opt-out ([[features/messaging]]) |
| App cold start reaches `InitStep.ready` | Deferred: daily streak check-in (`record_daily_checkin` RPC, local-day), FCM registration, full sync ([[domain/gamification-service]]) |
| Sync conflict detected | persist `conflict_history` → `conflictHistoryProvider` + recent-count banner/chip/detail sheet ([[data-layer/sync-strategy]]) |
| Migration runs | Drift `onUpgrade` (local) or Supabase SQL (remote) ([[data-layer/migrations]]) |
| `min_supported_build` bump | All users below version see non-dismissible blocking dialog ([[features/app_update]]) |

## "Which Edge Function does this?" (12 total)

| Need | Function |
|------|----------|
| Premium status validation (client pull) | `sync-premium-status` |
| RevenueCat subscription events (webhook push) | `revenuecat-webhook` |
| Free-tier limit enforcement | `validate-free-tier-limit` |
| Push notification delivery | `send-push` |
| Photo NSFW / CSAM scan | `scan-image-safety` |
| Community text moderation | `moderate-content` |
| Community post create/edit (server-side moderation) | `create-community-post` |
| Community comment create (moderation + block check) | `create-community-comment` |
| Community photo upload (moderation + storage) | `upload-community-photo` |
| MFA brute-force lockout | `mfa-lockout` |
| OAuth token revocation on logout | `revoke-oauth-token` |
| Admin system health | `system-health` |

All client-called functions require JWT verification; `revenuecat-webhook` is the
sole shared-secret exception (`verify_jwt=false`) — see [[infrastructure/edge-functions]].

## See Also

- [[README]] — quick navigation by section
- [[index]] — full page catalog
- [[overview]] — high-level synthesis
- [[known-gaps]] — what looks shipped but isn't
- [[sources/rules-index]] — rules → wiki mapping
