# Change Log Archive — July 2026 M

Archived July 2026 entries (07-17 to 07-25) rotated out of [[log]] during the
2026-07-25 Codemagic-removal documentation sync.

---

## [2026-07-25] audit | Aspirational-contract sweep: rules/wiki reconciled to code

Docs-only. Rewrote claims that asserted current behavior the code never had:
gamification XP table (real 11-entry `xpValues` + 3 daily caps), no level cap,
leaderboard is all-time top-100 only (no monthly/self-rank/TTL/materialized
view), XP award is a network write; marketplace monetization tier (boost, renew,
expiry, 7-day edit window, premium photo quota, phone opt-in) does not exist and
soft-delete is `is_deleted`; notification channels are the five
`NotificationChannelConfig` ids + `default` with no per-channel importance, and
send-push is `BATCH_SIZE=50` within `MAX_TOKENS=500`; deeplink payload is a
`'<type>:<id>'` string resolved by `payloadToRoute`, not JSON with a `route`;
calendar event types come from the real 18-member `EventType`, the feed uses
`watchAll` + in-memory month filtering on `eventDate` (no `start_at` range
query); DM push is not shipped. Constants corrected: community cache 5 min /
`maxScroll - 200` px / no like cache, DM page 50 with `content`+`created_at`
columns, admin health 5 min, `EggStatus` has 9 members. Fixed 6 wrong migration
timestamps and the auth logout order (FCM deactivation runs before `signOut` for
RLS). Recorded this session's code changes: genetics `calculationVersion` v9,
Drift shared-index `_tableExists` guard, ads on `effectivePremiumProvider`
(param renamed `premiumAccessProvider`), release builds ignore `ALLOW_PROXY`,
new Sentry reports for exhausted decrypt keys / `getFactors` fail-open, and the
signed-URL logging precedent. known-gaps +8.
## [2026-07-24] ci | check_remote_status.py distinguishes Xcode-Cloud-pending from real pending

`check_remote_status.py` reported a bare `commit status is pending` for any
non-success aggregate state, conflating a genuinely running check with the
common benign case where every ci.yml check-run is complete and green but the
commit has zero legacy status contexts (Xcode Cloud posts `BudgieBreedingTracker
| Default` up to ~1h late, push tip only). When state is pending, contexts are
zero, and all check-runs are complete with none failed, it now emits an
explanatory reason (still `is_clean=False` — verification waits for the context);
a still-running check keeps the generic pending. Two tests added
(`check_remote_status.py` 99%). Documented in ci-actions.md § Xcode Cloud status
context. Also rotated the two oldest (2026-07-14) entries into
[[log-archive-2026-07-l]] to stay under the 200-line cap.

