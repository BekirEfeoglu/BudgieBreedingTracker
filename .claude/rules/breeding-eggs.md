# Breeding & Eggs

Rules for the breeding tracking and egg management lifecycle. Applies to
`lib/features/breeding/`, `lib/features/eggs/`, `lib/domain/services/eggs/`,
`lib/domain/services/incubation/`, and repositories/models for breeding pairs,
incubations, clutches, eggs, and chicks.

## Change Entry Checklist

Before editing any part of this lifecycle:

- [ ] Mark every entity and side effect the change can reach in the canonical
  chain; do not review only the screen named in the task.
- [ ] Trace the real UI -> notifier/service -> repository -> DAO/remote path.
  UI must not bypass lifecycle orchestration for a convenient direct write.
- [ ] State the primary mutation boundary, optional side effects, rollback
  behavior, and the stable IDs used for retry/offline convergence.
- [ ] Identify impacted free-tier counts, parent closure rules, reminders,
  calendar events, and auto-created chick behavior.
- [ ] Identify stale-snapshot and duplicate-submit risks before adding awaits.
- [ ] Read the corresponding `obsidian-brain/features/*` and
  `obsidian-brain/domain/*` pages; update them when behavior changes.

## Entity Chain
- Canonical lifecycle: `Bird -> BreedingPair -> Incubation -> Clutch -> Egg -> Chick`
- Validate pair birds before writing: both exist, belong to the active user, are alive, have the expected genders, and share the same species
- Incubation species comes from the validated breeding pair species, not from a hardcoded default
- Incubation dates and hatch expectations must use `species_incubation_config.dart` / model helpers, not literal day counts
- When pair species changes, linked incubations must be updated consistently, including expected hatch dates when a start date exists

## Write Atomicity
- Breeding creation saves the pair, incubation, and both pending-sync rows in
  one real Drift transaction through `BreedingCreationPersistence`
- Remote pushes run only after that transaction commits and preserve parent
  order (pair before incubation); do not reintroduce compensating soft-delete
  rollback for this create path
- Parent deletion must not proceed if related cleanup discovery, child cleanup, or notification cleanup fails
- Use stable client-generated IDs for the whole chain so local-first writes remain sync-safe
- Ignore duplicate create/update/delete actions while notifier state is loading

### Create / Update Checklist

- [ ] Pair validation occurs immediately before persistence, after any awaited
  reads that could make an earlier UI validation stale.
- [ ] Pair + incubation creation uses the existing real Drift transaction; a
  failed incubation insert leaves neither entity nor pending-sync row committed.
- [ ] Remote push starts after commit and preserves parent-before-child order.
- [ ] Species changes recompute dependent hatch expectations and replace stale
  reminder/calendar work; they do not leave mixed-species derived data.
- [ ] Every client-generated ID remains stable across retries and devices.
- [ ] Update code re-fetches/rebases where a stale UI snapshot could overwrite
  concurrent edits to unrelated fields.

