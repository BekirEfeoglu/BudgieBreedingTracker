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

Breeding creates the pair + incubation as one atomic operation.
`BreedingCreationPersistence` writes both entities and both pending-sync rows
inside one Drift transaction. Remote push starts only after commit, pair first;
an incubation write failure rolls the local transaction back without a
compensating pair soft-delete.

## Key Providers

- `filteredBreedingPairsProvider` — pair list (filter/search/sort derived)
- `allIncubationsStreamProvider` — live incubation streams
- `breedingSeasonSummaryProvider` — egg/chick outcome summary per incubation
- Breeding notifier (handles create, cancel, complete, transaction failures)

## Lifecycle Rules (from breeding-eggs.md)

- Validate pair birds: both exist, belong to user, alive, correct genders, same species
- Incubation species comes from pair species (never hardcoded)
- Hatch dates from `species_incubation_config.dart`, not literal day counts
- Species change on pair → linked incubations updated (expected-hatch recomputed), old-species reminders cancelled + rescheduled, AND stale calendar `Event` rows cleaned + regenerated under the new species (`_updateIncubationSpeciesForPair`; calendar regen added 2026-07-02 — notifications were already handled but the calendar events kept the old species' milestone/hatch dates)
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
- `IncubationRiskSummary.risksForPair(id)` / `risksForIncubation(id)` return **cached, identity-stable, unmodifiable** lists (buckets grouped once into `_byPair`/`_byIncubation`, `List.unmodifiable`, shared `const []` for no-risk ids). Repeated calls return the same instance so `pairIncubationRisksProvider`/`incubationRisksProvider` can skip rebuilds when a pair's risks are unchanged; the returned list must not be mutated (freezing enforces it)
- Detail-screen `_PairRiskCard` is a secondary section: on stream error it collapses to `SizedBox.shrink()` (keeps the detail body usable) but logs via `AppLogger.error` so the failure stays observable rather than silent

## Pair Form UX

- When both parents are selected, the form calculates a candidate offspring inbreeding coefficient from existing pedigree data.
- Low/minimal risk is shown inline; moderate or higher risk (`>= 25%`) requires explicit confirmation before save.
- Calculation reuses `InbreedingCalculator`; no breeding schema change is required.

## Rules

- `.claude/rules/breeding-eggs.md` — canonical breeding rules
- `.claude/rules/data-layer.md` — ValidatedSyncMixin on breeding_pair_repository

## Change Safety

Breeding changes use the rule's entry, create/update, destructive-flow, and
scenario-matrix checklists. The local quality gate detects staged, unstaged,
and untracked lifecycle paths and automatically runs the focused
`scripts/run_breeding_egg_regression.sh` suite. That manifest now exercises the
real Drift transaction, breeding/egg notifiers, notification IDs and scheduling,
rescheduling/toggles, and calendar generation/provider wiring; it rejects
skipped or slow-tag-excluded manifest tests. Review must still trace the full
Bird → pair → incubation → clutch → egg → chick chain and manually confirm any
new branch not represented by a behavior assertion.

### Applied Checklist Evidence (2026-08-03)

The create/close production path was traced from
`breeding_form_body.dart` → `BreedingFormNotifier` →
`BreedingCreationPersistence` / `BreedingLifecyclePersistence` → local-first
repositories/DAOs and pending sync, followed by notification/calendar side
effects. The focused gate proves atomic rollback, duplicate-submit guards,
warning-not-rollback behavior, destructive cleanup, stable notification IDs,
and DST-safe reminder/calendar alignment. Server RLS state, biological claim
authority, translation meaning/layout, and a real-device platform scheduling
pass remain manual because local mocks cannot prove them.

## See Also

- [[features/eggs]]
- [[features/chicks]]
- [[features/_features-index]]
- [[domain/notification-service]]
