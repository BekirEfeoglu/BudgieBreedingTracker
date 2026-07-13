# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-13] test-fix | Root-caused + fixed the order-dependent failures. Reproduced with seed `1053617534` (full suite `+11658 -5`; all 5 in ONE file, `admin_monitoring_content_test.dart`). Cause: 20 raw-key l10n assertion tests (`pumpLocalizedApp` → `TestAssetLoader`, keys) shared the file with ONE `pumpTranslatedWidget` test that loads REAL 'tr' translations; easy_localization caches translations in a process-static per-locale, so when the real-translation test ran first under a shuffle, the raw-key tests saw translated text and `find.text('<key>')` found 0. Fix: moved the single real-translation test to its own file `admin_monitoring_content_translated_test.dart` (separate isolate ⇒ no static leak); the raw-key file is now order-independent (`+20` pass across 5 seeds incl. the repro seed). No production change.

## [2026-07-13] ci-decision | Global `--test-randomize-ordering-seed random` NOT enabled in the `test` job. Validation run surfaced order-dependent failures (`+11658 -5` on one random seed; a fixed seed `20260713` re-run passed 100% clean → the flakes are seed-specific/intermittent, not universal). Enabling globally would cause intermittent CI reds, so held. The ~5 order-dependent tests (shared-state / container-reuse class per test-stability.md #2/#3/#9) are spawned as a separate investigation (reproduce-with-captured-seed → bisect → isolate state), after which random ordering can be safely enabled. The touched sync subsystem was verified order-independent on its own.

## [2026-07-13] test-fix | Closed the near-`now` flaky class: relocated `syncClockProvider` from `sync_pull_handler.dart` to the canonical `sync_providers.dart` (both handlers already import it), migrated ALL of `SyncOrchestrator`'s raw `DateTime.now()` uses (checkpoint stamp, force-full-sync cooldown/stamp, `_isReconcileDue` reconcile-due check) onto a `_now()` seam, and made `sync_time_persistence_test.dart` deterministic (`createContainer({clock})` + exact `isAtSameMomentAs(fixedNow)` instead of a `<5s` wall-clock margin). 167 sync tests green incl. `--test-randomize-ordering-seed random`; default clock unchanged (no behavior change). Defense-in-depth over the earlier isolated fix.

## [2026-07-13] test-fix | Deflaked SyncPullHandler clock-skew boundary tests. `sync_pull_handler.dart` compared `since.isAfter(DateTime.now())` where `now` was evaluated after the async gap, so a `DateTime.now().add(1ms)` `since` in the test went stale (past) before the check → intermittent `Expected: null, Actual: DateTime` (flaked a #155 CI run). Added an injectable `syncClockProvider` (default `DateTime.now`) read via `_now()`; replaced all 4 `DateTime.now()` uses (skew check + telemetry secondsAhead + 2 conflict-record stamps). Test `createContainer({clock})` overrides it; the 3 skew tests now build `since` off a fixed `DateTime.utc(2026,7,13,12)` → deterministic. 5× local reruns green, 167 sync tests pass. No behavior change (default clock). test-stability.md anti-pattern #8. Sibling-path sweep (sibling-path-hunter) found NO other active flaky clock-race tests — the fixed file was isolated; the one structural twin (`sync_time_persistence_test.dart:298`, SyncOrchestrator) had a safe 5s margin — later migrated onto the seam anyway to fully close the class (see follow-up entry). Added a test-stability.md § Triage #3 note establishing `syncClockProvider` as the canonical near-`now` boundary-test seam so the class isn't reintroduced.

## [2026-07-13] ci-deps | Dependabot branch-page cleanup. Fixed the sentry_flutter ignore (54aa8cb): `>=10.0.0-0` did NOT close #152 (Dependabot reads it as `>=10.0.0` stable; the alpha sorts below) → switched to `update-types: [version-update:semver-major]`, #152 auto-closed. Weekly PRs: #153 softprops/action-gh-release v2→v3.0.2 MERGED (db9d865, pure Node20→Node24 runtime, zero API change, SHA-pinned, release.yml-only). #154 firebase_messaging 16.4.2 CLOSED+ignored (b447c29) — upstream broken: references `FirebasePlugin`/`pluginConstants` removed by firebase_core 4.12.0, breaks build + all firebase-importing tests. #155 firebase_core 4.11→4.12 (green alone; Firebase iOS SDK unchanged 12.15.0, Podfile.lock synced). #147/#149/#150 already auto-closed by prior ignore rules. dev-docs/dependency-upgrade-notes.md updated with the sentry rule-sorting gotcha + firebase notes.

