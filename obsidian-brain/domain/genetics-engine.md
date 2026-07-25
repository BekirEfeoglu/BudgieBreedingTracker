# Genetics Engine

**Location**: `lib/domain/services/genetics/`

**Current calculation version**: `v9`

**Contract**: `.claude/rules/genetics.md`

## Claim Authority

- Source/tests define current engine behavior.
- `docs/muhabbet-kusu-genetik-rehberi.md` and its approved sources support
  biological rates, loci, inheritance, and viability decisions.
- A code/guide conflict is investigated; current code is not scientific proof.
- Persisted output semantics are guarded by `calculationVersion` and
  `GeneticsHistory.isStale`.

## Capabilities

- **Punnett + multi-locus inheritance** — autosomal, sex-linked, allelic series,
  epistasis, compound naming, carrier/masked mutation output.
- **Z-linkage** — six pairs in gene order O—C—I—Slate. `LinkageCatalog` is the
  single pair→rate/evidence/display source used by engine and UI; derived and
  estimated values are labeled.
- **Reverse calculator** — every candidate is verified by the forward engine;
  deterministic comparator yields the same top 25 for the same input/version.
- **Inbreeding** — Wright F with disjoint-path rule, recursive memoized F_A,
  cycle guard, and honest `depthLimited` output.
- **Pruning diagnostic** — `calculateDetailed()` returns results plus discarded
  state/mass metadata; the legacy list API preserves result semantics.
- **MUTAVI regression matrix** — source-ID fixtures protect canonical guide
  crosses from silent engine drift.
- **Bird round-trip support** — history persists selected parent IDs and
  genotype provenance; unknown mutation IDs are excluded and surfaced.
- **Explicit linkage phase override (shipped 2026-07-12)** — `LinkagePhase
  {auto, coupling, repulsion}` on `ParentGenotype.phaseOverrides`;
  `_calculateGenericLinkedPair` consults it before falling back to implicit
  allele-state inference. `auto` output is byte-identical to prior behavior,
  so this did **not** bump `calculationVersion`. Persists in
  `GeneticsHistory.fatherPhaseOverrides` (Drift schema v28). Single-pair MVP —
  see § Known Unshipped Work.

## Current Viability Set

Only two evidence-backed combinations remain in
`lethal_combination_database.dart`:

- `df_crested` — `subVital`, offspring double-factor subset (MUTAVI K10)
- `df_feather_duster` — `lethal`, offspring double-factor subset (K15)

`df_spangle`, visual Ino/Pallid/TCB self-pair warnings were removed in v6;
`df_dominant_pied` was removed in v8. Structural `doubleFactorIds` still exist
for phenotype/genotype correctness even when no viability warning applies.

## Version History — Current Tail

- **v6**: viability audit; removed unsupported healthy-pair warnings, changed
  Crest lethal→sub-vital, corrected ino-locus masking semantics.
- **v7**: Ino masks Blackface/Saddleback/Mottled/Faded names and reports them in
  `maskedMutations`; Crest remains visible.
- **v8**: removed unsupported DF Dominant Pied semi-lethal warning.
- **v9** (2026-07-25): the multi-locus combiner stopped collapsing genotypically
  distinct states that share a post-masking compound phenotype name. The
  grouping key now carries the exact visual/masked identity alongside the v5
  double-factor set, and the merge branch unions `visualMutations` /
  `maskedMutations` instead of last-writer-wins. Probabilities and phenotype
  names were already correct — what changes is the reported visual/masked lists,
  and one merged group can now split into its distinct hidden-gene states. The
  single-locus path was unaffected. Test:
  `test/domain/services/genetics/multi_locus_masking_test.dart`.

Full v1–v9 history lives in `.claude/rules/genetics.md` and
`lib/core/constants/genetics_constants.dart`.

## Testing

- ~1,001 explicit `test()` declarations across 52 files under
  `test/domain/services/genetics/` as of 2026-07-25 (parameterized expansion
  excluded; count is inventory, not a quality target).
- Six linkage pairs cover coupling + repulsion with `closeTo` assertions.
- Viability changes require per-combination and real-engine DF tests.
- Output-semantic changes require version/stale assertions and regression tests.

## Known Unshipped Work

Multi-pair simultaneous phase override: when the father carries two
independent linked pairs heterozygous at once, only the tightest pair exposes
an `Otomatik | Coupling | Repulsion` control (residual D4 gap). Other open
roadmap items are tracked centrally in [[known-gaps]].

## See Also

- [[features/genetics]]
- [[domain/local-ai]]
- [[domain/services-index]]
- [[known-gaps]]
