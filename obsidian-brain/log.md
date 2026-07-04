# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

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

## [2026-07-04] docs | Rule: iOS Pods sync after dependency changes

New `.claude/rules/architecture.md` § "iOS Pods Sync" (mirrored in
[[architecture/tech-stack]] § Changing Dependencies), from a real incident:
after T12 added `flutter_displaymode`, `flutter pub get` refreshed the plugin
registrant but the local CocoaPods sandbox stayed stale → Xcode failed with
"The sandbox is not in sync with the Podfile.lock". Rule: every pubspec
dependency change is followed by `cd ios && LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8 pod install` (UTF-8 prefix avoids the CocoaPods
`Unicode Normalization` crash); commit `ios/Podfile.lock` together with
pubspec files when it changes; an unchanged lock is normal for stub iOS
podspecs — the run still regenerates `Pods/Manifest.lock`.

## [2026-07-04] perf (branch) | Rebuild hygiene: calendar filter + risk identity

Branch `perf/performance-improvements`, tasks 10-11 (commits `115f58bc`,
`d86f7d3`, `6c7c015`; review-approved). **Search (T10):** the bird-search
300ms debounce already shipped (`f43b7ef`); added timing regression tests
(200ms→'' / 350ms→value bracketing the timer + immediate-clear bypass) that
were missing, so a debounce removal can no longer pass silently — production
untouched. **Calendar (T11):** new `filteredCalendarEventsProvider` runs
`filterCalendarEvents` once per (stream, filter) change; the month/week/day
providers derive from it instead of each re-filtering. **Risk lists (T11):**
`IncubationRiskSummary.risksForPair`/`risksForIncubation` now return cached,
identity-stable, `List.unmodifiable` buckets (shared `const []` for no-risk
ids) so risk cards skip rebuilds when unchanged; a follow-up fix froze the
lists to prevent shared-cache mutation. **Platform (T12, `e2691aa`):** added
`flutter_displaymode` to request the Android panel's high refresh rate at
startup (guarded, fail-silent); Sentry `tracesSampleRate` now budgeted by env
(`sentryTracesSampleRateFor`: dev 1.0 / staging 0.5 / prod 0.1) per
observability.md instead of a flat 0.3. See [[features/calendar]], [[features/breeding]], [[architecture/tech-stack]].

## [2026-07-03] perf (branch) | Startup + resume path

Branch `perf/performance-improvements`, tasks 8-9 (commits `d80360f`/`d46d8f3`,
review-approved, 0 findings). **Splash (T8):** `appInitializationProvider` no
longer awaits FCM token registration (`pushNotificationService.init`, a network
call) or `_syncAuthMetadataToProfile` before `InitStep.ready` — both move to a
deferred fire-and-forget microtask. LOCAL notification channels +
`rateLimiterReadyProvider` stay awaited (a reminder must not fire before
DND/rate-limit prefs load), and `processPendingPayloads` stays right after
`ready`. `_rescheduleNotifications`/`_recoverPendingNotifications` remain
separate microtasks. **Resume (T9):** new `ResumeThrottle`
(`lib/core/utils/resume_throttle.dart`, in-memory per-key, injectable clock)
gates `_onAppResumed`'s in-app-update check (6h) and RevenueCat premium refresh
(5m) so rapid foreground/background flips don't re-fire them; presence/realtime/
notification-recovery/pushChanges stay unthrottled; `reset()` fires on logout.
Cold-start timing + push-delivery are manual device-QA (not run). See [[features/auth]].

## [2026-07-03] perf (branch) | Sync/cascade/import batching

Branch `perf/performance-improvements`, tasks 1-6 (each subagent-reviewed
clean). **Push (T1-3, `bcd13c7`/`b7d18d7`/`ffb4a49`):** the per-row `pushAll`
loop (one HTTP upsert per pending row) is replaced by
`SyncableRepository.pushPendingBatched` — chunks of 100 → one `upsertAll` +
one `SyncMetadataDao.deleteByRecords` per chunk. New batch metadata helpers
(`getByRecords`/`deleteByRecords`/`markPendingByRecords`) do the pending-marker
bookkeeping in one statement each. Chunk failure falls back to per-item
`push()` (poison-row isolation); `PushStats.pushed` counts only real successes
(telemetry-only). All 13 syncable repos routed through it (mixin hooks + 4
inline). **Cascade deletes (T4-5, `108c0885`/`d6b016c`):** `EventRepository.removeBy*`
→ one `softDeleteByIds` + one `markPendingByRecords` + one best-effort batched
`pushAll`; `GrowthMeasurementRepository.removeByChickIds` → one `hardDeleteByIds`
+ one batch `pendingDelete` metadata + one `BaseRemoteSource.deleteByIds`
(tombstones survive on remote failure). **Import (T6, `5ca9536`):** Excel import
persists via one `repo.saveAll` (no per-row push) + map-based FK validation
(one `getAll`, zero per-row `getById`); batch is all-or-nothing. **Index (T7,
`f9babe0`):** schema v25→v26 adds `idx_conflict_history_user_table_record`
`(user_id, table_name, record_id)` so `ConflictHistoryDao` exists-checks seek
instead of full-scan. See [[data-layer/sync-strategy]], [[data-layer/repositories]],
[[domain/data-io]], [[data-layer/migrations]].

