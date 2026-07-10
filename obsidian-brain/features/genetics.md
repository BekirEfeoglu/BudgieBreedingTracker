# Feature: genetics

**Purpose**: Select or enter parent genotypes, calculate expected offspring,
explain linkage/viability/inbreeding, and save or compare calculations.

## Shipped Screens

- `GeneticsCalculatorScreen` — parent selection, preview, results, save
- `GeneticsHistoryScreen` — saved calculations + stale indicators
- `GeneticsCompareScreen` — selected-history comparison and sharing
- `GeneticsReverseScreen` — target phenotype → parent suggestions
- `AiPredictionsScreen` — optional image/text AI analysis
- `GeneticsColorAuditScreen` — debug-gated phenotype color audit

Mutation reference details are presented by `mutation_detail_sheet.dart`; there
is no standalone mutation-guide screen.

## Key Provider Flow

```text
fatherGenotypeProvider + motherGenotypeProvider
  → offspringCalculationProvider (isolate, detailed result)
      → offspringResultsProvider
      → pruningDiagnosticsProvider
  → lethalAnalysisProvider / enrichedOffspringResultsProvider
```

Parent identity/provenance uses:

- `selectedFatherBirdProvider` / `selectedMotherBirdProvider`
- `fatherGenotypeSourceProvider` / `motherGenotypeSourceProvider`
- `ParentGenotypeSource {manual, fromBird, fromBirdEdited}`

History streams through `geneticsHistoryStreamProvider`; saved rows retain
`fatherBirdId`, `motherBirdId`, genotype maps, result JSON, and calculation
version.

## Current Engine Contract

- Calculation version: **v8**.
- Linkage rate/evidence/display metadata comes from one `LinkageCatalog`.
- Derived/estimated linkage values are labeled in the UI.
- Reverse results use a deterministic five-key comparator.
- Real pruning diagnostics—not mutation count—drive the coverage warning.
- Viability warnings currently cover DF Crest (sub-vital) and DF Feather
  Duster (lethal); removed healthy-pair warnings must not be reintroduced
  without approved evidence.
- 977 explicit domain `test()` declarations as of 2026-07-10.

See [[domain/genetics-engine]] for inheritance/version details.

## Bird Selection Round-Trip

Selecting a bird seeds the genotype and persists `{id,name}` identity. Manual
edits switch provenance to `fromBirdEdited`. Unknown mutation IDs are excluded
from the engine and surfaced as a localized scope warning. Reopening history
restores IDs when the birds still exist and uses a safe fallback label otherwise.

## Compare / Sharing

Comparison reads stored genotypes/results and can share a localized summary via
the platform share sheet. Failures use `AppLogger` and localized feedback.

## Local AI Boundary

`LocalAiService` can suggest sex/mutation with confidence. Low confidence is
shown as an estimate; all results require user review. The roadmap's direct
AI-photo → canonical calculator-genotype bridge is **not shipped**.

## Access

Genetics is premium-gated inline by effective premium access or the temporary
genetics rewarded-ad exemption. Genealogy's separate no-reward policy does not
apply here.

## Known Deferred Work

- Explicit linkage phase control (D4)
- Typed mutation evidence/confidence metadata (Q2)
- Combined breeding-form genetics advisory (I2)
- User-approved stale-history batch recompute (M1)
- Prediction-vs-actual, AI genotype bridge, and multi-generation planner

Canonical status is [[known-gaps]]; roadmap text alone does not imply shipping.

## Rules

- `.claude/rules/genetics.md`
- `.claude/rules/local-ai.md`
- `.claude/rules/premium-revenuecat.md`
- Phenotype colors remain a biological-accuracy exception to theme colors.

## See Also

- [[domain/genetics-engine]]
- [[domain/local-ai]]
- [[features/genealogy]]
- [[features/_features-index]]
- [[known-gaps]]
