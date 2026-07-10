# Genetics Engine

Source: `.claude/rules/genetics.md` (primary), `.claude/rules/local-ai.md` (AI integration), project memory

**Location**: `lib/domain/services/genetics/`

## Capabilities

- **Punnett square** — standard Mendelian inheritance calculation
- **Epistasis** — multi-locus gene interaction (e.g., opaline + clearwing)
- **MUTAVI rates** — authoritative mutation frequency data (see `docs/muhabbet-kusu-genetik-rehberi.md`)
- **Inbreeding coefficient** — Wright's F from pedigree (`inbreeding_calculator.dart`); enforces the disjoint-path rule (a father-line and mother-line path form a loop only if they share the apex and no other individual) so an ancestor reachable from both sides only through a nearer common ancestor isn't double-counted; F_A recursive + memoized (double-count bug fixed 2026-07-04)
- **Reverse calculator** — target phenotype → parent suggestions, each validated by the real forward engine. Deterministic ordering (`ReverseCalculationResult.compare`, 2026-07-10): maxProbability desc → probabilityAny desc → fewer parent states → fewer visual requirements → alphabetical signature; same input+version yields the same top 25 (used in both the final sort and `dedupeAndTrim` truncation). Results are not persisted → no version bump
- **Bird-selection round-trip** (2026-07-10, I1) — the calculator holds a `SelectedParentBird ({id,name})`, save fills `GeneticsHistory.fatherBirdId`/`motherBirdId`, reopen restores them; `ParentGenotypeSource {manual,fromBird,fromBirdEdited}` tracks provenance; `BirdGenotypeMapper.birdToGenotypeMapping` excludes unknown mutations from the engine and reports them for a UI scope warning. No migration (model/table already had the ID fields)
- **MUTAVI reference regression matrix** (`mutavi_reference_regression_test.dart`, 2026-07-10) — canonical guide crosses pinned with `guideSection` + `sourceIds` so engine drift that contradicts `docs/muhabbet-kusu-genetik-rehberi.md` fails loudly
- **Pruning diagnostic** (2026-07-10, Q1) — multi-locus builds drop combinations below `probabilityPruningThreshold` then normalize, hiding the dropped mass. `calculateDetailed()` returns `OffspringCalculation {results, PruningDiagnostics}` (wasPruned/prunedStateCount/discardedProbabilityMassBeforeNormalization/thresholds/normalized); `calculateFromGenotypes` still returns the identical list (byte-semantics preserved → no version bump). `pruningDiagnosticsProvider` drives a `PruningCoverageWarning` banner based on the real diagnostic, not a mutation-count guess
- **Dominant allelic series** — bug fixed 2026-04-09 (v2 calculation)
- **Z-linkage** — 6 sex-linked pairs (gene order O—C—I—Slate). Single source of truth: `linkage_catalog.dart` (`LinkageCatalog`) holds each pair's recombination rate, display cM (`rate*100`) and `measured|derived|estimated` evidence; both the engine (`tryLinkPair`→`recombinationRateFor`) and UI (`z_linked_badge`, `mutation_detail_sheet`→`linkagesFor`/`lookup`) read from it. Ino-locus alleles (ino/pallid/pearly/texas_clearbody) normalize to one `ino` token. Removed the drifted widget-local cM tables (Op-Cin 34→32, Op-Slate 40→40.5) 2026-07-10 — no calc change (rates unchanged), UI-only drift fix
- 930+ genetics-specific domain tests

## `calculationVersion`

Every result stores the algorithm version. When the engine is updated, old results can be flagged stale.

- Current version: `v6` (2026-07-10: viability audit aligned the lethal/sub-vital set with the cited MUTAVI sources — `df_crested` downgraded lethal→sub-vital per MUTAVI K10, and the false-positive warnings on healthy homozygous pairings `df_spangle`/`ino_x_ino`/`pallid_x_pallid`/`texas_clearbody_x_texas_clearbody` were removed; Pearly/Pallid no longer listed as masked-by-Ino since they are ino-locus alleles resolved by the allelic-series resolver. v5 kept the DF subset distinct in multi-locus crosses)

## Confidence Thresholds (AI-assisted)

When `LocalAiService` provides a genetics suggestion:
- Confidence < 0.7 → show as "tahmin" (estimate), no auto-save
- Confidence ≥ 0.7 → show as suggestion, user must accept

## Phenotype Colors

Genetic phenotype colors are **exempt** from the hardcoded color anti-pattern — biological accuracy requires fixed colors. See [[patterns/anti-patterns]] rule #19.

## Reference

- `docs/muhabbet-kusu-genetik-rehberi.md` — MUTAVI-sourced guide, authoritative for mutation data
- `.claude/rules/genetics.md` — Punnett, sex-linked linkage (Z chromosome gene order O—C—I—Slate), lethal combos, inbreeding, reverse calculator, epistasis, anti-patterns
- `.claude/rules/local-ai.md` — AI confidence integration

## See Also

- [[features/genetics]]
- [[domain/local-ai]]
- [[domain/services-index]]
