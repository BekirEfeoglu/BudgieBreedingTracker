# Change Log Archive - 2026-07 (early, incl. 2026-06-30)

Back to [[log]].

## [2026-07-01] fix | Health Records tab audit remediation (double-pop navigation, shared DatePickerField crash, cost validation gap, wiki drift)

Comprehensive review of `lib/features/health_records/` + health-record-adjacent
data/domain/statistics code found 2 code bugs + 1 wiki inaccuracy; fixed with
regression tests, each verified to fail without its fix (temporarily reverted,
reran, restored). (1) `HealthRecordDetailScreen`'s `_DetailContent` and
`HealthRecordFormScreen` both `ref.listen`ed the same unscoped
`healthRecordFormStateProvider` and both called `context.pop()` on
`isSuccess` — editing a record from the detail screen (List → Detail → Form,
both mounted via `context.push`) fired both listeners on the same success
event, popping twice and landing the user back on the list instead of the
updated detail screen. Fixed by removing the detail screen's `ref.listen`
entirely and awaiting `deleteRecord()` directly in `_onDelete` (standard
forms-validation.md await-then-pop pattern), so only the form screen's own
listener pops on edit success. Writing the regression widget test (nested
Detail→Form navigation with a real router) surfaced a second, unrelated
latent bug: (2) the shared `DatePickerField` (`lib/core/widgets/`, 7
consumers across birds/eggs/chicks/breeding/calendar/health_records) synced
its internal `TextEditingController` inside `build()` — mutating the
controller mid-build notifies the wrapping Form, which tries to rebuild an
ancestor that already finished building earlier in the same top-down pass,
throwing "setState() or markNeedsBuild() called during build" whenever a
date field's value transitions from empty/default to a populated value
during a rebuild (exactly what `HealthRecordFormScreen._populateFromExisting`
and its siblings in other forms do on every edit-mode load). Fixed by moving
the sync to `didUpdateWidget` deferred through a post-frame callback, which
runs after the current frame's build completes. Verified against all 7
consumers' existing tests (41 passed) plus a new dedicated regression test.
(3) The cost field's validator only checked `double.tryParse(...) != null`,
silently accepting negative values (unlike the weight field's positive check
right next to it) — added a `< 0` check reusing the existing
`validation.invalid_price` key (same convention as
`marketplace_form_providers.dart`'s price validation, no new l10n key
needed). (4) The wiki page claimed health documents/photos are stored in a
`health-records` Supabase Storage bucket with a 10MB guard — verified no such
bucket, upload widget, or model field exists anywhere in the codebase;
corrected the page, and also fixed its "list is per-bird" claim (the list
screen is actually a global all-birds list; per-bird is a separate embedded
widget in `bird_detail_health.dart`). 5 files changed (3 lib + 2 test) plus
this wiki page; full quality gate green (`flutter analyze`,
`verify_code_quality.py` 27/27, `check_l10n_sync.py`, `verify_rules.py
--strict`, targeted `flutter test` — 188 health-records-scoped + 41
DatePickerField-consumer tests, all passing).

Follow-up in the same session: fixed the flagged icon finding (4 of 7 health
record type icons used `LucideIcons` instead of `AppIcon` SVGs, unlike
injury/death in the same switch). Fetched the exact upstream SVG path data for
`stethoscope`/`thermometer`/`syringe`/`pill` from lucide-icons/lucide (ISC
license — already the source for the LucideIcons versions being replaced) and
adapted them to match this repo's existing icon convention (single-line,
`stroke-width="1.6"`, no explicit width/height) as 4 new files under
`assets/icons/general/`, registered as new `AppIcons` constants, swapped into
`health_record_card.dart`'s `healthRecordTypeIcon()` (89 → 93 icons; CLAUDE.md
stats updated via `verify_rules.py --fix`). `HealthRecordType.unknown` still
uses a generic `LucideIcons.helpCircle` fallback, which is correct (no
domain-specific concept to draw). Full quality gate rerun green.

## [2026-07-01] fix | Chicks tab audit remediation (bulk-action false success, deathDate revival bug, side-effect isolation, Dart-side aggregation)

Comprehensive review of `lib/features/chicks/` + chick-adjacent domain/data/statistics
code found 4 issues; fixed with regression tests for each (verified each test fails
without its fix via `git stash`). Highlights: (1) `ChickListScreen._runBulkAction`'s
`try/catch` around `await action(notifier, id)` never caught anything —
`ChickFormNotifier.deleteChick`/`.markAsDeceased` catch their own exceptions
internally and report failure via `state.error` instead of rethrowing, so bulk
delete/mark-deceased always reported blanket success even when individual items
failed. Fixed by checking `chickFormStateProvider.error` after each awaited call.
(2) `ChickFormNotifier.updateChick` never cleared `deathDate` when a chick's health
status was edited away from `deceased` via the form's segmented button (which only
blocked selecting *into* `deceased` inline, not leaving it) — left a contradictory
"healthy but has a death date" row. Now clears `deathDate` when `previous.healthStatus
== deceased && chick.healthStatus != deceased`. (3) `BandingActionNotifier
.markBandingComplete` was the one action in the whole feature that didn't isolate
side effects (calendar-event completion, reminder cancellation) from its primary
mutation (`bandingDate` save) — a transient failure in either would report
`AsyncError` even though the banding date had already durably saved. Wrapped both
in their own try/catch, matching every sibling action's warning-not-error pattern.
(4) `chickSurvivalProvider` (statistics) walked the full `chicksStreamProvider` list
in Dart to count healthy/sick/deceased — the same anti-pattern already fixed for
`healthRecordTypeDistributionProvider` (its sibling in the same file) and for
`ChicksDao.watchMonthlyHatched`, just missed here. Added
`ChicksDao.watchHealthStatusCounts` (SQL `GROUP BY health_status`) and rewired the
provider onto it. `BandingActionNotifier` had zero test coverage before this pass
(no test file/group existed) — added one. Deferred with reasoning (spun off as
follow-up tasks, not fixed in this pass): the chick weight-tracking data layer
(table/DAO/repository/sync, fully built and tested) has no reachable "add
measurement" UI anywhere in the app; `bird_list_screen.dart` has the identical
bulk-action false-success bug (same `_runBulkAction` shape, same missing coverage);
manually-created chicks have no `species` field, so promoting one silently produces
a `Species.unknown` Bird — all three need a product decision or larger scope than a
same-pass fix. 12 files changed (5 lib + 7 test), full quality gate green
(`flutter analyze`, 27/27 anti-pattern checkers, l10n sync, `verify_rules.py --strict`).

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
