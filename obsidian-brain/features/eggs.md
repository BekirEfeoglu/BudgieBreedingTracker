# Feature: eggs

**Purpose**: Egg tracking within a clutch — status transitions, fertile checks, hatch events.

## Key Screens

- Egg list within clutch
- Egg detail
- Egg form (add/edit)

## Egg Status Transitions

```
laid → fertile → incubating → hatched
             ↘              ↘ damaged
              → discarded
```

- `hatched`: must set `hatchDate`
- `fertile`: must set `fertileCheckDate`
- `discarded`: must set `discardDate`
- `hatched` → auto-create one chick (only if no chick exists for that egg)

## Key Providers

- `eggListByClutchProvider(clutchId)` — StreamProvider.family
- Egg status notifier

## Data

- **Table**: `eggs_table.dart`
- **Repository**: `egg_repository.dart` — requires `ValidatedSyncMixin` (parent: breeding_pair)

## Rules

- `.claude/rules/breeding-eggs.md` — full egg lifecycle rules
- `.claude/rules/data-layer.md` — ValidatedSyncMixin required

## See Also

- [[features/breeding]]
- [[features/chicks]]
- [[features/_features-index]]
