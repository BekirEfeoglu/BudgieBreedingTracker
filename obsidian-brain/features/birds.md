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

- **Model**: `lib/data/models/bird.dart` (Freezed)
- **Table**: `lib/data/local/database/tables/birds_table.dart`
- **DAO**: `lib/data/local/database/daos/birds_dao.dart`
- **Repository**: `lib/data/repositories/bird_repository.dart`
- **Remote source**: `lib/data/remote/api/bird_remote_source.dart`

## Photo Upload

- Max 10MB file size guard
- `scan-image-safety` Edge Function for NSFW/malware check
- Stored in `bird-photos` bucket (private, user-scoped RLS)
- Displayed with `CachedNetworkImage`

## Filter Bar

Horizontal scrollable row (replaced Wrap layout in 2026-04 refactor). Filters include
gender and status; status supports `alive`, `dead`, `sold`, and `gifted`.

Ring numbers are searchable and sortable with natural ordering; empty ring numbers stay
last in both ascending and descending ring sorts.

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

- `.claude/rules/data-layer.md` — Bird is a root entity (no ValidatedSyncMixin needed)
- `.claude/rules/assets-images.md` — photo upload pipeline
- `.claude/rules/breeding-eggs.md` — Bird as head of entity chain

## See Also

- [[features/_features-index]]
- [[features/breeding]]
- [[data-layer/repositories]]