## [2026-07-13] ci-deps | supabase/setup-cli v1.6.0→v3.0.0 SHA-pinned (d8bd095) — de-risked by inspecting v3 action.yml (still accepts `version: latest`; job installs latest CLI regardless), landed via own commit not the tag PR #147; validated on the merge's main-only deploy-edge-functions run. Added Dependabot `ignore` rules (efaa059) for the held bumps: supabase_flutter >=2.13.0, drift/drift_dev >=2.34.0, sentry_flutter >=10.0.0-0 — stops #149/#150/#152 re-proposal. dev-docs/dependency-upgrade-notes.md updated. Bonus (5467ed8): removed the stale `npm`/`/promo-video` ecosystem block — that dir was deleted long ago but the entry still pointed at `/promo-video/package.json`, failing every Dependabot run with `dependency_file_not_found` (surfaced when the ignore-rules edit triggered a re-run). pub + github-actions ecosystems remain.

## [2026-07-13] ci-deps | actions/setup-java 4.8.0→5.5.0 merged (#146, 8e37f39) — SHA-pinned, Android Build validated v5.5.0 green on the PR. supabase/setup-cli v3.0.0 (#147) HELD: its only consumer `deploy-edge-functions` is main-only so PR CI skipped it (green = false comfort) + tag-pinned not SHA. Added `dev-docs/dependency-upgrade-notes.md` (cb002d1/9956f88) recording drift-2.34 hard-block preconditions, supabase_flutter/sentry holds, setup-cli hold, and the purchases_flutter landing pattern. Local Flutter `[user-branch]` = detached HEAD at exact 3.41.4 tag (not an SDK mismatch — no action).

## [2026-07-13] deps | purchases_flutter 10.3.0→10.4.1 (#148, f92fda6). 10.4.x exports its own SubscriptionInfo → ambiguous_import vs app's SubscriptionInfo; fixed with `hide SubscriptionInfo` on all purchases_flutter imports (5 lib + 13 test) + pod update PurchasesHybridCommon 18.15.1→18.19.0 (ios/Podfile.lock). Constraint ^10.2.3→^10.4.1 synced across CLAUDE.md, tech-stack, premium-revenuecat.md, premium-service.md. Held: drift 2.34.1 (analyzer 13 vs riverpod_generator/SDK conflict), supabase_flutter 2.16 (iOS cap), sentry alpha.

## [2026-07-13] chore | audit follow-ups: #8 now CI-enforced via new check_remote_hardcoded_columns checker (28 total, 10 extras; scans lib/data/remote/ for column literals in .order/.eq/.gte/.lte/.match + inline .update/.upsert/.insert keys; 7 unit tests, 99% cov). Removed @Tags(['gamification']) from 2 fast mock unit tests (+dropped unused dart_test.yaml tag) so they stay on the PR gate.

## [2026-07-13] audit | 6-lane comprehensive sweep (anti-pattern/PII/edge/migration/genetics/test-stability). Baseline clean; 6 small fixes: #8 residual col literals (8 new SupabaseConstants: level/xp_title/is_verified_breeder/is_pinned/event_date/sort_order/minutes_before/scheduled_at across 5 remote sources incl. updateProfileVerification sibling), backup_restorer wrong-password/corruption Sentry discrimination (+backup.error_decrypt_failed l10n), moderate-content text .max(10000) DoS cap, validate-free-tier-limit auth-before-parse, presence endSession double-log, streak reminder scheduler injectable clock (midnight-race). Migration prod-parity verified via MCP (5 recent applied). 11,663 tests green.

## [2026-07-12] refactor | All 12 edge functions extracted to DI handler.ts pattern + request-level Deno tests (401/400/403/503/200); +39 tests (204→243). Closes audit backlog. Byte-identical behavior, config.toml/verify_jwt untouched.

## [2026-07-12] refactor | SupabaseConstants #8 coverage — 26 new col/RPC constants, 44 literals replaced across 8 remote sources + admin providers (chore/supabase-constants-coverage). No wire-value change.

## [2026-07-12] feat | genetics explicit linkage phase (D4) shipped — LinkagePhase override, engine consult, isolate+history persistence (Drift v28), father-column UI, single-pair MVP

## [2026-07-12] feat | gamification streak system shipped (user_streaks + record_daily_checkin RPC, tiered XP + 7/30/100 badges, home chip + celebration + 20:00 reminder)

## [2026-07-12] docs | Post-task suggestions contract — exactly 3 items

Clarified the agent communication contract at user request: after completing a
real task (code change, audit, fix, research), replies must end with **exactly 3**
specific, task-relevant next-step suggestions. Updated `.claude/rules/chat.md`
§ Post-Coding Suggestions (single authority, was unquantified) and mirrored a
compact line into `AGENTS.md` § Communication (a59251c, f2641be). Prose only, no
count/inline-ref drift; `chat.md` has no wiki page (rules-index: response-style,
no page needed). [[sources/rules-index]]

