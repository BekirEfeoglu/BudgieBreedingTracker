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
- `breedingSeasonSummaryProvider` — egg/chick outcome summary per incubation
- Breeding notifier (handles create, cancel, complete, rollback)

## Lifecycle Rules (from breeding-eggs.md)

- Validate pair birds: both exist, belong to user, alive, correct genders, same species
- Incubation species comes from pair species (never hardcoded)
- Hatch dates from `species_incubation_config.dart`, not literal day counts
- Species change on pair → linked incubations updated
- Pair cancel/complete → close active incubations + cancel reminders
- Pair delete cascade order: cancel notifications → detach chicks (null `eggId`/`clutchId`) → remove eggs → remove incubations → remove pair. Chicks survive as standalone records since they are live entities with their own lifecycle. (`breeding_form_actions.dart` `deleteBreeding`)

## Free Tier Guards

- Breeding pair + active incubation limits via `freeTierLimitServiceProvider`
- Bypass allowed for `effectivePremiumProvider`

## Side Effects After Local Persist

- Notification scheduling (incubation milestone reminders)
- Calendar event generation
- Optional failures must not undo primary mutation — show warning `errors.background_tasks_partial`

## Detail UX

- Detail shows a Season Summary card from existing eggs + chicks: total, fertile/incubating/hatched, hatched, live chicks.

## Pair Form UX

- When both parents are selected, the form calculates a candidate offspring inbreeding coefficient from existing pedigree data.
- Low/minimal risk is shown inline; moderate or higher risk (`>= 25%`) requires explicit confirmation before save.
- Calculation reuses `InbreedingCalculator`; no breeding schema change is required.

## Rules

- `.claude/rules/breeding-eggs.md` — canonical breeding rules
- `.claude/rules/data-layer.md` — ValidatedSyncMixin on breeding_pair_repository

## See Also

- [[features/eggs]]
- [[features/chicks]]
- [[features/_features-index]]
- [[domain/notification-service]]
