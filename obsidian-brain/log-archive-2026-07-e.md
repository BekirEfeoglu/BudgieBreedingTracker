# Change Log Archive - 2026-07 (part 5)

Back to [[log]].

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

## [2026-07-04] docs | 7 missing rule files created (coverage gap sweep)

Compared `.claude/rules/` coverage against the 24 feature modules + 23 domain
service dirs; seven shipped subsystems had no rule file. Created, grounded in
current code by three parallel code-exploration passes: `ads.md` (lazy SDK
init, ATT ordering, real banner call sites, rewarded access providers),
`app-update.md` (overlay-not-dialog prompt, minSupportedBuild force, fail-open),
`genealogy.md` (single-fetch traversal, depth persist, truncation-aware
inbreeding), `health-records.md` (mixin FK checks, follow-up reminders, known
chick-selector gap), `profile.md` (account deletion order + AAL2 guard),
`feedback.md` (online-only naming, device-info transparency), `settings.md`
(hub map — contract owners per toggle). CLAUDE.md § Rules table +
[[sources/rules-index]] updated; marketplace.md ad-placement line annotated as
design-goal (banners not wired to marketplace).

## [2026-07-04] docs | Rulebook drift sweep #2 (constants vs prose)

Second verification pass over `.claude/rules/` + `CLAUDE.md`, this time
checking numeric/schema claims against source. Fixed: assets-images icon
count 89→93 (mirrored in [[patterns/assets-images]]); presence.md's 30s
heartbeat / 90s TTL narrative replaced with the real
`user_presence_constants.dart` values (2 min beat / 5 min onlineThreshold /
10 min sessionTtl) across Heartbeat, TTL, Performance, throttle and the
anti-pattern; background-sync.md + [[data-layer/sync-strategy]] fictional
`SyncMetadata` schema (entityType/dirtyCount/markDirty) replaced with the
real per-record model (table_name, SyncStatus pending|pendingDelete|error,
UNIQUE(table_name,record_id), success deletes the row); encryption.md usage
claim widened (birds_dao + backup pipeline + app.dart dispose);
error-handling gained the missing `NotFoundException`; empty-loading's
nonexistent `ServerException` row corrected. CLAUDE.md script lists gained 8
missing entries (run_local_quality_gate, check_remote_status,
verify_security, git hooks, breeding regression + 3 test files). CI job
table verified against ci.yml — no drift.

## [2026-07-04] docs | Rulebook drift sweep (batched sync, pods, deps)

Rules + CLAUDE.md reconciled with shipped code after a full review of
`.claude/rules/` + `CLAUDE.md`. Fixed stale facts: background-sync.md's
fictional "500ms debounce before push" replaced with the real batched-push
contract (pushPendingBatched chunks, poison-row fallback, telemetry-only
`PushStats.pushed`); performance.md's two-arg `AppLogger('perf', ...)`
examples corrected to the single-message contract (mirrored in
[[patterns/performance]]); data-layer.md remote-source count 26→27;
data-io.md documents the all-or-nothing `saveAll` Excel import; premium
entitlement flow notes the 5-min `ResumeThrottle`. Added missing content:
notifications.md § FCM deferred-off-splash guard, observability.md
`sentryTracesSampleRateFor` enforcement note, calendar.md single-pass
filter rule, CLAUDE.md key-dep corrections (supabase iOS-CI cap,
purchases 10.2.3) + pod-install build command + an "Adding or bumping a
dependency" workflow. Oldest two log entries rotated to the new
[[log-archive-2026-07-d]].
