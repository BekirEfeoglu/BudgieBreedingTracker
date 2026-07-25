# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-25] release-ops | First real release build corrected the iOS artifact path

Ran `scripts/build_release.sh ios` end to end with a real Sentry token. Symbol
upload works: 127 debug files + the Dart obfuscation map uploaded, release
`com.budgiebreeding.tracker@1.1.7+56` created and finalized. But the build stops
at `build/ios/archive/Runner.xcarchive` — `flutter build ipa` cannot export an
IPA without an export-options plist, which Codemagic used to generate via
`xcode-project use-profiles` and nothing replaces locally. The script (and
release-ops.md, ci-cd.md, the store-release skill, CLAUDE.md § Release Builds)
claimed `build/ios/ipa/*.ipa`, a path that does not exist in this setup; the
script now reports whichever artifact was actually produced and fails if neither
is there. Found only by running it — every static check passed while the guidance
was wrong. CLAUDE.md was missed in the first pass and corrected in a follow-up:
release/deploy changes must land the owning rule AND CLAUDE.md together
(documentation-sync.md).

## [2026-07-25] security | TLS pin rotation lead time is now a CI gate

`security.md` required replacement fingerprints ≥14 days before expiry, but
nothing enforced it — a lapsed pin set leaves the app unable to reach the
backend at all, fixable only by a store release. `check_certificate_pin_freshness`
reads the earliest `valid <start> through <end>` comment above the pins and
fails `security-audit` inside that window (harsher message once expired);
39 → 40 controls. Writing the tests exposed a bug in the check itself: those
comments wrap, so the RSA leaf's date sits behind a `//` on the next line and
the first regex skipped it — both pins share an expiry, so the output looked
right while only one was read. Comment markers are now stripped before
whitespace is collapsed. Also audited GitHub secrets after the Codemagic
removal: all 12 are still referenced by workflows, nothing orphaned (the Play
credential lived in Codemagic's own env group, never on GitHub).

## [2026-07-25] release-ops | Codemagic removed; docs moved to script + artifact-only releases

Docs-only. `codemagic.yaml` was deleted (user decision), so all three workflows
it described (`android-release` → Play alpha, `android-verify-only`,
`ios-release` → TestFlight) are gone and **no hosted release pipeline remains** —
nothing publishes to a store automatically. Rewrote the release surface across
13 files: iOS is now `scripts/build_release.sh ios` + manual Organizer/`altool`
distribution; Android is `release-ready.yml` (artifact-only) with
`scripts/build_release.sh android` as the local equivalent. Documented the new
script's contract (fail-fast on `SENTRY_DSN` in `.env` / exported
`SENTRY_AUTH_TOKEN`, obfuscation + `sentry_dart_plugin` symbol upload with a
per-platform `SENTRY_RELEASE` matching `PackageInfo`) and the hazard it exists
for: `ios/Flutter/DartDefines.xcconfig` is gitignored and only a `flutter build`
rewrites it, so a raw Xcode Archive can ship a stale config — a found copy had
the legacy Google web client ID and **no** `SENTRY_DSN`. Called out that Play
version codes are package-global and are no longer resolved automatically
(now a manual pre-release check). Preserved the Flutter `3.41.4` pin rationale
(2026-07-18 `stable` drift to 3.44.6 broke locked `lucide_icons`) where it still
applies, on `release-ready.yml` + Xcode Cloud. Security controls 37→39.
known-gaps: artifact-only publishing recorded as a deliberate absence. Rotated
ten 07-17/07-18 entries into [[log-archive-2026-07-m]].

## [2026-07-25] audit-followup2 | Founder demotion-to-NULL failed open

Verifying the founder promotion fix end-to-end (rollback-wrapped simulation on
prod) surfaced a second, worse bug in the same trigger: demoting a privileged
user by setting `profiles.role = NULL` did NOT revoke their `admin_users` row.
`NEW.role NOT IN ('admin','founder')` is NULL — not TRUE — when NEW.role is
NULL, and NULL is the ordinary-member role here (162 of 164 profiles), so this
is the normal demotion path, not an edge case. The pre-existing
`NEW.role <> 'admin'` had the same hole, meaning revocation this way never
worked. Unlike 20260725043351 (failed closed) this fails OPEN. Fixed with
COALESCE in migration `20260725060242`; all four transitions re-verified by
simulation; zero stranded rows needed backfill. Also updated the GitHub
`GOOGLE_*_CLIENT_ID` secrets to the new OAuth project and closed issues
#25/#28/#29 as already-fixed.

## [2026-07-25] audit-followup | Closed the audit's deferred items

Second batch after the aspirational-contract sweep. Founder role never synced
into `admin_users` (promotion also DELETED an existing admin row) — both
trigger functions now mirror the role; migration `20260725043351` applied to
prod and repaired one live stranded account. Sync PUSH path gained
`reportPushFailure` (it had no counterpart to `reportPullFailure`, so
corruption-class failures looped silently); mfa-lockout, conflict
snapshot/restore and the AAL2 inner catch now reach Sentry with payload-free
synthetic exceptions. Weekly `E2E and Community Test` had been red since
2026-07-13: the 800x600 test surface is shorter than the register form, so its
submit button laid out off-viewport and `tap()` hit the scrollable — fixed with
a portrait surface. Edge handler tests 257→267 (send-push authorization,
Apple/502 revoke branches, scan-image-safety 413 remap), each verified
non-vacuous by mutation. Retired the expired Supabase leaf pin after
confirming both live leaves match. Genetics `depthLimited` now propagates
through nested F_A. Migration count 217→218.

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
