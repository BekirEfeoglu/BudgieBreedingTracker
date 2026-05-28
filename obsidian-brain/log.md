# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-05-29] sync | Leaderboard display-name privacy + stat drift sweep

Documented the leaderboard display-name + privacy opt-out feature (commits
`29b8d62`, `8894f7b`) and swept accumulated stat drift to the `CLAUDE.md` /
`verify_rules.py` baseline.

- `features/gamification.md` + `domain/gamification-service.md` +
  `data-layer/supabase.md`: `profiles.show_in_leaderboard` opt-out and the
  `get_leaderboard` `SECURITY DEFINER` RPC (excludes opt-out,
  `COALESCE(display_name, full_name)`, `authenticated`-only; client reads via
  `GamificationRemoteSource.fetchLeaderboard`).
- `data-layer/migrations.md`: schema v25 (`_migrateV24ToV25`).
- Stat sweep across `overview.md`, `index.md`, `architecture/folder-structure.md`,
  `data-layer/{supabase,migrations}.md`, `patterns/{l10n,testing}.md`: schema
  24→25, l10n 2,978/42→2,987/41, tests 906/11,056→901/11,048, migrations
  158→160, Edge fns 8→9, source 989→983, modules 25→24, domain 23→22, SVG
  84→89, shared widgets 28→29, Supabase constants 146→137, remote sources 27→26.
- `data-layer/tables-catalog.md`: index test asserts schema `>= 23` (floor).
- Code context: test fix `0755905` (date-flaky statistics test) shipped to main, CI green.

---

## [2026-05-28] iOS update prompt fix | iOS update dialog crashed (showDialog with no Navigator in the builder context); a rootNavigatorKey fix stopped the crash but GoRouter page rebuilds still dismissed the imperative dialog. Switched to an in-tree banner (optional) / full-screen layer (required) drawn in a Stack over the child, so it survives rebuilds. Polished with a tinted icon square + slide-up entrance. Verified live on the iOS simulator.

---

## [2026-05-28] android in-app updates | Added Google Play native in-app updates (in_app_update pkg; InAppUpdateService + AndroidInAppUpdater): flexible by default, immediate when updatePriority>=4. Custom dialog scoped to iOS (appUpdateStatusProvider returns null on Android + Theme.platform gate) to avoid a double prompt. Added app_update.download_complete/restart l10n. Both platforms now auto-detect store versions.

---

## [2026-05-28] consolidate update systems | Removed System B (update feature: UpdateListener, ForcedUpdateScreen, UpdateOptionalSheet, updateStatusProvider, update_check_service, AppVersionRemoteSource, AppVersion model, UpdateStatus enum, app_versions constants, update.* l10n). app_update is now the single update path. Feature modules 25 → 24; l10n 42 → 41 categories.

---

## [2026-05-27] sync | Map 13 new rule files to existing wiki pages

13 new rule files added to `.claude/rules/` covering previously rule-gapped domains
(features and services that had wiki pages but no rule source): `genetics.md`,
`encryption.md`, `moderation.md`, `community.md`, `messaging.md`, `presence.md`,
`admin.md`, `marketplace.md`, `gamification.md`, `statistics.md`, `calendar.md`,
`data-io.md`, `home-widget.md`. Total rules: 33 → 46.

- `sources/rules-index.md`: added all 13 mappings to primary + secondary wiki pages
- `domain/genetics-engine.md`: source ref updated from `local-ai.md` → `genetics.md` (primary) + linkage/lethal/reverse-calculator reference
- `domain/encryption-service.md`: source ref upgraded with `encryption.md` (primary)
- `domain/moderation-service.md`: source ref upgraded with `moderation.md` (primary)
- `domain/data-io.md`: added source ref (PBKDF2 backup key, Excel i18n headers)
- `domain/presence-service.md`: added source ref (TTL, heartbeat, privacy visibility)
- `domain/home-widget-service.md`: added source ref (shared storage schema, WidgetKit timeline budget)
- `domain/gamification-service.md`: added source ref (anti-gambling, streak, manual verified breeder)
- `features/community.md`, `features/messaging.md`, `features/admin.md`, `features/marketplace.md`, `features/statistics.md`, `features/calendar.md`: rule references added/extended
- `CLAUDE.md` (project root): Rules table extended with 14 entries (13 new + `breeding-eggs.md` that was missing from the table)
- `verify_rules.py`: 24/24 PASS, no stat drift

No new wiki pages created (all rule subjects already had pages). No broken
wikilinks. All pages under 200 lines.

## [2026-05-26] migrate | OAuth Phase 1+2 — new Client IDs in Firebase project, Supabase multi-audience, app code updated