## [2026-07-12] docs | wiki stat drift sweep — routes, tests, migrations count

Reconciled managed counts drifted from authoritative root `CLAUDE.md` §
Codebase Stats. **Routes 74→75** (index, overview, _features-index,
folder-structure, router-navigation). **Tests 11,506→11,515** (overview,
patterns/testing). **Migrations 206→207** in data-layer/migrations.md local
count; the 2026-07-10 MCP prod-parity snapshot stays at 206↔206, with
`20260710120000` marketplace-moderation trigger noted as applied to prod later
that day (both → 207, authority-preserving). No source/contract change; verified
no other count drift and that notification per-device-logout + marketplace
server-side-moderation contracts were already reflected. Lint green.

## [2026-07-12] notifications | inspection: FCM-logout doc reconcile + DND settings fixes

Notification-system inspection. (1) Docs: notifications.md, auth.md, and the
notification-service/auth-service wiki pages all claimed logout does
`unregisterAll()` / "delete all device tokens"; actual code
(`PushNotificationService.deactivateCurrentToken` →
`FcmTokenRemoteSource.deactivateToken`) deactivates ONLY the current device's
active token (and nulls `_currentUserId`) — per-device, not cross-device. Fixed
all 5 doc spots to the real (and correct: other logged-in devices keep push)
behavior. (2) Code: `_DndSection` read the rate limiter in initState, racing its
async `loadFromPrefs()` and freezing tiles on default hours over persisted
values — now watches `rateLimiterReadyProvider` and reads the limiter reactively;
`_DndTimeTile` gained a `Semantics(button)` combined label + 48dp minHeight
(a11y). 2 regression tests added. Investigated but NOT changed (not defects):
reschedule "cancel-before-add" is already handled at call sites
(breeding-form cancels previous species; egg-actions cancels all-species; reboot
starts clean); scheduled notifications bypassing client DND is by-design
(notifications.md: client DND = immediate only).

## [2026-07-12] ads | docs/app-ads.txt for AdMob authorized-sellers verification

Published `docs/app-ads.txt` (`google.com, pub-4121152941965334, DIRECT,
f08c47fec0942fa0`) at the marketing-site root so AdMob verifies the developer
domain and lifts "limited ad serving". Part of an external AdMob dashboard setup
session: linked both apps to their stores (Android→Google Play
`com.budgiebreeding.budgie_breeding_tracker`, iOS→App Store ID `6759828211`),
verified both via the now-live file (both "under review"), and confirmed all 6
production ad-unit IDs in `ad_service.dart` match the console. Publisher ID ==
`ca-app-pub-4121152941965334`. Wiki: [[infrastructure/marketing-site]]. Commit
d95e9bf.

## [2026-07-11] fix | About rate-app launch failure surfaces cannot_open_url

