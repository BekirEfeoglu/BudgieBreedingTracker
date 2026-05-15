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

- Detail shows weight tracking from existing growth measurements.
- Weaning prompts to save the chick as a Bird through the existing promotion flow.

## Rules

- `.claude/rules/breeding-eggs.md` — auto-chick creation rules
- `.claude/rules/data-layer.md` — ValidatedSyncMixin

## See Also

- [[features/eggs]]
- [[features/breeding]]
- [[features/_features-index]]