- GCP Firebase project: OAuth consent screen configured "In production", External (no verification needed — basic scopes only). New Web Client ID `720334450619-kvo5m738euj98t4qmmqeabmmd48ma0tl.apps.googleusercontent.com` + new iOS Client ID `720334450619-oacalc9gn0sg986d16it34jr4th6bkf4.apps.googleusercontent.com`.
- Supabase Auth Google provider Client IDs field set to comma-separated list with BOTH legacy + new Web Client IDs — old AND new binaries' ID tokens accepted in parallel, no breaking change.
- `ios/Runner/Info.plist` CFBundleURLSchemes replaced with new reversed iOS Client ID. `.env.example` updated with new Client ID values in comments.
- `patterns/security.md` rewritten from "dual-project" to "mid-migration" with future-state cleanup checklist.

## [2026-05-26] update | Add revenuecat-webhook + dual-project OAuth docs

- `infrastructure/edge-functions.md`: inventory 8 → 9, added `revenuecat-webhook` (Bearer token auth via `REVENUECAT_WEBHOOK_AUTH_TOKEN`), new "Webhook Receiver Exception" section, policies row, and step 7-12 for webhook receivers in the New Function Checklist.
- `patterns/security.md`: new "Dual-Project Google OAuth" section after OAuth Token Management — documents that the Google Sign-In OAuth client lives in GCP project `118599620356`, separate from Firebase project `720334450619`. Clarifies the Firebase SHA-1 duplicate-registration warning is informational, not a deletion target. Includes future consolidation runbook.
- Source commits: c63fe82 (webhook function + verify_security allowlist + CI deploy), c764e6f (security.md OAuth section), 0de440d (Android manifest hardening + .env + key.properties template).

## [2026-05-25] sync | Stat drift sweep + checker count refresh

- `overview.md`, `architecture/folder-structure.md`, `patterns/l10n.md`: l10n key count 2,968→2,978 (commit 1d2fff3 added chicks bulk feedback keys).
- `overview.md`, `patterns/testing.md`: test counts 901/11,017 → 906/11,056 (commits efc2ee1 + 1fd6bde added coverage for previously untested critical units + K3/K5 audit alignment).
- `overview.md`, `patterns/anti-patterns.md`, `infrastructure/ci-cd.md`, `infrastructure/scripts.md`: `verify_code_quality.py` checker count 24→27 — covers 19/24 CLAUDE.md anti-patterns + 8 audit-flagged extras (`Freezed3`, `Layer`, `Loading`, `TapTarget`, `Container`, `Upsert`, `Boundary`, `ImageCache`).
- `overview.md`: stats snapshot date 2026-05-21 → 2026-05-25.
- Disk vs `index.md` catalog cross-checked: 81 .md files match catalog. No new pages, no broken wikilinks, all pages under 200 lines (max is `index.md` at 126).

## [2026-05-21] enhance | Domain coverage expansion + skeletal feature buildup + cheat sheet

- New domain service pages (closes long-standing index-only entries):
  - `domain/incubation-service.md` — day math, milestones, environment monitor, species config
  - `domain/eggs-service.md` — `EggActionsNotifier` orchestration (RLS preflight, chick auto-create, parent closure, side-effect warnings)
  - `domain/data-io.md` — backup (JSON, AES), Excel import/export, PDF export (consolidates backup/import/export dirs)
  - `domain/encryption-service.md` — AES-256-CBC + HMAC, key rotation, payload codec
  - `domain/moderation-service.md` — text + image safety, fail-closed contract, Edge Function pipeline
  - `domain/gamification-service.md` — XP, level curve, daily caps, verified breeder, audit K12 race note
  - `domain/home-widget-service.md` — iOS / Android dashboard widget snapshot bridge
  - `domain/presence-service.md` — online status sessions, heartbeat TTL, UTC boundary
- Expanded skeletal feature pages with real codebase references:
  - `features/feedback.md`, `features/update.md`, `features/app_update.md`, `features/more.md`,
    `features/home.md`, `features/settings.md`, `features/profile.md`, `features/admin.md`,
    `features/calendar.md`, `features/notifications.md`, `features/eggs.md`,
    `features/marketplace.md`, `features/messaging.md`
- Added `cheat-sheet.md` — task-oriented "how do I / where is / when does / which Edge Function" lookup (no rule alignment needed, pure synthesis layer addition)
- `index.md`: added cheat-sheet at root level + 8 new domain pages (alphabetized)
- `README.md`: linked cheat-sheet from quick navigation
- `domain/services-index.md`: rebuilt table — each documented service now points to its page; remaining undocumented services point to their primary feature/service host
- `sources/rules-index.md`: extended `breeding-eggs.md` secondaries with the two new domain pages; added `domain/moderation-service` and `domain/encryption-service` to relevant rules

