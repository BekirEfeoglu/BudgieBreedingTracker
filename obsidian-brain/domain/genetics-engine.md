# Genetics Engine

Source: `.claude/rules/local-ai.md`, project memory

**Location**: `lib/domain/services/genetics/`

## Capabilities

- **Punnett square** — standard Mendelian inheritance calculation
- **Epistasis** — multi-locus gene interaction (e.g., opaline + clearwing)
- **MUTAVI rates** — authoritative mutation frequency data (see `docs/muhabbet-kusu-genetik-rehberi.md`)
- **Inbreeding coefficient** — F coefficient calculation from pedigree
- **Dominant allelic series** — bug fixed 2026-04-08 (v2 calculation)
- 62+ genetics-specific tests

## `calculationVersion`

Every result stores the algorithm version. When the engine is updated, old results can be flagged stale.

- Current version: `v2`

## Confidence Thresholds (AI-assisted)

When `LocalAiService` provides a genetics suggestion:
- Confidence < 0.7 → show as "tahmin" (estimate), no auto-save
- Confidence ≥ 0.7 → show as suggestion, user must accept

## Phenotype Colors

Genetic phenotype colors are **exempt** from the hardcoded color anti-pattern — biological accuracy requires fixed colors. See [[patterns/anti-patterns]] rule #19.

## Reference

- `docs/muhabbet-kusu-genetik-rehberi.md` — MUTAVI-sourced guide, authoritative for mutation data
- `.claude/rules/local-ai.md` — AI confidence integration

## See Also

- [[features/genetics]]
- [[domain/local-ai]]
- [[domain/services-index]]
