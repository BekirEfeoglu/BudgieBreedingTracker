# Breeding & Eggs

Rules for the breeding tracking and egg management lifecycle. Applies to
`lib/features/breeding/`, `lib/features/eggs/`, `lib/domain/services/eggs/`,
`lib/domain/services/incubation/`, and repositories/models for breeding pairs,
incubations, clutches, eggs, and chicks.

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

## Side Effects
- Notification and calendar generation are side effects after local persistence succeeds
- Optional side-effect failures must not undo a successful primary mutation; surface a localized warning such as `errors.background_tasks_partial`
- Supabase-unavailable calendar generation is an expected local/offline condition; log it at info level and continue
- Destructive parent operations must cancel incubation milestones and egg turning reminders for both incubation IDs and related egg IDs
- When a breeding pair is cancelled or completed, active incubations must be closed with the matching status and related reminders cancelled

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

> **Related**: data-layer.md (offline-first writes), providers.md (loading/race guards), testing.md (provider/repository tests), error-handling.md (warnings vs errors)
