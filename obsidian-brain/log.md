# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-14] fix | Community follow + DM were dead: RLS recursion & missing follow state

User report: "topluluk sekmesinde takip ve kişisel mesaj çalışmıyor". Three
root causes, all proven against prod before touching code.

**DM (hard failure, server).** `participants_insert`'s `WITH CHECK` contained an
unconditional raw `NOT EXISTS (SELECT … FROM conversation_participants …)`
(added by the 2026-07-02 block-hardening migration, which silently reverted
`20260402130000_fix_participants_rls_recursion.sql`). Reading the table from
inside its own policy → `42P17 infinite recursion` on EVERY participant insert.
DM never worked in prod (conversations/participants/messages = 0 rows).
Fix + applied to prod: `20260714181422_fix_conversation_participants_rls_recursion.sql`
routes the owner/admin and block checks through `private.is_conversation_manager`
/ `private.conversation_has_block_with` (SECURITY DEFINER). Verified end-to-end
as a real authenticated user (create → 2 participants → message → read cursor →
recipient reads); block rejection still fires (42501). Advisors: 0 new findings.

**Follow (client).** `fetch_community_feed` never returns `is_following_author`,
so `CommunityPost.isFollowingAuthor` was permanently `false` — the button never
showed the followed state and the "following" filter tab was always empty.
`_enrichPosts` now fetches `fetchFollowedUserIds` alongside the social-state RPC
(covers feed/detail/user-posts/tag/bookmark in one place). `FollowToggleNotifier`
now also invalidates `followedUsersProvider`, which the public-profile follow
button reads — without it that button ignored taps until pull-to-refresh.

