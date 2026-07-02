# Feature: chicks

**Purpose**: Chick tracking from hatch to fledgling. Growth records, gender determination.

## Key Screens

- Chick list (with filter bar — horizontal scrollable row)
- Chick detail
- Chick form (add/edit)

## Auto-Creation

When an egg is marked `hatched`, one chick is auto-created with:
- `userId`, `eggId`, `clutchId`, `hatchDate` inherited from the egg

Manual chick creation is also supported.

## Key Providers

- `chickListProvider` — StreamProvider
- `chickDetailProvider(id)` — StreamProvider.family
- `growthMeasurementsByChickProvider(chickId)` — chick weight/growth history

## Data

- **Table**: `chicks_table.dart`
- **Growth table**: `growth_measurements_table.dart` (`chickId`, `weight`, `measurementDate`)
- **Repository**: `chick_repository.dart` — requires `ValidatedSyncMixin` (parent: egg)

## Detail UX

- Detail shows weight tracking from existing growth measurements (read-only —
  there is currently no UI to add a new measurement anywhere in the app).
- Weaning prompts to save the chick as a Bird through the existing promotion flow.
- `healthStatus == deceased` and `deathDate` must stay in sync: editing a
  deceased chick's status back to healthy/sick/unknown via the form clears
  `deathDate` (`ChickFormNotifier.updateChick`) — otherwise the row ends up
  "alive but has a death date".
- `promoteToBird` resolves species transitively via `eggId -> incubation ->
  breeding pair`; a manually-created chick (no `eggId`) has no species
  anywhere on `Chick`, so it always promotes to `Species.unknown`.

## Statistics

`chickSurvivalProvider` (healthy/sick/deceased pie chart) is backed by
`ChicksDao.watchHealthStatusCounts` (SQL `GROUP BY health_status`), not a
Dart-side walk of the chick list — same SQL-aggregation pattern as
`watchMonthlyHatched` and `watchUnweanedCount`.

## Rules

- `.claude/rules/breeding-eggs.md` — auto-chick creation rules
- `.claude/rules/data-layer.md` — ValidatedSyncMixin

## See Also

- [[features/eggs]]
- [[features/breeding]]
- [[features/_features-index]]
