# Data I/O: Backup, Import, Export

Source: `.claude/rules/data-io.md` (primary — backup formats, device/portable encryption, restore preview, Excel i18n headers, PDF pedigree builders, free vs premium gating)

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
`BackupRestorer` (deserialize). Automatic backups can use device-bound
`EncryptionService` (`.enc.json`). Manual portable backups use
`PortableBackupCodec` (`.portable.enc.json`): PBKDF2-HMAC-SHA256 100K,
per-file random salt/IV, AES-256-CBC and encrypt-then-HMAC-SHA256. KDF work runs
off the UI isolate; the password is never stored or logged.

| Method | Purpose |
|--------|---------|
| `createBackup(userId, {encrypt, password})` | Full snapshot; password produces a cross-device portable encrypted file |
| `previewBackup(userId, filePath, {password})` | Read/decrypt/validate only; returns date and per-entity counts with zero repository writes |
| `restoreBackup(userId, filePath, {password})` | Merge-upserts rows by id; rejects other users, newer versions, wrong password and tamper |
| `uploadBackup(userId, file)` | Push to `backups` Supabase Storage bucket |
| `listBackups(userId)` | Remote backup index, user-scoped |

`BackupScheduler` runs periodic local snapshots when the user opted in.
Remote bucket: `SupabaseConstants.backupsBucket`, RLS-scoped to owner.
Restore has no wipe/rename/skip strategy: preview explicitly warns that matching
IDs are updated, unrelated existing rows remain, and there is no automatic undo.

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

`EncryptionService` remains the runtime device-key path for `.enc.json`.
`PortableBackupCodec` is separate and derives independent encryption/MAC keys
from the user password. Its versioned JSON envelope is authenticated before
decrypt; wrong password and tamper share the localized graceful error.
See [[domain/encryption-service]].

## Premium Gating

Manual portable backup and restore are free (data ownership). Excel/PDF export
and Excel import are entitlement/reward gated. Auto-scheduled device-key backup
is premium. See [[domain/premium-service]].

## Anti-Patterns

1. Importing without FK validation (orphan rows, sync-blocking)
2. Detecting only by extension — portable envelope is content-detected and versioned
3. Hardcoded sheet column names (Turkish labels) — use positional indexes
4. Restoring without the non-mutating preview/merge warning
5. Storing the encryption key in SharedPreferences (must be secure storage)

## See Also

- [[domain/encryption-service]] — payload codec, key derivation
- [[features/settings]] — backup screen + scheduler UI
- [[patterns/security]] — secure storage
- [[domain/services-index]]