## [2026-07-23] audit | Full-scope sweep: saveAll metadata collision, Sentry filter, deflake, #8 constants
7-lane read-only audit from a pristine baseline (all scripts + CI green). Four fixes landed:
- **P2 correctness (offline):** `SyncMetadataDao.insertAll` built each row with a FRESH v7 PK but targeted an existing `(table_name, record_id)`; `insertAllOnConflictUpdate` conflicts on the PK only, so the fresh PK fell through to the `UNIQUE(table_name, record_id)` index and threw. Broke offline breeding cancel/complete (`closeActiveIncubations` → `incubationRepo.saveAll` on an incubation that still had a pending row) mid-cleanup → zombie reminders + false `errors.unknown`, and genealogy orphan repair. Fixed at the DAO (one place, all 14 `saveAll` callers) to be records-aware: reuse each existing PK, preserve `createdAt`, status-agnostic (pending saves + `pendingDelete` tombstones). Real-DB regression test added.
- **Observability:** community post/comment mutators (Like/Bookmark/Delete/Edit/Pin/Follow/CommentForm/CommentDelete/CommentLike + 2 report widgets) and `FeedbackFormNotifier` called `Sentry.captureException` directly, flooding Sentry with expected `Validation`/`Network` exceptions. Routed through the existing `SentryErrorFilter` (`reportIfUnexpected` / `reportUnexpectedToSentry`). Sibling hunt found 2 extra sites in `community_create_providers` (guard-RPC + image-cleanup).
- **Test deflake:** `premium_sync_rpc_test` `Future.delayed(3s)` raced a real 2s backoff on the PR gate. Added `premiumSyncBackoffProvider` seam (prod default `Future.delayed`), test overrides to instant — ~6s wall-clock removed.
- **#8 SupabaseConstants (fully closed):** onConflict composites + auth-role/messaging-search literals, then in a follow-up the free-text `.or()` search literals (marketplace/community `title`/`description`/`content`) + admin `details::text` cast + `system_settings` `key`/`value` reads. Added `colTargetId/colTargetType/colBadgeId/colDisplayName/colTitle/colDescription/colContent/colDetails/colKey/colValue` (constants → 202). SupaCol scanner + a full-lib sweep now find zero remaining hardcoded column strings.
- **localization_flow_test deflake:** `_waitForLocale/_waitForDateFormat` polled a `DateTime.now()` wall-clock deadline (near-now flake under CI load) → rewritten to bound by event-loop yields (`Duration.zero`), value-equality as the readiness condition.
Migration prod-parity confirmed via Supabase MCP (3 post-baseline migrations applied; ledger clean). Security advisors: 2 known non-blocking (private-schema RLS INFO by-design, leaked-password dashboard toggle). Genetics clean; edge functions re-verified (all 12 pass JWT/validation/tests/deploy-registration/no-orphan — the lane's first run had not completed).
Also documented Xcode Cloud's post-push status semantics after a wrong theory ("no `lib/` change → no build") was formed and then refuted by a 20-commit scan: it reports as a legacy status context, builds only the push tip (intermediates stay `pending` forever on zero contexts), can land ~1h after Actions are green, and has no path filter — see ci-actions.md § Xcode Cloud status context.
Backlog follow-up: added create-community-comment malformed-body/invalid-uuid deno cases (suite 255→257); introduced the first Drift schema-consistency test (`migration_test.dart`: version + 20 tables + sync_metadata unique index + FK) — the `drift_dev schema` generated verifier can't compile (`table_name` → `tableName` field collides with `Table.tableName`), so it uses `sqlite_master`/`PRAGMA`. migrations.md's fictional `TestDatabase.atVersion`/`migrateTo` harness replaced with the real one; cross-version data-migration coverage recorded as a known gap.

## [2026-07-22] docs | Synchronize release and dependency snapshots

Updated the current build snapshot to `1.1.7+56` and aligned the Firebase Core
and RevenueCat package references with `pubspec.yaml` across rules and wiki pages.

## [2026-07-19] release | Bump the app version to 1.1.7+54

Updated the Flutter release version and runtime app metadata together. Android,
iOS Runner, and the dashboard widget continue to inherit the shared Flutter
build name and number.

## [2026-07-19] deploy | Enforce the scanned-image upload cap in production

Applied `20260717120000_align_scanned_image_upload_limits.sql` through an alias-mapped temporary CLI fixture so the remote ledger keeps the exact local version and SQL without rewriting historical migrations. Production now enforces 2 MiB on all seven safety-scanned image buckets, keeps `backups` at 50 MiB, and passes the online migration parity check.

## [2026-07-19] auth | Preserve post-login destinations and complete password recovery

Protected deep links survive OAuth, MFA, and startup through validated one-shot `returnTo` state. Recovery sessions stay on the new-password form until Supabase updates the password;
login UX adds bounded feedback, reduced motion, accessible controls, localized Apple labels, and four golden baselines.

## [2026-07-19] guard | Freeze the applied migration chain in a separate baseline fixture

Added an immutable filename/SHA-256 baseline through canonical `20260714200511` and recorded nine apply-time aliases without rewriting historical SQL.
The online guard parses only the remote ledger column and exposes `20260717120000` as the remaining explicit local-only migration.

## [2026-07-18] security-fix | Supabase RSA TLS fallback added to pin allowlist

Sentry release-54 telemetry from an Android 11 device exposed a false pinning
rejection while newer clients remained healthy. Live TLS reproduction showed
that the Supabase/Cloudflare endpoint serves the pinned ECDSA leaf to default
clients but a distinct Google Trust Services RSA leaf to RSA/TLS 1.2 clients.
The verified RSA fingerprint is now allowlisted alongside the ECDSA and
rotation-overlap pins; unknown certificates and production proxy connections
remain rejected. The rotation rule now requires checking both certificate
variants, with a focused regression for the RSA fallback.

## [2026-07-18] ci-fix | Android release build numbers are package-global

A signed Codemagic alpha release proved that Google Play reserves version codes
across tracks and uploaded artifacts: the alpha-scoped latest-build query chose
an already-used code. Android release versioning now queries the package-wide
Play maximum before incrementing, while the publishing destination remains the
alpha track. A static workflow contract prevents track-scoped regression.

## [2026-07-18] db-fix | Historical health-record migration no longer indexes a future column

Release-emulator Sentry verification exposed a v25 upgrade failure: the shared
performance-index helper attempted to index `health_records.chick_id` before
v27 added that column. The two chick indexes now use a schema-presence guard;
v27 invokes the helper again after adding the column. A file-backed sequential
v25→v29 regression preserves a legacy row and verifies the column plus indexes.

## [2026-07-18] auth-fix | Disabled guest CTA now matches server policy

Release-emulator verification found that the login screen advertised guest
access even though Supabase anonymous sign-ins are deliberately disabled.
Production now hides the guest CTA and limitation copy behind the matching
static client flag; card-level opt-in support remains for a future coordinated
server/RLS rollout, with client/server contract and widget regressions.

## [2026-07-18] ci-fix | Codemagic release SDK drift pinned to verified Flutter

The first store-free Android verification build reached signed AAB compilation
but Codemagic's moving `stable` channel had advanced to Flutter 3.44.6, where
locked `lucide_icons 0.257.0` no longer compiles because `IconData` is final.
All three Codemagic release workflows now pin Flutter 3.41.4, matching GitHub
Actions and Xcode Cloud; a static contract prevents silent channel drift.

## [2026-07-18] ci | Exact-SHA verifier recognizes only proven path-gated deploy skips

The remote status verifier now accepts a skipped `Deploy Edge Functions` job
only when `Edge Function Changes` completed successfully on the same commit.
This closes the false-negative for CI/docs-only pushes while preserving the
fail-closed behavior when the deployment detector fails or is missing.

## [2026-07-18] ci | Codemagic Android verification separated from store publishing

Added a manual `android-verify-only` workflow that produces a signed,
obfuscated AAB, uploads Dart symbols to Sentry, and retains both artifacts
without referencing Google Play credentials or declaring a publishing block.
Its version/build comes from the committed `pubspec.yaml`, so verification does
not query or mutate external store state; a static CI contract locks this down.

## [2026-07-17] ops | Production release Sentry monitoring enforced

Created the `budgie-breeding-tracker` Flutter project in the production Sentry
organization, stored its DSN in GitHub/Codemagic, verified ingestion with one
synthetic production event, and added an `org:ci`-only token plus
`sentry_dart_plugin` so obfuscated release symbols upload before publishing.

## [2026-07-17] chore | Supabase local SMTP config deprecation removed

Renamed the local email-capture section from deprecated `[inbucket]` to
`[local_smtp]`, matching Supabase CLI's current template without changing ports
or behavior. A static config regression prevents the warning from returning.

## [2026-07-17] ci-fix | Hook Flutter environment and Edge deploy regression repaired

The pre-commit hook now removes repository-local Git variables only for Flutter
subprocesses, preventing the SDK version from degrading to `0.0.0-unknown` in a
hook. Hook installation is worktree-relative and executable-safe. The Edge
deploy dependency regression now asserts the path guard alongside analyze,
Flutter, and Edge tests; a real hook-environment test covers the failure mode.
