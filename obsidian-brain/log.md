# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-05] docs | ci-actions rule: non-required Pages `deploy` transient

Encoded this session's push lesson so a transient GitHub Pages failure isn't
mistaken for a CI failure again. `ci-actions.md` § Post-Push Verification now
distinguishes the authoritative signal (commit status `success` + required
`ci.yml` check-runs) from the branch badge, and a new § Non-Required / Transient
Checks documents `pages-build-deployment`/`deploy` (auto-generated, non-required,
`docs/` site): its `Deployment failed, try again later.` / stuck-`building`
failures are GitHub-side infra, non-blocking, self-heal on the next push — re-run
once at most, never chase. Mirrored in [[infrastructure/ci-cd]].

## [2026-07-05] fix | Realtime log-throttle reset defeated by null-error statuses

`RealtimeErrorLogThrottle` (the Sentry breadcrumb-budget guard) was reset on any
null-error subscribe status. The Supabase SDK reports `closed`/`timedOut` with a
null error mid-reconnect (`realtime_channel.dart`), so the counter was cleared
between every `channelError` — the 5-warning cap never engaged and a failing
channel logged `.warning` forever (surfaced by the iOS Simulator
`EADDRNOTAVAIL, port 0` reconnect storm on `community-posts-feed`). Extracted the
correct policy into shared `handleRealtimeSubscribeStatus`
(`lib/data/remote/api/realtime_subscribe_status_handler.dart`): reset only on
`subscribed`; log (throttled) on `channelError`/`timedOut`; ignore transient
`closed`. Wired into `CommunityPostRemoteSource` + `EventRemoteSource`; 4 TDD
tests. Mirrored in [[patterns/observability]]. Underlying WebSocket bind failure
is environmental (simulator); REST feed unaffected.

## [2026-07-05] feat | Community feed visual redesign

Working-tree redesign of the community feed UI (behavior unchanged). New shared
`community_avatar.dart` (`CommunityAvatar` — circular avatar with optional brand
gradient ring + first-letter initials fallback, reused across post header, guide
cards, story strip). Pill tabs (`community_pill_tabs.dart`) now show icon+label
inline with the active tab filled by the `AppColors.primary→primaryLight`
gradient and full-radius pills. Action bar (`community_post_actions.dart`): liked
heart → `colorScheme.error` (red), bookmark → `AppColors.accent` (amber). FAB,
feed overlays, guide cards, and post card body/parts restyled to `AppColors`
brand accents. One new l10n key `community.guide_badge` ("Rehber", tr/en/de).

## [2026-07-05] fix | Excel round-trip: incubations imported + health exported

Audit found "Option B" wasn't lossless: export wrote an Incubations sheet but
import had no parser (round-trip dropped every incubation + dangled egg
`incubationId`); symmetrically export omitted health records. Added
`parseIncubationRow`/`parseIncubationStatus`/`importIncubationsFromExcel` (wired
breeding_pairs→incubations→eggs for FK ordering), un-truncated the exported
incubation id, `_addHealthRecordsSheet` + id-preserving `parseHealthRecordRow`,
`IncubationRepository` injected, 8 new `export.*` l10n keys. +2 round-trip tests;
gates green. See [[domain/data-io]].

## [2026-07-04] fix | Excel is now a lossless round-trip (Option B)

Follow-up to Option A, per user request. `ExcelExportService` now writes each
sheet in the import parser's exact column order with a trailing full-uuid ID
column (birds also carry death/sale dates; eggs the incubation link), and
serializes gender/species/status as stable enum NAMES (not localized labels) so
re-import parses them in any locale. The parsers PRESERVE the exported id
(idempotent upsert; lineage FKs resolve to the same rows). `findSheet` folds
diacritics and the importer also accepts the export's l10n sheet-name key
("Kuşlar" ↔ "Kuslar"). Two real export→import round-trip tests (birds with
lineage; pairs/eggs/chicks id preservation) + 156 import/export tests green. See
[[domain/data-io]].

## [2026-07-04] fix | Excel import tolerates unresolvable parent refs (Option A)

