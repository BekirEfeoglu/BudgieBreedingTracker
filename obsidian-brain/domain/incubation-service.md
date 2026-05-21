# Incubation Service

Source: `.claude/rules/breeding-eggs.md`, `.claude/rules/datetime-format.md`

**Location**: `lib/domain/services/incubation/`

## Responsibility

Pure-function calculations and helpers for the egg/incubation lifecycle:
incubation day math, milestone schedule per species, environment monitoring,
species resolution for inherited pair species. No persistence, no network —
called by repositories, providers, and notification scheduling.

## Components

| File | Purpose |
|------|---------|
| `incubation_calculator.dart` | Stage colors, milestone generation, validation, status transitions |
| `species_incubation_config.dart` | Per-species milestone tuples (`candling`, `secondCheck`, `sensitivePeriod`, `expectedHatch`, `lateHatch`) |
| `incubation_milestone.dart` | `MilestoneType` enum (`candling`, `check`, `sensitive`, `hatch`, `late`) + `IncubationMilestone` value type |
| `environment_monitor.dart` | Temperature + humidity readings, `IncubationAlertSeverity` (`normal`/`warning`/`critical`) |
| `egg_species_resolver.dart` | Reads pair → derives species for incubation and its eggs |

## Day Math

Day counting goes through `core/utils/date_utils.dart` `DateUtils.dayDiff(start, end)`
which normalizes to UTC midnight (`.claude/rules/datetime-format.md`). Naive
`Duration.inDays` is forbidden — DST sun-up boundary returns `0` and breaks
milestone notifications.

```dart
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart' as date_utils;
final day = date_utils.DateUtils.dayDiff(layDate, DateTime.now());
```

## Milestone Resolution

```
IncubationCalculator._resolveMilestones(species: ..., totalDays: ...)
  ├── species != null   → incubationMilestonesForSpecies(species)
  ├── species == null and totalDays default → Species.unknown defaults
  └── custom totalDays  → proportional (0.39 / 0.78 / -2 / +3 days)
```

`Species.unknown` falls back to budgie defaults (18 days). Per-species tuples
are the canonical source — adding a new species means adding one entry to
`species_incubation_config.dart`.

## Environment Monitoring

`EnvironmentMonitor` builds `EnvironmentReading` snapshots with derived
`IncubationAlertSeverity` per axis (temp/humidity). Thresholds come from
`incubation_constants.dart`. Persistence and history are not part of this
service — UI captures readings, repository persists them.

## Auto-Create Chick

When `EggActionsNotifier.markAsHatched()` (see [[domain/eggs-service]]) flips
an egg's status to `hatched`, the chicks repository auto-creates a `Chick`
linked to the egg + clutch with the egg's `hatchDate`, **only if** no chick
exists yet for that egg. Failure here is surfaced as a warning, not a
rollback — the egg status change remains successful.

## See Also

- [[features/breeding]] — `IncubationRiskAssistant` consumes this service's outputs
- [[features/eggs]] — egg status transitions
- [[domain/eggs-service]] — egg actions notifier
- [[domain/notification-service]] — milestone reminder scheduling
- [[patterns/datetime-format]] — `DateUtils.dayDiff` rule
- [[domain/services-index]]
