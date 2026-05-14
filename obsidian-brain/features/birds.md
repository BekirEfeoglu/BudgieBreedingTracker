# Feature: birds

**Purpose**: Core bird management — CRUD, profile view, photo gallery, filter/sort.

## Key Screens

- Bird list (filterable by gender, species, status)
- Bird detail / profile
- Bird form (add/edit)
- Bird photo gallery

## Key Providers

- `birdListProvider` — `StreamProvider<List<Bird>>` from Drift
- `birdDetailProvider(id)` — `StreamProvider.family<Bird?, String>`
- Filter/sort notifiers

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

Horizontal scrollable row (replaced Wrap layout in 2026-04 refactor). Filters: gender, species, status, ring number.

## Rules

- `.claude/rules/data-layer.md` — Bird is a root entity (no ValidatedSyncMixin needed)
- `.claude/rules/assets-images.md` — photo upload pipeline
- `.claude/rules/breeding-eggs.md` — Bird as head of entity chain

## See Also

- [[features/_features-index]]
- [[features/breeding]]
- [[data-layer/repositories]]