## Egg Status Transitions
- `EggStatus` (`lib/core/enums/egg_enums.dart`) has **9** members — every `switch`
  must stay exhaustive over all of them (CLAUDE.md anti-pattern #16):
  `unknown`, `laid`, `fertile`, `infertile`, `hatched`, `empty`, `damaged`,
  `discarded`, `incubating`. `infertile` and `empty` are real statuses, not
  synonyms of `discarded`/`unknown` — do not drop them from a status list
- Marking an egg `hatched` must set `hatchDate`
- Marking an egg `fertile` must set `fertileCheckDate`
- Marking an egg `discarded` must set `discardDate`
- A hatched egg should auto-create one chick only when no chick already exists
  for that egg. Drift and Supabase enforce this with the partial unique index
  `idx_chicks_active_egg_unique`
- Automatic chicks reuse the egg UUID as their chick ID so concurrent offline
  hatches on different devices converge on the same remote upsert
- Auto-created chicks inherit `userId`, `eggId`, `clutchId`, and `hatchDate` from the egg context

### Transition Checklist

- [ ] The requested transition is valid for the current persisted status, not
  merely for the stale object supplied by the UI.
- [ ] Status-specific dates are set or cleared consistently and covered by tests.
- [ ] Terminal-state logic continues to use the enum/model helper rather than a
  second private list that can drift.
- [ ] Hatch retry/concurrent-device behavior still produces at most one active
  chick linked to the egg.
- [ ] After a terminal transition or deletion, parent incubation and pair state
  are re-evaluated so active limits cannot be stranded.

## Side Effects
- Notification and calendar generation are side effects after local persistence succeeds
- Optional side-effect failures must not undo a successful primary mutation; surface a localized warning such as `errors.background_tasks_partial`
- Supabase-unavailable calendar generation is an expected local/offline condition; log it at info level and continue
- Destructive parent operations must cancel incubation milestones and egg turning reminders for both incubation IDs and related egg IDs
- When a breeding pair is cancelled or completed, active incubations must be closed with the matching status and related reminders cancelled

### Destructive Flow Checklist

- [ ] Discover and validate the complete child graph before the destructive
  boundary. A failed blocking lookup must not be interpreted as "no children".
- [ ] Preserve surviving chicks by detaching lifecycle links when the existing
  contract requires it; do not silently delete live records.
- [ ] Delete/close children in FK-safe order and confirm the primary mutation
  can proceed before cancelling reminders.
- [ ] Cancel both incubation-scoped and egg-scoped notifications and remove or
  regenerate related calendar rows as the operation requires.
- [ ] A blocking cleanup failure prevents success; an optional post-persist
  side-effect failure becomes a localized warning and remains observable.

## Free Tier And Guards
- Breeding pair and active incubation limits must use `freeTierLimitServiceProvider`
- `effectivePremiumProvider` is the premium source for feature limit bypasses; grace-period behavior must remain honored by that provider
- Client-side limits improve UX only; server/RLS/Edge Function validation remains authoritative

## Tests Required
- Add provider tests for duplicate submit guards, rollback paths, and side-effect warning paths
- Add repository/DAO tests when entity chain, FK behavior, sync metadata, or soft delete behavior changes
- Add e2e or integration coverage when a change crosses pair, incubation, egg, and chick boundaries
- Verify destructive flows cancel notifications and do not leave orphan child records
- Use `addTearDown(container.dispose)` for every `ProviderContainer`

### Required Scenario Matrix

| Changed behavior | Required proof |
|---|---|
| Pair/incubation create | valid path, every bird-validation rejection, transaction rollback, ordered post-commit sync |
| Species/date derivation | supported species, unknown/fallback behavior, species change, DST-safe forward dates |
| Egg transition | every allowed/rejected transition, status date, stale snapshot rebase, terminal parent closure |
| Hatch | first hatch creates one chick, retry is idempotent, concurrent duplicate is rejected/converges, chick failure warns |
| Delete/cancel/complete | FK-safe cleanup, surviving chick handling, blocked cleanup, incubation+egg reminder cleanup |
| Optional side effect | primary row stays committed, localized warning surfaces, failure is logged without PII |
| UI action | loading guard blocks double submit; widget remains mounted-safe after awaits |
| Offline/sync | stable IDs, pending-sync rows, parent-before-child ordering, retry/upsert behavior |

## Local Quality-Gate Mapping

`scripts/run_local_quality_gate.sh` includes untracked files in its changed-path
set and automatically calls `scripts/run_breeding_egg_regression.sh` when a
breeding/egg/chick lifecycle path, its scheduler/calendar integration, or this
rule changes.

| Control | Automated evidence | Manual residual |
|---|---|---|
| Focused provider orchestration | `scripts/run_breeding_egg_regression.sh` | Confirm the changed production path is represented by those fixtures |
| Rule/wiki/symbol consistency | `scripts/run_local_quality_gate.sh` | Read biological and lifecycle claims against their authority; green links are not proof |
| Enum/model/generated changes | build runner + analyzer + focused tests | Review `unknown` semantics and transition intent |
| Drift/Supabase schema | migration tests + `verify_migration_drift.py` | Verify production migration/RLS state when deployment is in scope |
| L10n warning/error copy | `check_l10n_sync.py --strict-keys` | Review meaning, placeholders, overflow, and actionability in all three languages |
| Notification/calendar cleanup | focused unit/provider tests | Exercise one real-device flow when platform scheduling behavior changed |

The automatic regression suite is a floor, not proof of complete lifecycle
coverage. Add a focused regression before changing behavior when the matrix row
has no existing test.

## Definition Of Done

- [ ] Canonical chain and ownership/species invariants remain true.
- [ ] Transaction, retry, warning, and destructive cleanup boundaries are explicit.
- [ ] No duplicate submit or duplicate active chick path remains.
- [ ] Notification/calendar cleanup is covered for every affected identifier.
- [ ] Focused regression and the canonical local quality gate pass.
- [ ] Changed rule/wiki/current-behavior claims are synchronized; historical log
  entries remain historical and are not rewritten.

> **Related**: data-layer.md (offline-first writes), providers.md (loading/race guards), testing.md (provider/repository tests), error-handling.md (warnings vs errors)
