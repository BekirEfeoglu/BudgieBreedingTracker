# Feature: health_records

**Purpose**: Health event tracking for individual birds — vet visits, medication, weight records.

## Key Screens

- Health records list (per bird)
- Health record detail
- Health record form

## Data

- **Table**: `health_records_table.dart`
- **Repository**: `health_record_repository.dart` — requires `ValidatedSyncMixin` (parent: bird)

## Attachments

Health documents/photos stored in `health-records` Supabase Storage bucket (private). 10MB guard applied.

## Rules

- `.claude/rules/data-layer.md` — ValidatedSyncMixin required for FK to bird
- `.claude/rules/assets-images.md` — document upload

## See Also

- [[features/birds]]
- [[features/_features-index]]
