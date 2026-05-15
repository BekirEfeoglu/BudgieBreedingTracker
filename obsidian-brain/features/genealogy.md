# Feature: genealogy

**Purpose**: Family tree visualization for birds — ancestors, descendants, inbreeding warning.

## Key Screens

- Family tree view (interactive graph)
- Bird ancestry detail

## Tree UX

- Tree view supports pan/zoom through `InteractiveViewer`.
- Tapping a bird node opens bird detail; root chicks route to chick detail.
- Bird nodes show photo thumbnails when `photoUrl` is available, otherwise fall back to gender/domain icon.

## Key Providers

- `genealogyTreeProvider(birdId)` — async tree structure

## Inbreeding Detection

Inbreeding coefficient calculated in genetics engine. High coefficient triggers UI warning. See [[domain/genetics-engine]].

## See Also

- [[features/birds]]
- [[features/genetics]]
- [[features/_features-index]]
