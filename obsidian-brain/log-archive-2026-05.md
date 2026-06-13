# Change Log Archive - 2026-05

Back to [[log]].

## [2026-05-26] migrate | OAuth Phase 1+2

- GCP Firebase project: OAuth consent screen configured "In production", External.
- New Web Client ID `720334450619-kvo5m738euj98t4qmmqeabmmd48ma0tl.apps.googleusercontent.com`.
- New iOS Client ID `720334450619-oacalc9gn0sg986d16it34jr4th6bkf4.apps.googleusercontent.com`.
- Supabase Auth Google provider accepts both legacy + new Web Client IDs during rollout.
- `ios/Runner/Info.plist` and `.env.example` updated with new Client ID values.
- `patterns/security.md` rewritten from "dual-project" to "mid-migration".

## [2026-05-26] update | Add revenuecat-webhook + dual-project OAuth docs

- `infrastructure/edge-functions.md`: inventory 8->9, added `revenuecat-webhook`.
- Added webhook receiver exception docs and deploy checklist steps 7-12.
- `patterns/security.md`: documented dual-project Google OAuth topology.
- Source commits: c63fe82, c764e6f, 0de440d.

## [2026-05-25] sync | Stat drift sweep + checker count refresh

- L10n key count 2,968->2,978.
- Test counts 901/11,017->906/11,056.
- `verify_code_quality.py` checker count 24->27.
- `overview.md` stats snapshot date 2026-05-21->2026-05-25.
- Disk vs `index.md` catalog cross-checked: 81 .md files.

## [2026-05-21] enhance | Domain coverage expansion + skeletal feature buildup + cheat sheet

- New domain service pages: incubation, eggs, data-io, encryption, moderation,
  gamification, home-widget, presence.
- Expanded skeletal feature pages with real codebase references.
- Added `cheat-sheet.md`; updated `index.md`, `README.md`,
  `domain/services-index.md`, and `sources/rules-index.md`.

## [2026-05-21] rule | DateUtils import convention

- `.claude/rules/datetime-format.md`: added mandatory `as date_utils` import prefix.
- `obsidian-brain/patterns/datetime-format.md`: mirrored the guidance.

## [2026-05-21] sync | Stat drift sweep + pattern gap fixes

- Refreshed stats to match `verify_rules.py` baseline: schemaVersion 22->24,
  l10n 2,840->2,968, source 959->989, tests 886/10,884->901/11,016,
  migrations 156->158, domain services 21->23.
- Added certificate pinning docs, sync rollout/kill-switch docs, and provider
  anti-pattern cross-reference correction.

## [2026-05-17] ingest | Incubation risk assistant, sync retry policy, services index

- `features/breeding.md`: documented `IncubationRiskCard` and `IncubationRiskAssistant`.
- `domain/services-index.md`: corrected count 21->23.
- Sync retry policy updated to `RetryScheduler`.

## [2026-05-15] docs | Marketing site anchor and accessibility QA

Added `infrastructure/marketing-site.md` and linked site-specific guidance from
CI/CD and accessibility pages.

## [2026-05-15] ingest | Birds timeline, grid view, ring sort, gifted status

Updated `features/birds.md` for bird detail life timeline, bird list photo grid
mode, natural ring-number sorting, and `gifted` status.

## [2026-05-15] ingest | Breeding deleteBreeding now detaches chicks before cascade

Fixed orphan chick FK sync block by clearing soon-to-be-deleted egg/clutch refs
before deleting breeding parents.

## [2026-05-14] ingest | Initial wiki bootstrap

All pages created from scratch by reading `CLAUDE.md`, `.claude/rules/`, and
`pubspec.yaml`.

## [2026-05-15] feature | Breeding/eggs/chicks dashboard UX

Added breeding season summary, today's egg-turning card, calendar incubation
filter, weaning-to-bird prompt, and chick detail weight history.

## [2026-05-15] feature | Genetics/breeding risk and sharing

Added breeding form inbreeding warning/confirmation and genetics compare share.

## [2026-05-15] feature | Genealogy node photos

Documented and implemented photo thumbnails inside interactive pedigree nodes.

## [2026-05-15] feature | Statistics records, trends, and PDF share

Added personal records, season comparison, health trend summaries, and statistics
PDF share action.

## [2026-05-15] feature | Cage ledger MVP and offline guide update

Added bird-list cage ledger from existing `cageNumber`, same-cage breeding
selector hints, and local user-guide topic for cage tracking.

## [2026-05-29] fix | app_update: Android DB force-update + config cleanup

`appUpdateStatusProvider` now reads Android `system_settings.app_version`.
Bumped stale config to 1.1.1+32; dropped orphaned `app_versions` table.
