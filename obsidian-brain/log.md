# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-06-13] automation | platform/wiki lint

- Removed unsupported Flutter web target files; GitHub Pages remains served from
  `docs/`.
- Added `check_platform_targets.py` and `check_obsidian_brain.py` to local and
  CI quality gates.

---

## [2026-06-13] sync | Rule metadata + wiki stat drift

Synced wiki summaries with current `CLAUDE.md` and `.claude/rules/` after the
rule metadata alignment commit.

- UUID guidance updated from `Uuid().v4()` to `const Uuid().v7()` for new entity
  creation paths in overview and sync/data-layer pages.
- Stat drift updated: source 983->987, tests 901/11,048->903/11,095, l10n
  2,992->2,995, migrations 160->174, Edge Functions 9->12, Supabase constants
  137->138, code-quality checker wording 28->27 checker categories.
- Edge Function inventory now includes `create-community-post`,
  `create-community-comment`, and `upload-community-photo`.
- Shared widget catalog corrected to 29 with 2 dialogs and 5 egg widgets.
- Older entries are archived in [[log-archive-2026-05]].

---

## [2026-05-29] sync | 5-tab audit + l10n/checker stat drift

Synced the five commits that landed after the `bb1798c` wiki sync: `f43b7ef`
(5-tab audit), `27ed5ec` (l10n 2,987->2,992), `dc4efd3` (version 1.1.1+32),
`77e091b` (checker count -> 28), `615cffe` (community tab icons #92).

- Stat drift: l10n **2,987 -> 2,992** (`overview.md` x2, `patterns/l10n.md`,
  `architecture/folder-structure.md`); `verify_code_quality.py` checker count
  **27 -> 28** with **8 -> 9** extras - added the `Spacing` (hardcoded ->
  `AppSpacing`) checker to the enumerated list (`overview.md`,
  `patterns/anti-patterns.md`, `infrastructure/scripts.md`,
  `infrastructure/ci-cd.md`).
- `features/breeding.md`: pair-delete cascade reordered - notifications/calendar
  are cancelled **last**, only after the cascade is confirmed to proceed. A
  blocked delete (child still live) now keeps reminders firing instead of
  stranding a live pair (`breeding_form_actions.dart` `deleteBreeding`).
- `domain/eggs-service.md`: new **Terminal Status** section - `EggStatus.isTerminal`
  (`hatched`/`damaged`/`discarded`/`infertile`/`empty`) is the single source of
  truth, replacing private `_isTerminalEggStatus`. Added fail-closed chick
  auto-create on duplicate-check read failure. Corrected stale symbols
  (`markAsHatched`/`_autoCreateChickIfMissing` -> `_createChickFromHatchedEgg`).
- `verify_rules.py` PASS - all numeric stats already at baseline.

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
  24->25, l10n 2,978/42->2,987/41, tests 906/11,056->901/11,048, migrations
  158->160, Edge fns 8->9, source 989->983, modules 25->24, domain 23->22, SVG
  84->89, shared widgets 28->29, Supabase constants 146->137, remote sources
  27->26.
- `data-layer/tables-catalog.md`: index test asserts schema `>= 23` (floor).
- Code context: test fix `0755905` (date-flaky statistics test) shipped to main,
  CI green.

---

## [2026-05-28] iOS update prompt fix | iOS update dialog crashed

A rootNavigatorKey fix stopped the crash but GoRouter page rebuilds still
dismissed the imperative dialog. Switched to an in-tree banner/full-screen layer
drawn in a Stack over the child, so it survives rebuilds. Verified live on the
iOS simulator.

---

## [2026-05-28] android in-app updates | Added Google Play native in-app updates

Flexible by default, immediate when `updatePriority >= 4`. Custom dialog scoped
to iOS to avoid a double prompt. Added app_update restart/download l10n.

---

## [2026-05-28] consolidate update systems | Removed old update feature

Removed the old `update` feature path. `app_update` is now the single update
path. Feature modules 25->24; l10n 42->41 categories.

---

## [2026-05-27] sync | Map 13 new rule files to existing wiki pages

13 new rule files added to `.claude/rules/` covering previously rule-gapped
domains and services. Total rules: 33->46.

- `sources/rules-index.md`: added all 13 mappings to primary + secondary wiki
  pages.
- Domain and feature pages gained source refs for genetics, encryption,
  moderation, community, messaging, presence, admin, marketplace, gamification,
  statistics, calendar, data-io, and home-widget rules.
- `CLAUDE.md` rule table extended with 14 entries.
- `verify_rules.py`: 24/24 PASS, no stat drift.

Older May 2026 entries are archived in [[log-archive-2026-05]].
