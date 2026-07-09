# Feature: genetics

**Purpose**: Budgerigar genetics calculator — Punnett square, mutation rates, inbreeding coefficient.

## Key Screens

- Genetics calculator (select parent birds → view offspring probabilities)
- Mutation reference guide
- Genetics result detail

## Key Providers

- `geneticsCalculatorProvider` — NotifierProvider (calculator state)
- `geneticsResultProvider` — computed offspring distribution

## Genetics Engine (`lib/domain/services/genetics/`)

- Punnett square calculation
- Epistasis handling (multiple loci interactions)
- MUTAVI-sourced mutation rates (authoritative reference: `docs/muhabbet-kusu-genetik-rehberi.md`)
- Inbreeding coefficient calculation
- Calculation version: v5 (2026-07-09: multi-locus combiner keeps the DF subset a distinct `(double factor)` result so offspringHomozygous lethals fire in multi-locus crosses; v4 tagged full-dominant homozygotes "(double)", 2026-07-02)
- 950+ genetics-specific domain tests

## `calculationVersion`

Stored per result so future algorithm changes can be detected and results can be flagged as stale.

## Compare / Sharing

- `GeneticsCompareScreen` can compare selected history rows across phenotype probabilities.
- Compare results include a share action that builds a short text summary from the selected calculations and opens the platform share sheet.
- Share failures are logged through `AppLogger` and surfaced with localized UI feedback.

## Local AI Integration

`LocalAiService` can analyze a bird photo to suggest gender/mutation with confidence score:
- Confidence < 0.7 → "tahmin" label, no auto-save
- Confidence ≥ 0.7 → user review + accept to save
- See [[domain/local-ai]]

## Rules

- `.claude/rules/local-ai.md` — AI confidence thresholds
- Genetic color constants are an **exception** to hardcoded colors anti-pattern (biology requires fixed colors)

## See Also

- [[domain/genetics-engine]]
- [[features/_features-index]]
