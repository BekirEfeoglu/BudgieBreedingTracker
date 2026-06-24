# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-06-24] update | Dependency maintenance + iOS CI fix (cap supabase_flutter <2.13.0)

`flutter pub upgrade` (within-constraint) bumped sentry_flutter 9.22.0,
firebase_messaging 16.4.1, firebase_core 4.11.0, go_router 17.3.0,
purchases_flutter 10.3.0, sign_in_with_apple 8.1.0, supabase_flutter 2.15.0 —
pubspec.yaml untouched, lockfiles + iOS Podfile.lock re-synced (commit
`0e8cb1b`). That push went red on the **iOS Build** job: supabase_flutter 2.13+
pulls the `passkeys` → `passkeys_doctor 1.4.1` → `device_info_plus 12.4.0`
chain, whose iOS code calls the visionOS-only `NSProcessInfo isiOSAppOnVision`
selector, failing to compile on the CI `macos-latest` Xcode SDK. Fixed in
`c78aa2c` by capping `supabase_flutter: '>=2.5.0 <2.13.0'`, which drops the
passkeys/device_info_plus chain entirely while keeping the other upgrades.
Revisit the cap when CI Xcode is bumped or passkeys is actually needed. See
[[architecture/tech-stack]].

## [2026-06-24] audit | Full-scope review (pristine) + const fix, version bump, iOS pods cleanup

Comprehensive multi-dimension audit (security, architecture, domain logic, data
layer) on `main`. Baseline gates all green: analyze 0, code-quality 27/27, l10n
synced, security 37/37, rules 24/24. Parallel-agent findings were adversarially
verified — nearly all "critical/high" flags proved false positives: genetics
normalize-then-filter is by-design; the chick-care scheduler hour is clamped and
floor-derived (no overflow); `nest`/`notification` repos have no hard FK so need
no `ValidatedSyncMixin`; `marketplace_listing_remote_source.dart` does exist;
`egg_actions_notifier` is tested. See [[patterns/anti-patterns]],
[[domain/genetics-engine]], [[data-layer/repositories]].

Direct-to-main commits:

- `4913abe` (in `207c812`): marketplace gender `ChoiceChip` avatars — added
  `const` to the `AppIcon(AppIcons.male/female)` cases (the only `flutter
  analyze` issue in the tree). `LucideIcons.helpCircle` for `BirdGender.unknown`
  left as-is — app-wide convention (`bird_gender_icon`, bird/chick detail) and
  the quality scanner accepts it (no domain SVG for unknown gender). See
  [[features/marketplace]].
- `bb1dcd8`: version bump `1.1.2+34` -> `1.1.3+50`.
- `bc99b91`: iOS `project.pbxproj` — dropped redundant empty
  `inputPaths`/`outputPaths` from the Pods copy-resources / embed-frameworks
  build phases (xcfilelist paths retained). See [[infrastructure/release-ops]].
- Root `CLAUDE.md` Start Here now points to this wiki + `AGENTS.md` +
  `run_local_quality_gate.sh` / `check_remote_status.py`.

`pubspec.lock` transitive test-package downgrades (meta/test/test_api/test_core)
were intentionally NOT pushed — a local-env resolution artifact.

---

## [2026-06-21] audit | App-tab sweep + anti-pattern #24 / error-logging fixes

Comprehensive read-only audit of all app tabs (5 bottom-nav screens + ~70
sub-screens via the More hub). Quality gates clean (27-checker scan 0/0,
analyze clean). Direct-to-main fixes (commit `651df06`):

- genetics `AiWelcomeScreen`: `_FeaturePill` icon param `IconData` -> `Widget`;
  dna pill now uses `AppIcon(AppIcons.dna)` to match the hero icon
  (anti-pattern #24). Generic image/search pills stay on `LucideIcons`.
- breeding `_PairRiskCard` + gamification `BadgesScreen` XP header: secondary
  sections still hide on error, but now log via `AppLogger.error` instead of
  swallowing silently (consistency with the HomeScreen pattern).
  See [[features/breeding]], [[features/gamification]].

Same-day branch cleanup — merged the three open audit-routine PRs to main, then
deleted all non-`main` remote branches (only `main` remains):

- `#117` (`de62ab9`): `offline_banner` LucideIcons -> AppIcons. See
  [[patterns/empty-loading-error-states]].
- `#115` (`7b9cdca`): marketplace gender `ChoiceChip` avatars -> domain
  `AppIcon` + regression test (+1 test, stats 11,096 -> 11,097). See
  [[features/marketplace]].
- `#116`: closed as a duplicate of `#115` (same marketplace fix, no test).

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
