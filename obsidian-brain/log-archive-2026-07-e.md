# Change Log Archive - 2026-07 (part 5)

Back to [[log]].

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
