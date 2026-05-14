# Feature: genealogy

**Purpose**: Family tree visualization for birds — ancestors, descendants, inbreeding warning.

## Key Screens

- Family tree view (interactive graph)
- Bird ancestry detail

## Key Providers

- `genealogyTreeProvider(birdId)` — async tree structure

## Inbreeding Detection

Inbreeding coefficient calculated in genetics engine. High coefficient triggers UI warning. See [[domain/genetics-engine]].

## See Also

- [[features/birds]]
- [[features/genetics]]
- [[features/_features-index]]
