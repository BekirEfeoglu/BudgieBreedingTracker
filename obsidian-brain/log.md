# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-10] feat | Genetics roadmap D3 + Q3 + I1 (unblocked Phase A/B items)

Continued `dev-docs/genetics-improvement-roadmap.md` after D1.
**D3** — `mutavi_reference_regression_test.dart`: guide-traceable regression
matrix (Blue×Blue/split, Cinnamon/Ino×normal female, Greywing×Clearwing/Dilute,
Cinnamon+Ino→Lacewing), each fixture carrying `guideSection` + `sourceIds`
(K1–K14), asserting the guide's ratios. Documented that AR split×split collapses
to phenotype 25% visible / 75% normal-carrier (guide's genotype 25/50/25).
Test-only, no drift found → no version bump.
**Q3** — `ReverseCalculationResult.compare`: deterministic 5-key tie-break
(maxProbability → probabilityAny → fewer states → fewer visuals → alphabetical
signature), used in the final sort AND `dedupeAndTrim` truncation so the top-25
is reproducible. Reverse results aren't persisted → no version bump.
**I1** — bird-selection round-trip: `SelectedParentBird ({id,name})` replaces the
name-only providers; save fills `GeneticsHistory.fatherBirdId`/`motherBirdId`;
reopen restores identity; `ParentGenotypeSource {manual,fromBird,fromBirdEdited}`
provenance badge; `BirdGenotypeMapper.birdToGenotypeMapping` excludes+reports
unknown mutations (UI scope warning). No migration (fields already existed).
4 new l10n keys (tr/en/de). Docs: `.claude/rules/genetics.md` (Reverse,
new Bird Selection Round-Trip, MUTAVI matrix) + [[domain/genetics-engine]].
All 2005 genetics domain+feature tests + e2e green; gated items (D2/D4/Q2/I2)
left for domain-owner/architecture decisions.

## [2026-07-10] feat | Genetics roadmap D1 — typed linkage catalog + UI drift fix

Executed D1 of `dev-docs/genetics-improvement-roadmap.md`. New
`lib/domain/services/genetics/linkage_catalog.dart` (`LinkageCatalog`) is the
single source for the 6 Z-linkage pairs: recombination rate (from
`GeneticsConstants`), display cM (`rate*100`), and `measured|derived|estimated`
evidence + source note. Engine (`mendelian_calculator` `tryLinkPair` →
`recombinationRateFor`) and both UI surfaces (`z_linked_badge`,
`mutation_detail_sheet` → `lookup`/`linkagesFor`) now read from it. Deleted the
drifted widget-local tables — `mutation_linkage_data.dart` and the badge's
`_linkageRates` showed Op-Cin `34`/Op-Slate `40` while the engine used
`0.32`/`0.405`; catalog closes the drift by construction (Op-Cin 32, Op-Slate
40.5). Ino-locus alleles normalize to one `ino` token. Derived/estimated rates
carry an evidence label in the badge popup (`genetics.linkage_derived`/
`linkage_estimated`, tr/en/de); unified the detail-sheet rate framing to cM.
No `calculationVersion` bump (rates unchanged — UI drift + pure refactor).
Updated `.claude/rules/genetics.md` § Sex-Linked Linkage and
[[domain/genetics-engine]]. 15 new catalog tests; 1981 genetics tests green.

## [2026-07-10] docs | Testing wiki caught up with the tag→CI-gate rule

[[patterns/testing]] now mirrors the "Test Tags → CI Gates" table added to
`.claude/rules/testing.md` (community tag reserved for heavy screen/widget
suites; mock-based unit tests stay untagged on the PR gate; new tag-based
exclusions fall under the skip policy) and its stale stats were refreshed
(914/11,436 → 917/11,488).

## [2026-07-09] rules | Session lessons folded into the rulebook

ci-actions/release-ops/CLAUDE.md: Xcode Cloud post-clone installs Flutter via
curl+unzip (git clone = known-flaky, flutter/flutter#163198 — the TRUE root of
the recurring Build - iOS fail; first curl build passed in ~9 min), drift_dev
"Circular error" is a non-fatal WARNING (simolus3/drift#3227), `>>> STEP N:`
markers + superseded-build guidance. data-layer.md: never close a
`.references()` cycle (customConstraint pattern). migrations.md: drift-guard
script + ledger `statements` content-drift procedure + forward-reconcile rule.
testing.md: tag→CI-gate table (community tag = weekly job; unit tests untagged).
Wiki ci-cd.md Xcode Cloud section rewritten to match.

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

Older entries are archived in [[log-archive-2026-07-g]], [[log-archive-2026-07-f]], [[log-archive-2026-07-e]], [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
