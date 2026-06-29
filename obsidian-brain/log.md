# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-06-29] fix | Decorative animations honour reduce-motion (test-safe)

The UI-refresh animation widgets (`PulseAnimation`, `ShimmerShineAnimation`,
`ScannerLineAnimation` — perpetual `repeat()`; `SlideFadeAnimation` — entrance
`Future.delayed`) ran unconditionally, hanging `pumpAndSettle` and leaking
timers across ~40 widget tests. They now read
`MediaQuery.disableAnimations` in `didChangeDependencies` and render the static
end state when reduce-motion is on (a11y win + test-safe). `test/
flutter_test_config.dart` sets `disableAnimations: true` globally via
`FakeAccessibilityFeatures` so every test (helper or custom MaterialApp) is
covered. `progress_bar_test` updated for the new Container-based bar (the
refresh replaced `LinearProgressIndicator`). See [[patterns/ui-patterns]],
[[patterns/testing]].

## [2026-06-29] feat | Admin moderation queue, force logout + aggregate-detail RPC

New `admin_moderation_screen.dart` + `admin_moderation_providers.dart`:
`adminPendingPostsProvider` / `adminPendingCommentsProvider` list community
content with `needs_review = true`; `AdminModerationNotifier`
(`adminModerationProvider`) approves (clear `needs_review`) or soft-deletes
(`is_deleted = true`) posts/comments. Route `AppRoutes.adminModeration`
(`/admin/moderation`). New `admin_users_filter_sheet.dart` (advanced
status/plan/date filters) and `admin_user_detail_content_security.dart`
(security + audit section with **force logout**). 4 Supabase migrations
(`20260627132400`–`20260627134000`, all applied to prod): the
`admin_get_user_aggregate_detail` RPC (one-round-trip user detail, switched
`SECURITY DEFINER` → `INVOKER` to clear the linter warning — safe because all
read tables have admin-inclusive RLS SELECT), SECURITY DEFINER exposure
hardening (revoke PUBLIC/anon execute), and `admin_force_logout` (deletes
`auth.sessions` + stamps `profiles.session_revoked_at`; refresh tokens revoked
immediately, live access token valid ≤1h, no token hook). See [[features/admin]].

## [2026-06-29] feat | BirdLifecycleService cancels reminders on bird exit

New `lib/domain/services/birds/bird_lifecycle_service.dart`
(`birdLifecycleServiceProvider`) — called from `bird_form_providers.dart` when
a bird is sold / gifted / dead / deleted. Cancels active breeding pairs and
their active incubations, and now also cancels the scheduled reminders
(incubation milestones + per-egg turning, species-resolved) so no zombie
notifications fire for a pair that no longer exists, then clears calendar
events. Best-effort + non-rethrowing per `breeding-eggs.md`. Brings the domain
service count to 23. Review fixes in the same pass: 13 missing admin/community
l10n keys added (tr/en/de), `AppIconButton`/`AppIcon` + `mounted`/`LoadingState`
+ `SupabaseConstants` column fixes in the new admin files, stray `scratch.ts`
removed. New tests: `bird_lifecycle_service_test.dart` (4),
`admin_moderation_providers_test.dart` (4). See [[features/birds]],
[[domain/services-index]].

`adminUserCountsProvider` (`admin_users_providers.dart`) now feeds the users
summary bar instead of deriving Toplam/Aktif/Pasif/Çevrimiçi from the loaded
page (capped at `AdminConstants.usersPageSize` = 50, so totals appeared stuck
at 50). Counts come from database-wide queries: total/active via `profiles`
head counts, online via the presence-sessions source. The screen uses global
counts when unfiltered, falls back to the loaded set when filtered/searched,
and invalidates counts on refresh/retry/user mutations (commit `94d0c88`).
See [[features/admin]].

## [2026-06-25] cleanup | Merge auto-audit branch + delete it (main-only policy)

Folded the cloud smoke-audit branch `chore/auto-audit-20260626-1415` (CI-green,
fast-forward from `567c3da`) into `main` and deleted it, leaving `main` as the
only remote branch. Net changes: genetics results `ListView.builder` `cacheExtent`
magic number `300` extracted to a `_kListCacheExtent` constant in
`grouped_results_list.dart` (behavior unchanged; a `scrollCacheExtent` rename
attempt was reverted — that API is absent in Flutter 3.41.4), plus a transitive
test-tooling lockfile bump (meta 1.18.0, test 1.31.0, test_api/test_core).

## [2026-06-25] update | Major dep bumps: flutter_local_notifications ^22, google_mobile_ads ^9

`flutter_local_notifications` 21 → ^22.0.0 (`cbcf297`); v22 adds web support, no
breaking changes to APIs used. `google_mobile_ads` 8 → ^9.0.0 (iOS GMA SDK 13.3.0
+ UMP 3.1.0); no public API changes, ad API usage unchanged. `share_plus` 13 +
`package_info_plus` 10 deferred: both need `win32 ^6`, blocked by `file_picker
11.0.2` (`win32 ^5.9.0`), no functional gain. See [[architecture/tech-stack]].

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
