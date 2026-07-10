# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-10] fix | Genetics engine audit — viability set aligned to MUTAVI (v6)

3-agent read-only audit of the genetics engine (inheritance math, mutation data,
epistasis+viability), each finding verified against the code + the corrected
MUTAVI guide. **Core math confirmed correct** (sex-linked genotype, AR/AID,
allelic series incl. sex-linked hemizygous females, ino masking). Fixes landed
(calculationVersion v5→v6, viability output changed):
- `df_crested` severity `lethal → subVital` — the app's own cited source
  (MUTAVI K10, "Crest: A Subvital Character") calls crest subvital, not lethal.
- Removed false-positive sub-vital warnings on healthy homozygous pairings:
  `df_spangle` (DF spangle is viable), `ino_x_ino` / `pallid_x_pallid` /
  `texas_clearbody_x_texas_clearbody` (standard, healthy — the guide never
  warned them; an old comment mis-attributed it).
- `epistasis_engine_modifiers` no longer lists Pearly/Pallid as "masked by Ino"
  — they are ino-locus alleles resolved by the allelic-series resolver (Pearly
  is dominant to ino; Pallid co-expresses), so masking them contradicted the
  phenotype name.
Non-versioned fixes: feather_duster description `(fd/fd)`→`(fdu/fdu)` (fd is
Faded's symbol); defensive comment on pallid's ino-locus rank. Extensive test
updates across 8 files to the new evidence-based behavior; 1016 genetics domain
+ 1018 feature + e2e green. Mutation catalog verified 39/39 vs the guide, all
inheritance types/loci/sex-linkage correct. Debatable items left for the domain
owner: AD "visual = homozygous" model (visual×normal→100% mutant vs guide 50/50
heterozygous default); ino not masking melanin-pattern names (Blackface etc.).

## [2026-07-10] feat | Genetics roadmap Q1 — pruning diagnostic + coverage warning

Multi-locus builds drop combinations below `probabilityPruningThreshold` then
normalize the survivors, which hides that mass was dropped (results read more
certain than they are). New `MendelianCalculator.calculateDetailed()` returns
`OffspringCalculation {results, PruningDiagnostics}` — wasPruned, prunedStateCount,
discardedProbabilityMassBeforeNormalization (raw 0..1), thresholds, normalized —
instrumented in `_crossAllLoci`'s early-pruning loop. `calculateFromGenotypes`
still returns the identical list (`_calculate(...).results`), byte-semantics
preserved (guarded by a test) → no calculationVersion bump. Provider chain:
`offspringCalculationProvider` (isolate) → `offspringResultsProvider` (derived) +
`pruningDiagnosticsProvider`; `PruningCoverageWarning` banner in the results step
fires on the real diagnostic (not a mutation-count heuristic) with the discarded
%. 8 new engine tests (5/6/7-locus boundaries deterministic: 6 loci ≈10.9% mass,
7 ≈50%). 2 l10n keys tr/en/de. Docs: genetics.md § Pruning Diagnostic +
[[domain/genetics-engine]]. All 2018 genetics tests + e2e green. Remaining
unblocked: T1 (property tests, depends on this). Gated: D2/D4/Q2/I2.

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


Older entries are archived in [[log-archive-2026-07-g]], [[log-archive-2026-07-f]], [[log-archive-2026-07-e]], [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
