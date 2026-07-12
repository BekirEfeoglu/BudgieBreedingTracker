# Change Log Archive — July 2026 H

Archived July 2026 entries rotated out of [[log]] during the 2026-07-11
marketing-site documentation sync (and the same-day birds/chicks/health-records
and auth legal-links syncs).

---

## [2026-07-10] feat+refactor | Marketplace pagination/search (chip #2) + #8 column constants (chip #3)

Closed the last two audit chips (delivered via parallel worktree agents; diffs
reviewed + all gates run in the main tree). **B — marketplace pagination +
server-side search:** the feed hard-capped at 20 and search/price/gender only
scanned those 20 (`MarketplaceRepository.search` was dead code → search found
nothing beyond page 1). `marketplaceFeedProvider` (AsyncNotifier.family) replaces
single-page `marketplaceListingsProvider`: `build()` loads page 1 or runs the
query via `repo.search` (cap 50); `loadMore()` appends the next before-cursor page
(no-op in search/while-loading/at-end/null-cursor; a failed load-more keeps the
page, never wipes it). Both surfaces (screen ListView + tab GridView) got a
`ScrollController` + loadMore-at-80% + a bottom spinner; `filteredMarketplaceListingsProvider`
unchanged. **C — #8 refactor:** replaced hardcoded Supabase column literals with
`SupabaseConstants` across 16 `lib/data/` files — value-match only (every
constant's value == the literal; table-specific `read`→`notificationColRead`;
`listing_id` left as-is, no constant exists). No behavior change.

## [2026-07-10] feat | Marketplace server-side listing moderation (chip #1)

Closed the audit's marketplace gap — listing text was client-moderated only
(a tampered/direct-REST insert bypassed it → immediately public). Added a
`BEFORE INSERT` trigger `trg_moderate_marketplace_listing` (migration
`20260710120000`, APPLIED TO PROD via MCP) mirroring moderate-content/moderation.ts
`moderateText` (denylist + caps/repeat/URL heuristics) over
title+description+species+mutation. Chose the trigger over the edge-fn+RLS-lockdown
"recommended" fix: locking down authenticated INSERT would break old binaries
still doing direct inserts — the trigger enforces for ALL clients, breaks none,
reversible (`DROP TRIGGER`). Verified live (scam blocked, clean allowed, tx rolled
back); security advisor clean. Client maps `MARKETPLACE_MODERATION_REJECTED` →
`ValidationException('marketplace.moderation_rejected')`.

## [2026-07-10] audit | Full-scope 10-lane sweep — 12 fixes across 6 features

10 parallel read-only auditors (6 specialized + 4 feature-tab lanes over all 24
tabs) from clean main; every fix shipped with tests. **more:** Statistics/Genetics
tiles ignored the rewarded-ad providers the router honors, so a user who watched a
reward ad was bounced back to the paywall (`navigateOrHint` now mirrors the gate).
**health_records:** chick-linked records showed no animal name (list+detail read
only `birdId`); reminder body used the record title not the bird's name; edit
populate skipped `setState`; the `List`-keyed filter families leaked (→ autoDispose).
**chicks:** `markAsWeaned`/`markAsDeceased` reported false success on a
concurrently-deleted chick → now surface not-found. **auth:** AAL2 read-failure
now fails closed for MFA-enrolled users; `completeAfterMfaChallenge` gained the
symmetric pre-cleanup AAL2 gate. **observability:** Sentry user scope set on
login / nulled on logout; offline timeout + `NetworkException` no longer captured.
**icons:** vaccination/medication/temp → `AppIcons`. EF1 (comment cross-post
`parent_id`) was a false positive — the DB trigger already rejects it; migration
ledger 205=prod. **Owner then decided the two gated items:** chick promotion now
enforces the free-tier bird limit (was a breed→promote paywall bypass); the
unsourced `df_dominant_pied` semi-lethal warning was removed (calculationVersion
7→8) — DF Australian Dominant Pied is viable, same class v6 dropped. Still
deferred (chips): marketplace moderation edge fn + pagination/search, #8
column-literal refactor.

## [2026-07-10] fix | Genetics deferred decisions — ino masks melanin patterns (v7); dominant model already OK

Handled the two items left for the domain owner after the v6 audit.
**E1 (chosen: mask clear melanin cases):** Ino now masks the melanin-based
pattern mutations Blackface/Saddleback/Mottled/Faded in the phenotype name
(`epistasis_engine_modifiers` step 15 guarded by `!hasIno`) and reports them via
maskedMutations. Crest stays unmasked (feather structure); Pied/Fallow/Clearbody
left unmasked (debatable). calculationVersion v6→v7 (name + maskedMutations
output changed). New resolution tests; version literal bumped.
**M1 (chosen: clarify UI labels) — already implemented:** verify-don't-trust
win. `AlleleStateBadge`/selection_summary already label AD+AID states as SF/DF
(dosage-based) with a DF/SF tooltip, AND `mutation_chip_widgets` already defaults
a newly-added dominant/incomplete-dominant mutation to `carrier` (= SF /
heterozygous), so `grey × normal → 50/50` matches the guide out of the box. The
`_getDominantAllelePair` visual=homozygous only applies when the user explicitly
picks the clearly-labelled DF. Only enhancement: the dosage tooltip now spells
out the breeding consequence (SF ~50% / DF 100%, default SF) in tr/en/de. No
engine/math change, no version bump for M1.

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
