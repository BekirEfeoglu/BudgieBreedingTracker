# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-09] fix | Drift clutches↔incubations module cycle crashed drift_dev codegen

Root-caused the intermittent Xcode Cloud post-clone failure (Build - iOS
action_required, `build_runner` exit 1 ~33s, survived 8 retries): a bidirectional
typed FK (clutches.incubationId ⇄ incubations.clutchId, both `.references()`)
formed a reference cycle that drift_dev 2.31 crashes on ("Circular error when
deserializing drift modules"), build-order dependent so it hit some CI runners
only. Retries can't clear it. Fixed by declaring incubations.clutchId's FK with a
raw `.customConstraint('NULL REFERENCES clutches (id)')` (+ dropping the
clutches_table import) — breaks the module edge, preserves the SQL FK 1:1, no
schema change. 763 db/incubation/egg tests pass. See [[data-layer/drift]] §
Circular FK References.

## [2026-07-09] ci | Audit follow-ups: migration drift guard + codegen-flake hardening

Post-audit "apply all suggestions" round. Added `scripts/verify_migration_drift.py`
(offline dup-version/malformed-name structural guard wired into the code-quality
job; opt-in `--online` prod-ledger parity; 27 tests, 100% cov). Added coupling-
phase linkage tests for the 3 previously repulsion-only Z-pairs (all 6 now assert
both phases). Bumped the drift_dev "Circular error" codegen retry cap 3→5 in
ci.yml, then found the Xcode Cloud `Build - iOS` post-clone ran build_runner BARE
(the only unprotected codegen step) — action_required at ~47s — and wrapped it in
the same clean-and-retry loop. See [[infrastructure/ci-cd]], [[infrastructure/scripts]].

## [2026-07-09] fix | Migration content-drift reconciliation (repo ↔ prod ledger)

Deep migration check via Supabase MCP: version parity prod=local, but the
ledger's `statements` column revealed 4 files diverging from applied SQL.
Gamification `::integer` (cosmetic) reconciled in-place; admin_get_table_counts
+ cleanup fns benign (later drift-free migration redefines them). Real one:
`20260430130000` system_settings SELECT policy used `public.is_admin()` while
prod ran `private.is_admin()` (different bodies → behavioral). Fixed forward via
`20260709180636`, applied to prod as an idempotent no-op; repo+prod now 205 in
lockstep. Old files left un-edited (no history rewrite). See [[data-layer/migrations]].

## [2026-07-09] audit | Full-scope sweep: genetics + calendar test hardening

Multi-agent sweep from clean main (all gates green). Only fixes: feather_duster
+ df_spangle multi-locus DF regression guards (v5 claimed 4 combos, 2 untested)
and a calendar midnight-rollover flake. Community-tag PR-gate gap flagged to user.

## [2026-07-09] fix | Genetics: DF lethal warnings dropped in multi-locus crosses (v5)

Followed up the audit's deferred genetics FINDING 1. Traced end-to-end: EVERY
offspringHomozygous lethal (crested, DF spangle, feather duster, DF dominant
pied) — not just dominant_pied — had its warning silently dropped in any
multi-locus cross. Root cause was NOT the guardian's `(homozygous)`-match
one-liner (which failed its own regression test) but the combiner grouping:
`_resolveEpistasisForCombined` keyed results by the epistasis compound name
(identical for homo/heterozygous dominant), so DF and SF merged and the
`doubleFactorIds` tag was overwritten. Fix keeps the DF subset a distinct
`(double factor)` result keyed by its exact DF set (so different homozygous
loci don't cross-pollute tags and over-attribute a lethal). Verified via
diagnostic: warnings fire + affected probability is the true ~25% subset for
both dominant_pied and crested + a second locus. calculationVersion 4→5;
regression tests for both. Also folded in 2 LOW cleanups: removed dead
`LethalScope.parentAnyVisual` + checker, reconciled the crested "sub-vital"
comment vs its LethalSeverity.lethal classification. Commits 1f2ffa3, 4de2eca.

## [2026-07-09] fix | Comprehensive audit sweep (6 agents + Supabase DB checks)

Full-scope audit (Supabase now connected). DB-side: security advisors clean;
the only perf-advisor WARNs (3× `auth_rls_initplan`) were my new
`mfa_recovery_codes` policies calling `auth.uid()` bare — rewrapped as
`(select auth.uid())` (migration `20260709130517`, advisor 3→0). Migration
deployment-drift found + repaired: 2 local files (`add_health_record_chick_fk`,
`add_message_photos_storage_bucket`) had version prefixes not matching the prod
ledger (prior MCP-apply timestamps) — `git mv`'d to `20260709103045`/`103112`,
local↔prod 204↔204. Code fixes: recovery-code writes `.insert()`→`.upsert()` +
client v7 ids + SupabaseConstants (MFA-critical idempotency, `colCodeHash`/
`colUsedAt` added); PII obfuscation of user UUIDs in messaging + gamification
logs; corrected a fail-open→fail-CLOSED doc comment on `scanImageSafety`;
replaced brittle `.at(N)` privacy-test finders with text finders. Edge-fn
lane: 12/12 clean (Deno 204/0), only test-completeness gaps (deferred).
Genetics lane found a real bug — `df_dominant_pied` semi-lethal warning
dropped in multi-locus crosses — but the one-line fix failed its own
regression test, so it was reverted and deferred to a dedicated task (needs a
proper multi-locus DF-path trace + calculationVersion 4→5 bump). 113 unused_index
INFOs left untouched (trigram/FK-covering/low-traffic — don't-drop lesson).

## [2026-07-09] feat | Close 7 gaps (gamification brick, DM retry, MFA recovery, feedback limit, auto-backup, read receipts, calendar reminders)

Seven-item sweep, each its own commit + prod migration where needed (applied
Supabase-first via MCP, advisors clean): **(1)** gamification `total_xp` drift
brick fixed with an AFTER INSERT trigger deriving `user_levels` from
`SUM(xp_transactions)` (`20260709113822`, backfill heals drift). **(2)** DM
photo: cooldown pre-check + retry replays the uploaded image, not text.
**(3)** MFA recovery codes — `mfa_recovery_codes` (SHA-256, own-scope RLS) +
`redeem_mfa_recovery_code` RPC (private DEFINER deletes `auth.mfa_factors`,
public INVOKER wrapper; `20260709115154`/`115445`). **(4)** feedback rate limit
BEFORE INSERT trigger, 5/user/hour (`20260709120555`). **(5)** wired the
orphaned `BackupScheduler`/`BackupService` + premium frequency picker + resume
trigger. **(6)** reciprocal `readReceiptsEnabledProvider` (skips write + caps
bubble). **(7)** calendar reminder editing via `updateEvent(reconcileReminder)`.
Removed 5 known-gaps rows; tr/en/de keys + owner rules updated per item.

## [2026-07-09] fix | Audit sweep — gamification profile sync, rank icons, post photo cap

Parallel-agent audit of the post-`f435373` diff (community redesign, 10-tier
rank ladder, comment replies, mutes, admin atomic RPCs). Fixed and pushed:
**(1)** `GamificationRemoteSource.updateProfileVerification`/`updateProfileLevelInfo`
filtered `profiles.eq('user_id')`, but `profiles` is keyed by `id` and has no
`user_id` column — every level-up/verified sync 400'd silently since 2026-04-02,
freezing `profiles.level`/`xp_title` and blocking the verified tick. Now `.eq('id')`.
**(2)** `AppIcons.getLevelIcon` never updated for the 10-tier expansion —
non-monotonic (enthusiast→gold, champion→platinum below legendary); remapped to a
strict 5-icon ascending ladder. **(3)** `create-community-post` Zod `image_urls`
cap was 6 vs the premium max of 10 — premium 7–10-photo posts uploaded then 400'd;
raised to 10. Also fixed `check_bare_catch` false positives (recognize
`reportPullFailure` + widen lookahead to 8 lines). Deferred (needs server RPC):
`total_xp` computed incrementally vs the RLS `SUM()` WITH CHECK — one dropped
request between insert and level-upsert permanently bricks a user's leveling.
Updated gamification-service.md + edge-functions.md. Commits da3c02d, 600c3c2, e808dff.

## [2026-07-09] fix | Pull-failure Sentry reporting across syncable repos

A PII/observability agent sweep found every syncable repository's `pull()`
swallowed unexpected errors (serialization, Drift corruption, malformed payload)
with only `AppLogger.error` — a breadcrumb, not a Sentry issue — and since the
repo swallows it, the central `SyncPullHandler` never sees it. Added top-level
`reportPullFailure()` in `base_repository.dart` (mirrors `detectPullConflicts`
so non-mixin Photo/Profile repos share it): logs then `Sentry.captureException`
with a `sync_phase: pull` tag, filtering `AppException` so ProfileRepository's
swallowed offline failures stay out of Sentry. Applied to all 15 `pull()` sites;
removed now-unused logger imports (commit 5b73ef2). Also 4090d64: bracket-prefix
form-notifier log tags (observability.md convention). A third suggestion
(skip NetworkException in `SentryErrorFilter`) was rejected — an explicit test
asserts NetworkException IS reported, a deliberate decision. Updated
data-layer/repositories.md § SyncableRepository.

## [2026-07-08] fix | Migration deployment drift repaired (prod)

Comprehensive app audit found 3 migrations shipped in client code but never
applied to prod: `add_bird_tags_to_posts` (community_posts bird_id/bird_name/
mutation_tags columns), `fetch_community_feed_sort` (p_sort_by RPC param), and
`admin_atomic_audit_rpcs` (21 admin audit RPCs). Post detail/user-posts were
400'ing (client `_feedColumns` selected non-existent columns) and admin
user-management RPCs were missing. Applied all 3 to prod via MCP (deps verified
first), added the `community_mutes` FK covering index (perf advisor 0001), then
reconciled the ledger: `git mv`'d 8 local files onto their production ledger
versions (6 timestamp-twins from prior MCP applies + the 2 newly-applied) and
inserted the admin migration's ledger row → 197 local ↔ 197 ledger, zero drift,
`db push` now a clean no-op. Security advisors: no new findings (admin RPCs
correctly private SECURITY DEFINER + public INVOKER wrappers, anon revoked).
Docs synced: comment replies (one-level) and bird-link/mutation tags are now
SHIPPED (removed from known-gaps); community rule + wiki + migrations page
updated with the "deploy is manual, verify after merge" lesson.

## [2026-07-08] rules | Rulebook audit: auth.md + birds.md added, stale values fixed

`.claude/rules/` audit (54 files): all structurally complete, but two core
modules had no owning rule — added `auth.md` (router guard integration, MFA
challenge, AAL2 destructive-action pattern, cooldown persist, logout chain)
and `birds.md` (status lifecycle side effects via BirdLifecycleService,
BirdsDao field encryption, photo partial-failure contract, cage ledger MVP,
free tier 15). Three-place registration done (CLAUDE.md § Rules table,
rules-index, this log); features/auth, features/birds, domain/auth-service
now cite the owning rules. Stale rule content fixed: migrations.md garbled
intro + 174→196 count, premium-revenuecat purchases_flutter ^10.0.2→^10.2.3,
testing.md CI timeout 25→30/40, icon count 93→99 (assets-images,
coding-standards), and security.md § MFA UX Flow no longer presents recovery
codes as shipped (2026-07-02 audit: they don't exist — also added to
known-gaps).

## [2026-07-08] docs | Brain expansion: router page, known-gaps registry, drift fixes

Added [[architecture/router-navigation]] (GoRouter redirect chain, guard order,
RouterNotifier, deep-link UUID/editId validation — router was the last major
subsystem without a page) and [[known-gaps]] (central registry of latent code
surfaces, unshipped design goals, and deliberate absences, sourced from the
rule files). Registered both in index/README; overview gained a "Design Goal ≠
Shipped" decision pointing at known-gaps. Drift fixed: 73→74 routes
(_features-index), 194→196 migrations (migrations, supabase), supabase_flutter
constraint now shows the `<2.13.0` iOS CI cap, storage-bucket table corrected
to the real 8 `SupabaseConstants` buckets (no `health-records`/`chat-attachments`
buckets; marketplace bucket is `photos`), folder-structure router listing gained
founder_guard/redirect_guards/route_utils/router_notifier, cheat-sheet edge-fn
table completed to all 12 (JWT note now carries the `revenuecat-webhook`
shared-secret exception) plus new task rows, stale "two local untracked
migrations" bullet removed. Second sweep: 913/12,059 test stats → 914/11,436+
(testing, overview — now mirrors CLAUDE.md § Codebase Stats), 3,050 → 3,068
l10n keys (l10n, folder-structure).

## [2026-07-08] docs | Obsidian brain inventory synced

Fixed wiki drift found during the `obsidian-brain` audit: codebase stats now
reflect schema v26, 913 test files / 12,059 passing tests, 3,050 l10n keys per
language, 194 tracked Supabase migrations, 28 remote-source files, and current
Supabase constant counts. Also corrected stale schema v25 references, the old
notification-service path, and duplicated migration-count values across the
overview, index, data-layer, architecture, testing, and l10n pages.

Older entries are archived in [[log-archive-2026-07-f]], [[log-archive-2026-07-e]], [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
