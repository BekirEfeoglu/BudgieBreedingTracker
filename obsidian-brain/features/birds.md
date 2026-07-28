# Feature: birds

**Purpose**: Core bird management — CRUD, profile view, photo gallery, filter/sort.

## Key Screens

- Bird list (filterable by gender, species, status)
- Bird list photo grid toggle
- Bird list cage ledger bottom sheet
- Bird detail / profile
- Bird detail life timeline
- Bird form (add/edit)
- Bird photo gallery

## Key Providers

- `birdsStreamProvider(userId)` — `StreamProvider<List<Bird>>` from Drift
- `birdByIdProvider(id)` — `StreamProvider.family<Bird?, String>`
- `birdTimelineProvider(bird)` — combines existing Drift streams into profile events
- Filter/sort notifiers
- `birdListViewModeProvider` — list/grid visual mode
- `cageSummariesProvider(birds)` — groups alive birds by normalized `cageNumber`, with unassigned birds last.

## Data

- **Model**: `lib/data/models/bird_model.dart` (Freezed)
- **Table**: `lib/data/local/database/tables/birds_table.dart`
- **DAO**: `lib/data/local/database/daos/birds_dao.dart`
- **Repository**: `lib/data/repositories/bird_repository.dart`
- **Remote source**: `lib/data/remote/api/bird_remote_source.dart`

## Lifecycle Side Effects

`BirdLifecycleService` (`lib/domain/services/birds/bird_lifecycle_service.dart`,
`birdLifecycleServiceProvider`) handles cross-domain cleanup when a bird leaves
the user's inventory. `bird_form_providers.dart` calls
`cancelActiveBreedingsForBird(id)` on the sold / gifted / dead / delete paths.
For each **active** breeding pair the bird belongs to it:

1. Cancels the pair (`BreedingStatus.cancelled` + `separationDate`)
2. Cancels related active incubations (`IncubationStatus.cancelled`)
3. Cancels scheduled reminders — incubation milestones **and** per-egg turning
   reminders (species resolved per incubation, matching the breeding-cancel path)
4. Removes calendar/events for the pair (`eventRepo.removeByBreedingPairIds`)

Side effects are best-effort and never rethrow: a cleanup failure must not undo
the primary bird mutation (per `breeding-eggs.md`). Errors are logged via
`AppLogger.error`. `cancelActiveBreedingsForBird` returns `bool` (success/failure);
`BirdFormState.warning` surfaces `errors.background_tasks_partial` to the user on
failure instead of dropping it silently — matches the breeding/egg notifier pattern.

## Photo Upload

- Picker: 1920×1920/q85; picker sonrası raw 2 MiB guard. `StorageService`,
  safety scan ve `bird-photos` bucket limiti aynı sınırı uygular
- `scan-image-safety` Edge Function for objectionable-content checks (wired through
  `StorageService.uploadBirdPhoto` → `_uploadFile` → `_uploadBinary` →
  `_readValidatedUpload`, scan defaults on for `birdPhotosBucket`)
- Stored in `bird-photos` bucket (private, user-scoped RLS)
- Displayed with `CachedNetworkImage`
- `createBird`: once the bird row itself is persisted, a later failure (photo
  gallery row save, free-tier count calc) is reported as a non-blocking
  `warning` (`birds.photo_gallery_save_partial`), not a hard error — avoids a
  confused user retrying into a duplicate bird, and the compensating storage
  cleanup only fires when the bird row was never persisted (so it never
  deletes a photo object a saved bird's `photoUrl` still references)
- Unexpected photo storage/DB errors (gallery add/delete in
  `bird_detail_photos.dart`, the `createBird` inner upload catch) are reported to
  Sentry via `reportUnexpectedToSentry` (`sentry_error_filter.dart`, see
  [[patterns/observability]]); transient network/validation exceptions stay
  excluded. Previously these paths only logged.

## Sensitive Field Encryption

`BirdsDao` encrypts `ringNumber`, `notes`, and `genotypeInfo` at rest (see
`encryption.md`). On decrypt failure (wrong/rotated key, corruption,
tampering), `_decryptSensitive` logs via `AppLogger.error` + `Sentry.captureException`
and returns `null` for that field — it never returns the raw ciphertext as if
it were plaintext.

## Filter Bar

Horizontal scrollable row (replaced Wrap layout in 2026-04 refactor). Filters include
gender and status; status supports `alive`, `dead`, `sold`, and `gifted`.
If filters/search produce no rows, the empty state exposes a localized clear
action that resets both sources.

Ring numbers are searchable and sortable with natural ordering; empty ring numbers stay
last in both ascending and descending ring sorts.

## Bulk Selection

Selection mode has a visible app-bar entry and therefore does not depend on a
hidden long-press gesture. Long-press context menus still offer Select as a
shortcut. While selection mode is active, card context menus are disabled so
tap consistently toggles selection; bulk actions remain disabled until at
least one bird is selected. List and grid checkboxes keep a minimum 48dp target.

## Ring Number Uniqueness

`BirdFormIdentitySection` checks `BirdRepository.hasRingNumber` after a 400ms
debounce while the user types. A monotonic request ID drops stale async results,
`mounted` guards disposal, and `excludeId` prevents the edited bird from
matching itself. The lookup is best-effort for early feedback; both create and
update submit paths normalize and re-check the ring before saving, then surface
`birds.ring_number_not_unique` on conflict. Empty ring numbers remain valid.

## Cage Ledger

Bird records already carry `cageNumber`; no separate `Cage` table exists yet.
The bird list app bar opens `CageLedgerSheet`, which groups living birds by cage
and lets users jump to bird detail. This is an MVP for cage/aviary management
without schema changes.

Breeding pair selection marks candidates from the same cage as the already selected
opposite-sex bird with `breeding.same_cage_recommended`.

## Timeline

Bird detail includes a read-only life timeline assembled from current local data:
birth/registration, status transfer, pairings, egg summaries, chick origin, and health
records. No separate timeline table exists.

## Rules

- `.claude/rules/birds.md` — owning rule: status lifecycle side effects, encryption, photo partial-failure, cage ledger, free tier
- `.claude/rules/data-layer.md` — Bird is a root entity (no ValidatedSyncMixin needed)
- `.claude/rules/assets-images.md` — photo upload pipeline
- `.claude/rules/breeding-eggs.md` — Bird as head of entity chain
- `.claude/rules/forms-validation.md` — async validation + submit fallback

## See Also

- [[features/_features-index]]
- [[features/breeding]]
- [[data-layer/repositories]]
