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
- Pair delete cascade order: detach chicks (null `eggId`/`clutchId`) → remove eggs → remove incubations → remove legacy `Clutch` rows (`ClutchRepository.getByBreeding`) → remove pair → **cancel notifications/calendar last**. Reminders are cancelled only AFTER the cascade is confirmed to proceed; if a child is still live the delete blocks with a warning and reminders keep firing — cancelling up-front would strand a still-alive pair with its reminders already gone (May 2026 5-tab audit). Chicks survive as standalone records since they are live entities with their own lifecycle. Clutch cleanup is best-effort (legacy/cross-device data only — the in-app UI doesn't create clutches) and never blocks pair removal. (`breeding_form_actions.dart` `deleteBreeding`, June 2026 breeding-tab audit)

## Free Tier Guards

- Breeding pair + active incubation limits via `freeTierLimitServiceProvider`
- Bypass allowed for `effectivePremiumProvider`

## Side Effects After Local Persist

- Notification scheduling (incubation milestone reminders)
- Calendar event generation
- Optional failures must not undo primary mutation — show warning `errors.background_tasks_partial`

## Detail UX

- Detail shows a Season Summary card from existing eggs + chicks: total, fertile/incubating/hatched, hatched, live chicks.
- `IncubationRiskCard` surfaces top risks from `IncubationRiskAssistant` (overdue eggs, stale tracking, hatch-rate decline, high unsuccessful-egg rate, chick health loss). List screen shows global summary; detail screen filters to the current pair.

## Incubation Risk Assistant

- Service: `lib/domain/services/breeding/incubation_risk_assistant.dart`
- Provider: `incubationRiskSummaryProvider.family(userId)` joins pair + incubation + egg + chick streams
- Severity: `info` / `warning` / `critical`; widget caps to top 3 by severity rank
- Purely derived (no DB writes); recomputes when any source stream emits
- Detail-screen `_PairRiskCard` is a secondary section: on stream error it collapses to `SizedBox.shrink()` (keeps the detail body usable) but logs via `AppLogger.error` so the failure stays observable rather than silent

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
