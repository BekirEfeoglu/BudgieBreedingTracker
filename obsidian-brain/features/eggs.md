# Feature: eggs

**Purpose**: Per-egg lifecycle management inside an incubation — add, mark
fertile / hatched / damaged / discarded, schedule turning reminders.
Driver for chick auto-creation and incubation closure.

## Key Screens

| Screen | Route |
|--------|-------|
| `EggManagementScreen` | `AppRoutes.breedingEggs` (`/breeding/:id/eggs`) — list under an incubation |
| `EggManagementAddSheet` | Bottom sheet — add new egg without leaving the screen |

There's no dedicated form route — add/edit happens in bottom sheets so
the egg list stays visible (rapid entry during a clutch).

## Status Transitions

```
laid → fertile → incubating → hatched
             ↘              ↘ damaged
              → discarded
```

| Target status | Side effect |
|---------------|-------------|
| `fertile` | sets `fertileCheckDate` |
| `discarded` | sets `discardDate`, cancels turning reminders |
| `damaged` | cancels turning reminders |
| `hatched` | sets `hatchDate`, auto-creates chick (if none), reschedules milestones |

When **all eggs in an incubation** reach a terminal status, the
incubation auto-closes (and the parent pair closes if no other active
incubations) — see [[domain/eggs-service]].

## Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `eggListByClutchProvider(clutchId)` | `StreamProvider.family` | Eggs under a clutch |
| `eggActionsProvider` | `NotifierProvider` | Add/update/delete actions surface (`EggActionsState`) |

## Data

| Layer | File |
|-------|------|
| Drift table | `eggs_table.dart` |
| Repository | `egg_repository.dart` — uses `ValidatedSyncMixin` (FK parent: incubation → breeding_pair) |
| Mapper | `eggs_mapper.dart` |
| DAO | `eggs_dao.dart` |

## Service

[[domain/eggs-service]] (`EggActionsNotifier`) orchestrates the chain:
RLS preflight → repository write → reminders → calendar event → parent
closure. UI never bypasses the service.

## Auto-Create Chick

`markAsHatched` triggers `_autoCreateChickIfMissing(egg)`. Idempotent —
will not duplicate if a chick already exists. Failure surfaces as a
warning, not an error (egg state is the source of truth).

## Reminders

Turning reminders use deterministic notification IDs (`egg_${id}_day_${n}`)
so updates cleanly cancel + reschedule. UTC + `tz.TZDateTime` everywhere
(see [[patterns/datetime-format]]).

## Rules

- `.claude/rules/breeding-eggs.md` — lifecycle contract
- `.claude/rules/data-layer.md` — `ValidatedSyncMixin` requirement
- `.claude/rules/datetime-format.md` — DST-safe day math

## See Also

- [[features/breeding]] — parent incubation
- [[features/chicks]] — auto-created chick lifecycle
- [[domain/eggs-service]] — orchestration
- [[domain/incubation-service]] — milestone math
- [[features/_features-index]]
