# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-01] fix | Breeding tab audit remediation (race condition, FK gap, warning surfacing)

Multi-agent audit of `lib/features/breeding/` + `lib/domain/services/eggs/`
(providers/services, data layer, UI) found 10 issues; fixed in priority order.
Highlights: (1) `EggActionsNotifier.updateEggStatus` re-fetches by id before
writing — a stale `Egg` snapshot held across an async UI gap (status sheet)
could otherwise resurrect a soft-deleted egg if its breeding pair was removed
concurrently, including re-triggering chick auto-create against an
already-deleted incubation chain. (2) `ClutchRepository.validateForeignKeys`
never checked `breedingId`, the one FK with a real Postgres constraint — added
the check, removed the `incubationId` check (that field is unconditionally
stripped by `toSupabase()`, so validating it only blocked otherwise-valid
pushes). (3) `deleteEgg` never re-triggered `_completeIncubationIfAllEggsTerminal`
(only `updateEggStatus` did) — deleting the last non-terminal egg left the
incubation stuck `active` forever, stranding a free-tier slot. (4)
`BreedingFormNotifier`'s `warning` surfacing was inconsistent: `deleteBreeding`
correctly showed `errors.background_tasks_partial` on side-effect failure,
but `createBreeding`/`cancelBreeding`/`completeBreeding`/the species-change
path in `updateBreeding` silently swallowed the same class of failure —
`BreedingNotificationHelper`'s three methods now return `bool` instead of
`void` so callers can tell. (5) `deleteBreeding`'s cascade never cleaned up
legacy `Clutch` rows (the in-app UI doesn't create them, but cross-device/old
data can have them). (6)-(10): double-submit window in the breeding form
during the awaited inbreeding-confirmation dialog (`_submitting` flag added);
`EggStatus.unknown` produced zero valid transitions in
`getValidStatusTransitions` despite being non-terminal (dead end recoverable
only via delete+recreate — now offers the same transitions as `laid`, and the
switch is exhaustive instead of wildcard-`_` so a future enum addition can't
silently fall through again); hardcoded Supabase strings in
`ClutchRemoteSource.fetchByBreeding`; no busy indicator on the breeding detail
popup menu during complete/cancel/delete. All fixes covered by new/updated
unit + widget tests; full project `flutter analyze` and quality gate clean.

## [2026-06-30] fix | Birds tab audit remediation (lifecycle warning, decrypt safety, a11y)

Multi-agent audit of `lib/features/birds/` (data/provider/screen/widget layers)
found ~30 issues; fixed in priority order. Highlights: (1) `BirdFormState` gained
a `warning` field — `cancelActiveBreedingsForBird` now returns `bool` so
delete/markAsDead/markAsSold/markAsGifted surface `errors.background_tasks_partial`
on cleanup failure instead of dropping it silently (breeding/egg notifiers already
did this; birds didn't). (2) `BirdsDao._decryptSensitive` no longer returns raw
ciphertext as plaintext on decrypt failure — logs + blanks the field
(`encryption.md` violation). (3) `createBird`: bird-row-persisted-but-photo-row-failed
no longer reports total failure (duplicate-bird-on-retry risk) or deletes the
storage object the saved bird's `photoUrl` references (dangling-ref bug) — both
traced via exact code-flow reading, not just the audit's surface description.
(4) Bulk-select `Checkbox` and two `OutlinedButton`s were below the 48dp WCAG
floor (`VisualDensity.compact` / `AppSpacing.touchTargetMin` misuse). (5) Added
missing test coverage for `BirdGridCard` and `BirdDetailTimeline` (zero tests
before this pass). Several audit-suggested fixes were investigated and declined
with reasoning (not applied): gender-icon consolidation into `BirdGenderIcon`
would change icon *color* at 3 call sites (unintended visual side effect);
`updateItem`/`fetchByGender` "dead code" both have dedicated passing unit
tests (deliberate API surface, not accidental cruft); `resolveAll()` provides
no real batching over `birdsStreamProvider`'s existing `Future.wait` pattern
(traced the implementation — it's the same `Future.wait(urls.map(resolve))`);
`RefreshIndicator` not awaiting fresh data is a codebase-wide pattern shared
with `breeding_list_screen.dart`/`chick_list_screen.dart`, not bird-specific.
27 files changed (17 lib + 8 test modified + 2 test created), full quality gate
green (`flutter analyze`, 27/27 anti-pattern checkers, l10n sync, `verify_rules.py --strict`).

## [2026-06-29] fix | Cert-pin rotation + unbounded sync timeout (sync stuck)

Device logs showed all Supabase calls failing with
`TlsException: Certificate pinning check failed` — Supabase rotated its leaf cert
early (new `E4:89:…`, valid 2026-06-28→09-26, Google Trust Services WE1) ahead of
the pinned `B9:B8:…` cert's 2026-07-29 expiry, so every request was rejected at TLS
and nothing synced. Verified the new fingerprint independently via `openssl s_client`
(not a MITM), added it to `certificate_pinning.dart` `_trustedFingerprints` keeping
the previous leaf for rotation overlap (security.md procedure). Separately hardened
`sync_orchestrator.dart`: push/pull phases had no timeout, so a stalled request left
`isSyncingProvider` true forever (UI stuck on "Senkronize ediliyor…") — added a 45s
network-phase timeout (injectable for tests) that converts a hang into a recoverable
error. Regression tests added for both.

## [2026-06-29] security | Harden admin_force_logout SECURITY DEFINER exposure

Supabase linter `0029` flagged `public.admin_force_logout(uuid)` as an
`authenticated`-callable `SECURITY DEFINER` RPC. Body already guards on
`public.is_admin()` (no privilege escalation), but the function — added
`20260627134000`, after the same-day linter-fix migrations — skipped the
established `private`-schema hardening pattern from `20260501115000`. New
migration `20260629120000_harden_admin_force_logout_exposure.sql` moves the
privileged impl into `private`, keeps a `public` `SECURITY INVOKER` wrapper
(public name + signature unchanged, so `admin_user_manager.dart` rpc call is
untouched), and re-scopes grants to `authenticated, service_role`. Idempotent;
not yet deployed (`supabase db push` pending). Migration count 178→179 across
CLAUDE.md, data-layer.md, overview.md, supabase.md. Documented the SECURITY
DEFINER RPC exposure pattern in [[data-layer/migrations]].

## [2026-06-29] test | Repair 44 UI-refresh widget-test failures

Second pass after the reduce-motion fix. Root causes + fixes: stale provider
overrides opened real Drift streams (cleanup-timer leaks) — home/breeding/
active-breedings/main-shell now stub `birdByIdProvider` /
`birdsByUserIdMapProvider` / `profileSyncProvider`; `SliverAppBar.large` renders
the title twice so title finders moved to `findsWidgets`; scroll structure
changed `ListView`/`SingleChildScrollView` → `CustomScrollView`/`SliverList`/
`SliverGrid`; the 300ms search debounce must be advanced before asserting
no-results; loading buttons keep a non-null no-op handler (assert spinner / no
submit, not `onPressed == null`); a custom `MediaQueryData` shadowed the global
`disableAnimations`; pending `Future.delayed`/RPC timers drained or stubbed
(`reset_user_data`). See [[patterns/testing]].

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

Older entries are archived in [[log-archive-2026-06]] and [[log-archive-2026-05]].
