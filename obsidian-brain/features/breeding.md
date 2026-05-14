# Feature: breeding

**Purpose**: Breeding pair creation, incubation tracking, lifecycle management.

## Key Screens

- Breeding pairs list
- Breeding pair detail
- Breeding pair form (add/edit)
- Incubation detail

## Entity Chain

```
Bird → BreedingPair → Incubation → Clutch → Egg → Chick
```

Breeding creates the pair + incubation as one atomic operation. Pair/incubation rollback if incubation save fails.

## Key Providers

- `breedingPairListProvider` — StreamProvider
- `activeIncubationsProvider` — live incubation streams
- Breeding notifier (handles create, cancel, complete, rollback)

## Lifecycle Rules (from breeding-eggs.md)

- Validate pair birds: both exist, belong to user, alive, correct genders, same species
- Incubation species comes from pair species (never hardcoded)
- Hatch dates from `species_incubation_config.dart`, not literal day counts
- Species change on pair → linked incubations updated
- Pair cancel/complete → close active incubations + cancel reminders

## Free Tier Guards

- Breeding pair + active incubation limits via `freeTierLimitServiceProvider`
- Bypass allowed for `effectivePremiumProvider`

## Side Effects After Local Persist

- Notification scheduling (incubation milestone reminders)
- Calendar event generation
- Optional failures must not undo primary mutation — show warning `errors.background_tasks_partial`

## Rules

- `.claude/rules/breeding-eggs.md` — canonical breeding rules
- `.claude/rules/data-layer.md` — ValidatedSyncMixin on breeding_pair_repository

## See Also

- [[features/eggs]]
- [[features/chicks]]
- [[features/_features-index]]
- [[domain/notification-service]]
