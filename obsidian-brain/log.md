# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

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
