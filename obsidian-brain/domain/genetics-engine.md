# Genetics Engine

**Location**: `lib/domain/services/genetics/`

**Current calculation version**: `v8`

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

Full v1–v8 history lives in `.claude/rules/genetics.md` and
`lib/core/constants/genetics_constants.dart`.

## Testing

- 977 explicit `test()` declarations under `test/domain/services/genetics/` as
  of 2026-07-10 (parameterized expansion excluded; count is inventory, not a
  quality target).
- Six linkage pairs cover coupling + repulsion with `closeTo` assertions.
- Viability changes require per-combination and real-engine DF tests.
- Output-semantic changes require version/stale assertions and regression tests.

## Known Unshipped Work

Explicit `Otomatik | Coupling | Repulsion` phase selection is not implemented;
phase is still inferred from allele states. Other open roadmap items are tracked
centrally in [[known-gaps]].

## See Also

- [[features/genetics]]
- [[domain/local-ai]]
- [[domain/services-index]]
- [[known-gaps]]