Deferred audit item (F-IO-1); user chose Option A. Re-importing an export
silently dropped every bird with a father/mother + all pairs: the import
regenerates ids, so the FK refs (old ids) never resolved and the parent
validation threw `birds.not_found`, skipping the whole row. `_sanitizeBirdParents`
now NULLS an unresolvable parent ref and still imports the bird (drops only the
dangling link); a parent that resolves but is genetically invalid (wrong
gender/species) still rejects. `_importSheet`'s `validate` returns the sanitized
item to persist. Pairs still skip (they need two real birds). Discovered in
passing: the export report and import template column layouts differ (only
name/ring/gender/parent-ids/notes align), so the true lossless round-trip is the
encrypted backup, not Excel — the class doc + data-io wiki now say so. See
[[domain/data-io]].

## [2026-07-04] fix | Sync stale-error cleanup moved out of the push phase

Deferred audit item, now requested. `ValidatedSyncMixin.pushAll` ran
`clearStaleErrors` first — in the PUSH phase, before the reconcile pull. Deleting
an error `sync_metadata` row there strips reconcile protection
(`getPendingRecordIds` = pending+error), so the following full pull could
hardDelete an unsynced local-only record → data loss. Removed the push-phase call
(the orchestrator's `cleanupUnrecoverableErrors` already runs it globally POST-pull,
the safe time), and set `createdAt` in `markPending`'s insert branch so the (now
sole, post-pull) cleanup + Sentry monitoring stop being inert on the common
`pending→error` path (createdAt was null → zombie error rows forever). Converted the
two push-phase-cleanup tests into "pushAll does NOT clean" regression guards; 510
repo+sync green. See [[data-layer/sync-strategy]].

## [2026-07-04] fix | Comprehensive audit sweep — 8 findings fixed, 2 deferred

Full multi-subsystem bug hunt (8 parallel audit agents), each fix verified.
**genetics** — `inbreeding_calculator` double-counted Wright loops through a
common ancestor's own ancestors (full-sib mating with an inbred grandpa returned
0.359375 vs the correct 0.265625, inflating risk bands); rewrote to store
vertex-set paths + a disjoint-path rule + recursive memoized F_A (1123
genetics/genealogy tests green). **calendar** — auto-generated milestone/hatch
events were stored at UTC-midnight then bucketed by local day, showing a day
earlier than the local-wall-clock reminder in UTC-negative zones; switched to
local field addition to match the scheduler. **marketplace** — feed/tab favorite
toggle was non-optimistic with no refresh and its error listener lived only on
the form screen (tap looked like a no-op on success / silent on failure); the
notifier now invalidates the list providers on success and the feed/favorites
screens surface errors. **messaging** — `message_remote_source` realtime
callbacks now use `RealtimeErrorLogThrottle` (sibling sources already did); new-DM
search got a sequence guard. **chicks** — bulk action gained the `_isBulkRunning`
re-entry guard `BirdListScreen` already had. **breeding** — incubation detail now
passes `species` to the milestone/stage calculator (cockatiel/finch drifted a day
from reminders). **genealogy** — `initPedigreeDepth` await→ref.read now
mounted-guarded. Deferred with tasks: push-phase stale-error cleanup timing
hazard + Excel round-trip FK loss (freshly-iterated / product-decision surfaces).
See [[domain/genetics-engine]], [[domain/calendar-service]], [[features/marketplace]].

## [2026-07-04] fix | Four surfaced findings fixed in order (D, A, C, B)