Reconciled `0f4fb09`. The Settings→About "Uygulamayı Puanla" (rate-app) tile
(`about_section.dart`) showed `errors.unknown` ("unexpected error") when the
store-page `launchUrl` failed — in both the `!launched` branch and the catch.
A failed store launch is a can't-open-link condition, not an unexpected crash, so
it now surfaces `errors.cannot_open_url` ("no suitable app found"), matching the
sibling launch paths (the More-tab About dialog `_showMoreAboutDialog` +
`about_section`'s support/contact tile, both already on that key). Message-precision
fix — no new l10n key, no contract/stat change; below rule granularity so
`.claude/rules/settings.md` untouched. [[features/settings]] § About.

## [2026-07-11] fix | About dialog surfaces silent launchUrl failures

`5d2f118` — the More-tab "Hakkında" dialog (`more_screen_sections.dart`
`_showMoreAboutDialog`) email + website links only handled thrown exceptions;
`launchUrl` can return `false` (no mail app / browser) without throwing, leaving
a tapped link a silent no-op. Now checks the bool return and shows
`errors.cannot_open_url`, matching the settings `AboutSection` pattern. Kept bare
`launchUrl` (no `canLaunchUrl`) — mailto false-negatives on Android 11+ without a
`<queries>` manifest entry. No stat/contract change.

## [2026-07-11] fix | Admin moderation deletes confirm-gated, Sentry on destructive ops, SupabaseConstants

Reconciled `7edf39d` (admin review fixes). **Contract change:** moderation
`deletePost`/`deleteComment` now show `showConfirmDialog(isDestructive: true)`
(`admin.moderation_delete_title`/`_confirm`) before removing content — the last
single-tap destructive admin path is now two-step-guarded like every other one.
Single-user destructive ops in `admin_user_manager` (`toggleUserActive`,
`grantPremium`, `revokePremium`, `forceLogout`) + the moderation action catch now
`Sentry.captureException(e, stackTrace: st)` on failure, parity with
`admin_bulk_manager` (was breadcrumb-only, anti-pattern #23). `admin_users`/
`admin_health`/`admin_dashboard` providers moved hardcoded column literals to
`SupabaseConstants` (+`colIsPremium`, +`colIsAcknowledged`); backup-error snackbar
stopped interpolating raw `e.toString()` (dropped the `{}` in `admin.backup_save_error`).
Managed counts via `verify_rules.py --fix`: Supabase constants 154→156, l10n keys
~3,124→~3,126 (both CLAUDE.md + inline rule refs). [[features/admin]] § Moderation
Queue / Force Logout / Current Decisions. Rotated the oldest 2026-07-10 10-lane
audit entry into [[log-archive-2026-07-h]].

## [2026-07-11] fix | Settings sync-table map uses SupabaseConstants + guarded share

Reconciled `5f9fbbf` (two settings-review fixes, no contract change).
`sync_detail_sheet._localizeTable` switched on raw `'birds'`/`'eggs'`/... table
string literals (anti-pattern #8) → now switches on `SupabaseConstants.*Table`
so a schema rename tracks the display mapping instead of silently falling
through to `sync.table_other`. `about_section`'s share-app tile fired
`SharePlus.share` fire-and-forget (only unguarded share/launch in the section)
→ now `await` + try/catch + `AppLogger.warning`, matching the store/support/
export paths. Docs only, no managed count changed.

## [2026-07-11] docs | Premium paywall Terms (EULA) label fully localized

Reconciled `ca22fed`. `premium_paywall_footer.dart` built its terms link label
as `'${'settings.terms'.tr()} (EULA)'` — concatenating a hardcoded `(EULA)` onto
translated text (anti-pattern #11). New `settings.terms_eula` key (tr/en/de)
rendered directly. Managed l10n count →3,124 (CLAUDE.md + localization.md via
`verify_rules.py --fix`); mirrored into overview.md. No contract change,
docs/managed values only.

## [2026-07-11] fix | Auth legal-links launchUrl failure now logged + surfaced

Reconciled `343b580`. The Terms/Privacy `TapGestureRecognizer`s in
`legal_links_text.dart` (auth screens) fired `launchUrl` fire-and-forget — a tap
that couldn't open the external URL failed silently. Extracted `_openUrl(url)`:
awaits `launchUrl`, logs failures via `AppLogger.warning`, and surfaces
`errors.cannot_open_url` in a SnackBar when the launch returns false / throws
(mirrors the premium paywall `_openLegalUrl` + `premium_screen`
`_openSubscriptionManagement` handling reconciled earlier this session).
Silent-failure → logged+feedback robustness only; no contract change.
[[features/auth]] unchanged — the page doesn't document the legal-links widget's
launch behavior. Docs/log only. Rotated the oldest 2026-07-10 v6 genetics-audit
entry into [[log-archive-2026-07-h]].

## [2026-07-11] docs | Local AI rule/wiki reconciled to fail-fast reality (no retry, no client rate limit)

Doc-only reconciliation — the `LocalAiService` code is authoritative for current
behavior and is correct; local-ai.md overstated two unshipped mechanics.
**§ Fallback Chain:** `local_ai_transport.dart` routes to exactly ONE backend
(`config.isOpenRouter ? OpenRouter : Ollama`) and throws a typed
`NetworkException`/`ValidationException` (`genetics.local_ai_error_*` l10n key) on
the FIRST failure — no retry-once, no 2s backoff, no cross-backend fallback, and
no `AnalysisResult.unavailable()` type (models are `LocalAi{Genetics,Sex,Mutation}Insight`,
surfaced via AsyncValue.guard → ErrorState). The helper-not-gate contract still
holds. **§ Cost & Size Guards:** there is no client-side rate limiter (only the
8-entry/10-min `LocalAiCache`; OpenRouter 429 is upstream) — consistent with the
rule's own Anti-Pattern #6. Registered both as future/unshipped in [[known-gaps]]
and mirrored the fixes into [[domain/local-ai]]. No lib/ change. Rotated the
oldest Q1 log entry into [[log-archive-2026-07-h]].

Older entries are archived in [[log-archive-2026-07-j]], [[log-archive-2026-07-i]], [[log-archive-2026-07-h]], [[log-archive-2026-07-g]], [[log-archive-2026-07-f]], [[log-archive-2026-07-e]], [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