Also: the community-tagged marketplace test still asserted the pre-2026-07-10
"messaging disabled" contract and had been red in the weekly suite; updated.
Rules updated: community.md (§ Follow + 2 anti-patterns), messaging.md (recursion
regression + anti-pattern #12).

## [2026-07-14] ci | Drift guard: +Dao/Mapper/Guard, bare-prose scan, allowlist audit

Third round of drift-guard hardening (measured before wiring, per the
suggestions). **Suffix expansion:** `--classes` now also checks
`*Dao`/`*Mapper`/`*Guard` (measured 8 tokens, 0 unresolved → zero-noise).
**Bare-prose scan:** class-suffix names are now checked outside backticks too
(fenced code blocks + inline-backtick spans stripped first) — closes the gap
that let the `ConnectivityService` sibling in data-flow.md slip past a
backtick-only scan (20 bare pairs measured, 0 unresolved). **Allowlist audit:**
new `--audit-allowlist` mode (periodic, NOT gated) flags allowlist entries no
longer cited by any doc; ran it and pruned 8 dead placeholders (`exampleProvider`,
`myAsyncProvider`, `someProvider`, `bar.dart`, `example.dart`, `foo.dart`,
`my_form.dart`, `my_screen.dart`). Both the `--target all --classes` gate and
the audit are clean. Test suite 23→31 (100% cov). Docs synced (CLAUDE.md
Quality Scripts, documentation-sync.md, wiki scripts.md).

## [2026-07-14] ci | Drift guard extended to wiki + class names; wiki symbol drift fixed

Executed the three follow-up suggestions. **#3 (obfuscation debunk):** `git grep`
found 135 `*Notifier` / 29 `*Service` / 492 `*Provider` readable names — the
subagent "source is minified" claim was an artifact; disregarded. **#1 + #2
(extend the checker):** `check_rule_symbol_drift.py` gained `--target
{rules,wiki,all}` (wiki scan excludes `log.md`/`log-archive-*` — chronological
history legitimately names removed symbols) and `--classes` (opt-in check of
`*Service`/`*Notifier`/`*Repository` — measured LOW noise: every finding was
genuine drift or documented-non-existence prose). Both surfaces + classes now
gated via `--target all --classes` in the `code-quality` CI job +
`run_local_quality_gate.sh`. **Wiki drift fixed (11):** breeding
`breedingPairListProvider`→`filteredBreedingPairsProvider` +
`activeIncubationsProvider`→`allIncubationsStreamProvider`; chicks
`chickListProvider`→`filteredChicksProvider`; eggs `eggs_mapper.dart`→`egg_mapper.dart`;
profile `currentUserProfileProvider`→`userProfileProvider`; home
`connectivityProvider`→`syncStatusProvider`; admin+more
`userRoleProvider`→`isAdminProvider`/`isFounderProvider`; data-io
`adsServiceProvider`→`adServiceProvider`; premium ×2
`freeTierUsageProvider`→`freeTierLimitServiceProvider`. **Class drift fixed:**
background-sync.md + data-flow.md `ConnectivityService`→`networkStatusProvider`
(the real `connectivity_plus` wrapper; no such class exists). Allowlisted the
documented-non-existence prose (premiumStatusProvider, genealogyTreeProvider,
MarketplaceListingRepository anti-pattern name, CalendarService,
IncubationReminderService). Test suite 18→23 (100% cov). Docs synced across
CLAUDE.md/ci-actions.md/documentation-sync.md/wiki.

## [2026-07-14] ci | Aspirational-contract guard shipped + full rule sweep (all 56 rules)

Followed up the 07-13 sweep with the remaining ~45 rules (6 parallel lanes, user-prioritized genetics/moderation/community first) AND automated the drift class. **Rule fixes (3 genuine):** community.md `CommunityCreateNotifier`→`CreatePostNotifier` (real class in `community_create_providers.dart`); admin.md § Realtime Updates rewrote — admin has ZERO realtime code (`lib/features/admin/` grep clean), moderation queue is `FutureProvider.autoDispose` + pull-to-refresh + post-action `ref.invalidate`, so the live-`admin_reports`-channel/toast/badge section was never-built → now § Queue Refresh (pull-based) + monitoring table row + anti-pattern #7 corrected + known-gaps row added; encryption.md anti-pattern `constantTimeBytesEquals`→`_constantTimeEquals`. auth.md `clearPresence` already fixed in 9756905 (agent read stale); genealogy `ancestorsProvider` location verified correct. 47 other rules verified clean symbol-by-symbol. **New CI gate:** `scripts/check_rule_symbol_drift.py` (+ 18-test suite, 100% cov) — for every `.claude/rules/*.md`, each `xProvider` token and `.dart` path must resolve in code; the two near-zero-false-positive shapes that caught the 07-13 drift (`conflictNotifierProvider`, etc.). Wired blocking into `code-quality` CI job + `run_local_quality_gate.sh`; allowlist escape hatch for prose that documents removed symbols. Documented across CLAUDE.md (Quality Scripts + Script Tests + CI table), ci-actions.md, documentation-sync.md § Verification, and wiki scripts.md/ci-cd.md. Known-gaps +1 (admin realtime queue). Task 3: the 07-13 known-gaps rows were all already marked unshipped in their owning rules — no inconsistency.

## [2026-07-13] docs | 4-lane doc-drift sweep: rules + wiki reconciled to code, skills-index added

Comprehensive `.claude` + `obsidian-brain` improvement pass (4 parallel read-only audit lanes, all findings code-verified before applying). **Aspirational-rules class (largest):** `presence.md` rewritten to reality — no `clearPresence`/`invisible`/`away`/visibility modes; boolean active/inactive sessions, `markInactive()→endSession()`, admin panel is the ONLY consumer (auth.md logout chain + presence-service/messaging wiki mirrors synced). `data-io.md` backup sections rewritten — single `.json`/`.enc.json` file (no zip/manifest/attachments), runtime `EncryptionService` key (no PBKDF2 → encrypted backups not portable), restore is merge-upsert (no wipe/preview). `forms-validation.md`: `ValidationException` has NO `fieldErrors` map; `PrimaryButton.isLoading`; no `intl_phone_field`; ring-unique check unshipped (birds.md sibling fixed). `home-widget.md`: real API is `syncDashboardSnapshot` + typed `AppHomeWidgetConstants` keys, system-locale widgets, no 00:01 refresh. `background-sync.md`/`domain/sync-service.md`: fictional `SyncService.syncAll/syncEntity/validateParents/conflictNotifierProvider` → real `SyncOrchestrator.fullSync/pushChanges/pullChanges`, `validateForeignKeys` (`Future<String?>`), `conflictHistoryProvider`, `SyncDisplayStatus`. **Wiki lag on shipped features:** settings.md auto-backup (shipped 2026-07-09), messaging.md read-receipt reciprocal opt-out, gamification-service trigger-derived level (no `_updateUserLevel`/`gamificationServiceProvider`), community `communityProfileProvider` removed. **Recency sync:** ci-cd + testing pages document random test ordering + order-dependency triage + `syncClockProvider` clock-seam; anti-patterns page: #7 statically checked, #8 partially CI-enforced (`check_remote_hardcoded_columns`); tech-stack versions (firebase_core ^4.12.0, image_picker ^1.2.3, build_runner ^2.15.1); migrations count 210; sync-strategy 13+photo repos; environment.md +`REVENUECAT_WEBHOOK_AUTH_TOKEN`; overview 3,146 l10n / 11,607+ tests; EmptyState `subtitle` (not `message`) + SkeletonLoader no-`count` fixed across rules+wiki; `performance.md` `forceFullSync()`. **New:** [[sources/skills-index]] (catalogs `.claude/skills`, registered in index/cheat-sheet/agents-index + documentation-sync.md row); known-gaps +7 rows (DM card producers latent, presence UI, PBKDF2 backup, restore preview, fieldErrors, ring-unique, chat-attachments) + orphan-photo GC deliberate absence; cheat-sheet +3 how-do-I rows +streak fire row. Rotated all 2026-07-11 entries into [[log-archive-2026-07-j]].

## [2026-07-13] test-fix | Root-caused + fixed the order-dependent failures. Reproduced with seed `1053617534` (full suite `+11658 -5`; all 5 in ONE file, `admin_monitoring_content_test.dart`). Cause: 20 raw-key l10n assertion tests (`pumpLocalizedApp` → `TestAssetLoader`, keys) shared the file with ONE `pumpTranslatedWidget` test that loads REAL 'tr' translations; easy_localization caches translations in a process-static per-locale, so when the real-translation test ran first under a shuffle, the raw-key tests saw translated text and `find.text('<key>')` found 0. Fix: moved the single real-translation test to its own file `admin_monitoring_content_translated_test.dart` (separate isolate ⇒ no static leak); the raw-key file is now order-independent (`+20` pass across 5 seeds incl. the repro seed). No production change.

## [2026-07-13] ci-hardening | Enabled `--test-randomize-ordering-seed random` in the `test` job. Validation first surfaced order-dependent failures (`+11658 -5` on a random seed; fixed seed `20260713` passed clean → seed-specific), all 5 root-caused to the admin-monitoring l10n leak (see fix entry) and isolated. After the fix, 4 full random-order passes (seeds 1661166742 / 2225109751 / 110335361 / 3601774480) all clean ⇒ suite order-independent. Enabled the flag + documented the "red = new order-dependency, not flakiness; reproduce with the logged seed" contract in ci-actions.md § Random Test Ordering.

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

Older entries are archived in [[log-archive-2026-07-j]], [[log-archive-2026-07-i]], [[log-archive-2026-07-h]], [[log-archive-2026-07-g]], [[log-archive-2026-07-f]], [[log-archive-2026-07-e]], [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