The user asked to fix all four findings the bug hunt surfaced but had deferred.
(D) `72f095e` eggs — deleting the sole/last egg now cancels the now-empty
incubation (`fromDelete` flag) instead of stranding it `active` against the
free-tier limit. (A) `6101459` sync — pull recorded a conflict only when remote
was strictly newer, but insertAll overwrites unconditionally, so a pending local
edit clobbered by an equal/older remote (clock skew) was silently discarded;
conflict RECORDING widened to any pending overwrite (server-wins unchanged), and
the 14 divergent per-repo conflict loops collapsed into one shared
`detectPullConflicts`. (C) `ddeb1a7` sync — unified the stale-error threshold
(`maxSyncRetries` → `RetryScheduler.maxRetries`; the >=10 branch was unreachable)
and gave `clearStaleErrors` the orchestrator path's 24h age guard. (B) `0bc0bc0`
sync — the incremental pull cursor is rolled back 5 min at read time to tolerate
device-vs-server clock skew (persisted checkpoint + display unchanged). Each fix
has regression tests; 511 repo+sync green, analyze clean. See
[[data-layer/sync-strategy]], [[domain/eggs-service]].

## [2026-07-04] docs | DST field-addition pattern synced to rule + wiki pages

Follow-up doc sync for `07638b5`: `.claude/rules/datetime-format.md` § Hatch
Date Prediction rewritten (Duration-add was still blessed as "acceptable" —
now field addition is mandatory, new anti-pattern #10) and the pattern
documented in [[patterns/datetime-format]] + [[domain/incubation-service]].

## [2026-07-04] fix | Two correctness bugs from a live-code bug hunt

Four adversarial bug-hunt agents swept the live high-risk subsystems
(breeding/egg lifecycle, sync/data, datetime/notifications, genetics); each
finding was re-verified against source before any change. Two confirmed HIGH
bugs fixed. (1) `f52fd49` genetics: `ViabilityAnalyzer._checkOffspringHomozygous`
short-circuited on parent VISUAL sets, so an autosomal-recessive lethal
(Feather Duster) never warned for carrier×carrier — now relies solely on the
authoritative per-offspring `doubleFactorIds`. (2) `07638b5` incubation: milestone
+ banding dates used `startDate.add(Duration(days:N))` (DST-drifts a day; the
notification fired a day off from the calendar events) → switched to DST-safe
field addition in notification_scheduler, incubation_calculator, chick_model.
Both got regression tests; 1399 affected tests green. Surfaced but NOT changed
(need product/architecture decision): sync conflict-recording gap on equal/older
remote timestamps, checkpoint device-clock skew, retry threshold 7-vs-10
divergence, sole-egg-delete leaving an incubation stuck active. See
[[domain/genetics-engine]], [[domain/incubation-service]].

## [2026-07-04] docs | New rule: documentation-sync (every change updates docs)

Added `.claude/rules/documentation-sync.md` — the canonical home for the
"every change updates CLAUDE.md + rules + obsidian-brain, same change" discipline
that was scattered across ai-workflow.md, release-ops.md § Documentation Drift,
code-review.md § 10, and this wiki's Ingest contract. Covers the source-of-truth
hierarchy, a what-changed→what-to-update table, the Ingest/≤200-line contract,
the three verification scripts, and CI enforcement (rules-sync, code-quality,
auto-fix-stats). Registered in CLAUDE.md § Rules table + [[sources/rules-index]];
ai-workflow.md Related footer points to it.

## [2026-07-04] docs | Wiki gap + drift fix (parallel to rule sweep)

Extended the coverage sweep to obsidian-brain. Created [[domain/ads-service]]
(the ads subsystem had no wiki page — banners/interstitials/rewarded were only
punted to premium-service). Verified 5 wiki claims against source and fixed the
drift: profile.md avatar bucket `bird-photos`→`avatars` (path
`avatars/{userId}/avatar.{ext}`, sizing 512px/q80 not 1920/q85) and account
deletion "grace period"→`AccountDeletionController` + AAL2 order; feedback.md
categories 5→3 (`bug/feature/general`), statuses →`open/inProgress/resolved/
closed`, class → `FeedbackRemoteService` (online-only, not a `*Repository`
exemption); settings.md account deletion grace→AAL2 + `BackupScheduler` marked
unwired; genealogy.md gained the `PremiumGuard` route note + PDF export. Also
corrected my own `settings.md` rule (accessibility section is wired: font scale
+ reduce-animations + haptics, not "unwired"). index.md + services-index.md
register the new page.

Older entries are archived in [[log-archive-2026-07-e]], [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