## [2026-07-03] fix (branch) | community post-edit + admin follow-ups

Branch `fix/community-followups` (commit `b9e4f77`, review-approved). 7 deferred
fixes: (1) admin `clearReviewFlag` wrote a non-existent `reviewed_by` column →
removed (that admin action was broken in prod; IMPROVEMENT_PLAN §6.14 closed);
(2) edit sheet now uses the shared `showAppBottomSheet` (SafeArea bottom inset on
notched devices); (3) comment empty-state fires on `visibleComments.isEmpty` so a
fully-muted thread no longer renders blank; (4) `_maxLength` cross-refs the edge
schema; (5) `PostEditNotifier.editPost` → `Future<String?>` so the specific
`edit_window_expired` message surfaces (previously an unused l10n key); (6) dropped
a redundant `invalidateAll()` in `update()`; (7) added a real edit-menu tap-through
widget test. 470/470 community+remote-source tests green (§6.13 + §6.14 closed).

## [2026-07-03] feat (branch) | community mute client (feed + comment filter)

Branch `feature/community-tab-faz1` (commit `40013c0`). Client for `community_mutes`:
remote (`CommunityEngagementRemoteSource` mute methods, `.upsert` idempotent) → repo →
`mutedUsersProvider` (`MutedUsersNotifier`, SharedPreferences + server sync,
optimistic+rollback — mirrors the block stack). Feed filter applies muted after blocked
across all four tab arms; new `visibleCommentsProvider` filters muted+blocked comment
authors and the detail screen renders from it. Light action (no confirm, toast only),
community-only (never touches messaging — mute doesn't affect DMs). 27/27 new tests,
2171 community+data suite green, analyze/l10n/quality clean. Last impl task of the
post-edit + mute branch; migrations (edit hardening, mutes) await the checkpoint apply.

## [2026-07-03] feat (branch) | community_mutes table (soft block, owner-only RLS)

Branch `feature/community-tab-faz1` (commit `74c7ad1`). Migration
`20260703121000_community_mutes.sql`: new `public.community_mutes` table for a
one-directional visibility-only mute — a SEPARATE table (not a `community_blocks`
column) so it can't affect messaging's block-RLS DM rejection. SELECT is owner-only
(`auth.uid() = user_id`, no two-sided branch) so the muted user can't discover the row;
INSERT/DELETE owner-scoped; `FORCE RLS`, `no_self_mute` CHECK, `unique_pair`, index on
`user_id`. NOT applied to prod. Client (repo/provider/feed+comment filter/menu) lands in
the next branch task.

## [2026-07-03] feat (branch) | community post edit UI (sheet, menu, badge)

Branch `feature/community-tab-faz1` (commit `d31eef5`). User-facing edit: content-only
bottom sheet (`community_post_edit_sheet.dart`), `postEditProvider` (`editPost → bool`;
success → `applyPostEdit` + `communityPostByIdProvider` invalidate, failure →
`AppLogger.error` + Sentry, feed left intact), author-only "Edit" menu item gated by
`canEditPost` (UTC now−createdAt < 5 min), `edited` badge on the header, 6 l10n keys
(tr/en/de). 436/436 community tests, analyze/l10n/quality clean. Completes the
post-edit vertical (migration → edge fn → data path → UI) on the branch.

## [2026-07-03] feat (branch) | community post edit client data path

Branch `feature/community-tab-faz1` (commit `68d6a57`). Client wiring for the
5-minute edit: `CommunityPost.editedAt` (`DateTime?`) + `CommunityPostX.isEdited`;
`CommunityPostRepository.update({postId, content})` →
`CommunityPostRemoteSource.updateContent` → `EdgeFunctionClient.updateCommunityPost`
(`mode: 'update'`). `_parsePost` reads `edited_at`; `update` invalidates post cache.
Online-first exemption doc-blocks untouched; generated Freezed files gitignored
(regenerated in CI). UI (sheet/menu/badge) lands in a later branch task.

## [2026-07-03] feat (branch) | community post edit hardening migration

Branch `feature/community-tab-faz1` (NOT yet merged/applied to prod). Migration
`20260703120000_community_post_edit_hardening.sql` (committed `3cdf483`): adds
`community_posts.edited_at timestamptz`, narrows the `authenticated` UPDATE grant
to `(is_deleted, needs_review)` so post **content** can no longer be
edited directly by clients (edits must go through the moderated
`create-community-post` edge fn `mode: 'update'`, being wired in the same branch),
and recreates `fetch_community_feed` (DROP+CREATE — RETURNS TABLE shape changed) to
return `edited_at`. Applied to prod 2026-07-03 (MCP; advisors 0 new). At apply time
the original grant listed `reviewed_by` too, but that column does NOT exist on
`community_posts` (never added by any migration) — dropped from the grant; the
`clearReviewFlag` write to it is a pre-existing latent bug (IMPROVEMENT_PLAN §6.14).
The other 3 authenticated UPDATE call-sites (`softDelete`, admin
`approvePost`/`deletePost`) write only within the grant. Client edit UI +
`edited` badge land in later tasks of the same branch. Design:
`docs/superpowers/specs/2026-07-03-community-tab-design.md`.

Older entries are archived in [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
