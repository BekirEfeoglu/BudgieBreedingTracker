# Data I/O: Backup, Import, Export

Source: `.claude/rules/data-io.md` (primary — backup format, runtime-key encryption, Excel i18n headers, PDF pedigree builders, free vs premium gating)

**Locations**:
- `lib/domain/services/backup/`
- `lib/domain/services/import/`
- `lib/domain/services/export/`

## Responsibility

User-controlled data movement across formats: JSON backup (full snapshot),
Excel import (bulk add), Excel export (per-entity sheets), PDF export
(genealogy, statistics). All flows are local-first — the file is the
artifact, and Supabase Storage is the optional cloud copy.

## Backup (JSON)

`BackupService` orchestrates `BackupDataCollector` (serialize) and
`BackupRestorer` (deserialize). Optional AES-256-CBC encryption via
`EncryptionService` (see [[domain/encryption-service]]); encrypted files
get `.enc.json` extension and auto-detect on restore.

| Method | Purpose |
|--------|---------|
| `createBackup(userId, {encrypt})` | Full snapshot → local JSON file |
| `restoreBackup(userId, filePath)` | Inverse — merge-upserts backup rows by id (no wipe/preview); rejects other users' backups and newer backup versions |
| `uploadBackup(userId, file)` | Push to `backups` Supabase Storage bucket |
| `listBackups(userId)` | Remote backup index, user-scoped |

`BackupScheduler` runs periodic local snapshots when the user opted in.
Remote bucket: `SupabaseConstants.backupsBucket`, RLS-scoped to owner.

## Import (Excel)

`DataImportService` consumes workbooks in the documented IMPORT column layout
(a hand-fillable template). **Option B (2026-07-04): export → import is now a
lossless round-trip.** `ExcelExportService` writes that exact column layout with
a trailing full-uuid ID column (birds also carry death/sale dates; eggs carry the
incubation link), and enum-backed fields (gender/species/status) are serialized
as stable enum NAMES — not localized labels — so re-import parses them back in
any locale. The parsers PRESERVE the exported id (upsert → idempotent re-import;
FK lineage refs resolve to the same rows). `findSheet` also folds diacritics so a
localized export sheet name ("Kuşlar") resolves to the ASCII template name, and
the importer additionally accepts the export's l10n sheet-name key. Bird parent
refs still go through `_sanitizeBirdParents` ("tolerant import"): on a normal
round-trip it nulls nothing (ids preserved), but a reference that **can't be
resolved** (cross-account / hand-crafted template) is nulled and the bird still
imports (no whole-bird drop), while a parent that resolves but is genetically
invalid (wrong gender / different species) still rejects the row. Breeding pairs
still require two resolvable birds and surface a clear `ImportResult` error.
The encrypted backup remains the recommended full-fidelity path (photos,
timestamps, all entities); Excel round-trips the tabular entities.

Supported sheets: birds, breeding pairs, **incubations**, eggs, chicks,
health records. Sheet columns are Turkish-labeled (master locale) — column
order is fixed, not name-based, to survive translation drift.

**FK-aware sheet ordering (2026-07-05):** `importAllFromExcel` runs
birds → breeding_pairs → **incubations → eggs** → chicks → health_records so an
egg's `incubationId` resolves to a freshly-imported incubation. Before this,
incubations were exported but had NO import parser — a full round-trip silently
dropped every incubation and left each egg's `incubationId` dangling (nulled by
the tolerant path). Now `parseIncubationRow` + `parseIncubationStatus` reconstruct
them and the exported id is written in FULL (was truncated to 8 chars) so the FK
resolves. Health records also gained id preservation (trailing ID column) so
re-import is idempotent, not duplicate-generating.

**Batch persistence:** `_importSheet` parses+validates every row, then persists
the valid ones with a single `repo.saveAll(validItems)` (one batched local
insert + one batched sync-mark) instead of a per-row `repo.save()` that would
fire an HTTP push per row. FK validation is map-based — the importer loads the
existing rows once into a `Map<id, entity>` and looks parents up in memory
(no per-row `getById`); newly validated rows are added to the map so later
rows in the same sheet resolve against them. `saveAll` is all-or-nothing (Drift
`insertAll` is one transaction): a mid-batch failure returns
`importedCount: 0` rather than leaving a partial import behind.

## Export (Excel + PDF)

| Service | Output |
|---------|--------|
| `ExcelExportService` | `.xlsx` with one sheet per entity type |
| `PdfExportService` | Statistics summary + per-section page builders |
| `PedigreePdfBuilder` (+ chart/table/constants) | Genealogy pedigree PDF with chart + table |

Excel `exportAll` writes SIX sheets — birds, breeding pairs, incubations, eggs,
chicks, health records — symmetric with the importer's supported sheets (health
was previously omitted from export while the importer could read it; incubations
were exported but never imported). Sheets share the column format with the Excel
importer, so export → edit externally → import round-trips cleanly.

## Encryption Hook

`EncryptionService` is optional but injected for both backup directions.
When present, encrypted backups gate restore behind the user's secret;
the codec is `EncryptionPayloadCodec` (envelope, version, IV).
See [[domain/encryption-service]].

## Premium Gating

Backup, full export, and PDF share are entitlement-gated through
`adServiceProvider` reward states (`isExportRewardActiveProvider`) and
premium check. Free-tier users get ad-rewarded one-shot exports; premium
users skip the ad gate. See [[domain/premium-service]].

## Anti-Patterns

1. Importing without FK validation (orphan rows, sync-blocking)
2. Skipping encryption detection — `.enc.json` extension is the signal
3. Hardcoded sheet column names (Turkish labels) — use positional indexes
4. Restoring on top of existing data without clearing (duplicates + UUID collisions)
5. Storing the encryption key in SharedPreferences (must be secure storage)

## See Also

- [[domain/encryption-service]] — payload codec, key derivation
- [[features/settings]] — backup screen + scheduler UI
- [[patterns/security]] — secure storage
- [[domain/services-index]]