## [2026-05-21] rule | DateUtils import convention (prevent auto-audit regression)

- `.claude/rules/datetime-format.md`: added `DateUtils.dayDiff` helper section with mandatory `as date_utils` import prefix (Flutter material exports its own `DateUtils`; unprefixed import → `ambiguous_import` analyze fail). Surfaced PR #80 root cause.
- `obsidian-brain/patterns/datetime-format.md`: mirrored the same guidance + extended anti-pattern list (adds prefixed-import rule).

## [2026-05-21] sync | Stat drift sweep + pattern gap fixes

- `overview.md`, `index.md`, `architecture/folder-structure.md`, `data-layer/drift.md`, `data-layer/migrations.md`, `data-layer/supabase.md`, `patterns/l10n.md`, `patterns/testing.md`: refreshed stats to match `verify_rules.py` baseline (schemaVersion 22→24, l10n 2,840→2,968, source 959→989, tests 886/10,884→901/11,016, migrations 156→158, domain services 21→23).
- `patterns/security.md`: added active certificate pinning section (SHA-256 allowlist, rotation, emergency proxy flag).
- `patterns/feature-flags.md`: documented sync rollout/kill-switch flags (`syncOfflineBannerEnabledProvider`, `syncBackgroundEnabledProvider`, `syncRealtimeEnabledProvider`, server kill switch, rollout percent) with ramp plan.
- `patterns/providers.md`: corrected anti-pattern cross-reference (#3,#4 → #4).
- Verified all 74 wiki files, no broken `[[wikilinks]]`, all pages under 200 lines.

## [2026-05-17] ingest | Incubation risk assistant, sync retry policy, services index

- `features/breeding.md`: documented `IncubationRiskCard` + `IncubationRiskAssistant` (5 risk types, severity ranking, derived from pair/incubation/egg/chick streams).
- `domain/services-index.md`: corrected count 21→23, refreshed list to match actual `lib/domain/services/` directories.
- `data-layer/sync-strategy.md` + `domain/sync-service.md`: updated retry policy to `RetryScheduler` (45s base, max 7, 10min cap, 20% jitter) — was stale 5-attempt/2s spec.

## [2026-05-15] docs | Marketing site anchor and accessibility QA

Added `infrastructure/marketing-site.md` for the GitHub Pages product site,
including direct `#genetics-demo` hash behavior, reveal/GSAP cleanup,
language/mobile-menu/FAQ semantic state, SEO/store-link consistency, and
web QA checklist. Updated CI/CD and accessibility pages to cross-link the
new site-specific guidance.

## [2026-05-15] ingest | Birds timeline, grid view, ring sort, gifted status

Updated `features/birds.md` for bird detail life timeline, bird list photo grid mode,
natural ring-number sorting, and `gifted` as a non-sale transfer status.

## [2026-05-15] ingest | Breeding deleteBreeding now detaches chicks before cascade

Fixed orphan chick FK sync block: `deleteBreeding` clears `eggId`/`clutchId` on chicks
referencing soon-to-be-deleted eggs so chicks survive as standalone records.
Updated `features/breeding.md` with new cascade order.

## [2026-05-14] ingest | Initial wiki bootstrap — recreated after worktree deletion

All pages created from scratch by reading:
- `CLAUDE.md` (project root)
- All 32 files in `.claude/rules/`
- `pubspec.yaml`

Pages created: README, CLAUDE, index, log, overview, architecture/* (6), features/* (26),
data-layer/* (6), domain/* (8), infrastructure/* (6), patterns/* (15), sources/rules-index.
## [2026-05-15] feature | Breeding/eggs/chicks dashboard UX

Added breeding season summary, today's egg-turning card, calendar incubation filter,
weaning-to-bird prompt, and chick detail weight history.

## [2026-05-15] feature | Genetics/breeding risk and sharing

Added breeding form inbreeding warning/confirmation from pedigree data and a
genetics compare share action for selected history calculations.

## [2026-05-15] feature | Genealogy node photos

Documented and implemented photo thumbnails inside interactive pedigree nodes.

## [2026-05-15] feature | Statistics records, trends, and PDF share

Added personal records, season comparison, health trend summaries, and a
statistics PDF share action backed by reusable highlight providers.

## [2026-05-15] feature | Cage ledger MVP and offline guide update

Added bird-list cage ledger from existing `cageNumber`, same-cage breeding
selector hints, and a local user-guide topic for cage tracking.
