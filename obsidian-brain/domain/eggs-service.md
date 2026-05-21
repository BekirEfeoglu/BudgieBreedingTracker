# Eggs Service

Source: `.claude/rules/breeding-eggs.md`

**Location**: `lib/domain/services/eggs/`

## Responsibility

Domain-level orchestration for egg lifecycle actions (add, status transition,
delete). Sits above `EggRepository` because the chain has side effects:
auto-chick creation, parent incubation closure, parent pair closure,
notification cancellation, calendar event generation.

## State

`EggActionsState` exposes:

| Field | Purpose |
|-------|---------|
| `isLoading` | Guards against double-submit |
| `error` | Localized blocker — primary write failed |
| `warning` | Localized soft-failure — primary write succeeded, side effect didn't |
| `isSuccess` | Last action completed |
| `chickCreated` | Auto-create chick fired and inserted a row |

Triple-state (`error` / `warning` / `success`) lets UI distinguish
"action failed" from "saved, but reminders didn't reschedule" — both need
user feedback, with different urgency.

## Lifecycle Methods

```
addEgg(incubationId, layDate, eggNumber)
  ├── guard isLoading
  ├── verify incubation belongs to current user (RLS preflight, audit K11)
  ├── insert egg via EggRepository (.upsert with client-generated UUID v7)
  ├── reschedule turning reminders
  └── generate calendar event (best-effort)

updateEggStatus(egg, newStatus)
  ├── set status + status-specific date (hatchDate / fertileCheckDate / discardDate)
  ├── if newStatus == hatched → _autoCreateChickIfMissing
  ├── reschedule reminders for the egg
  └── _completeIncubationIfAllEggsTerminal (closes parent if all eggs terminal)
       └── _flipPairIfNoActiveIncubations (closes pair if no active incubations)

deleteEgg(id)
  ├── soft-delete via repository
  ├── cancel egg-specific notifications
  └── propagate to _completeIncubationIfAllEggsTerminal
```

## Auto-Create Chick

`markAsHatched` on an egg triggers `_autoCreateChickIfMissing(egg)`. Behavior:

- **Idempotent**: only inserts when no chick already exists for the egg
- **Inherits**: `userId`, `eggId`, `clutchId`, `hatchDate` from the egg
- **Does not rollback**: if chick insert fails, the egg stays `hatched`,
  and the failure surfaces as a `warning` so the user can add the chick
  manually. Egg state is the source of truth.

## Free-Tier Recovery

After every status transition, parent incubation + pair are re-evaluated.
When all eggs reach a terminal status, the incubation flips to `completed`
and the pair flips to `completed`/`cancelled` so `guardBreedingPairLimit`
stops counting it. Without this, free-tier users got stranded with no
remaining pair slots after their eggs hatched out (audit fix, May 2026).

## Side-Effect Errors

Reminder/calendar failures are collected in `sideEffectErrors`, joined,
and reported as a localized `warning`. Primary write success is never
undone by a side-effect failure — `errors.background_tasks_partial`
covers the generic case.

## Anti-Patterns

1. Calling `EggRepository.upsert()` directly from UI (bypasses chick auto-create)
2. Rolling back egg state on chick failure (egg is the source of truth)
3. Forgetting RLS preflight on add (incubation ownership check)
4. Treating side-effect failure as primary failure (user thinks egg wasn't saved)
5. Skipping `_completeIncubationIfAllEggsTerminal` on status change (free-tier leak)

## See Also

- [[features/eggs]] — UI consumers
- [[features/chicks]] — auto-created chick lifecycle
- [[domain/incubation-service]] — milestone math
- [[domain/notification-service]] — turning reminders
- [[domain/services-index]]
