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
- Breeding creation saves the pair and its incubation as one logical operation
- If incubation save fails after pair save, rollback the pair to avoid orphan breeding records
- Parent deletion must not proceed if related cleanup discovery, child cleanup, or notification cleanup fails
- Use stable client-generated IDs for the whole chain so local-first writes remain sync-safe
- Ignore duplicate create/update/delete actions while notifier state is loading

## Egg Status Transitions
- `laid`, `fertile`, `incubating`, `hatched`, `damaged`, `discarded`, and `unknown` paths must remain explicit in model/provider logic
- Marking an egg `hatched` must set `hatchDate`
- Marking an egg `fertile` must set `fertileCheckDate`
- Marking an egg `discarded` must set `discardDate`
- A hatched egg should auto-create one chick only when no chick already exists for that egg
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
