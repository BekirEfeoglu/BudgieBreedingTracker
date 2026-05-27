# Data I/O: Backup, Import, Export

Source: `.claude/rules/data-io.md` (primary — backup format, PBKDF2 backup key, Excel i18n headers, PDF pedigree builders, free vs premium gating)

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
| `restoreBackup(userId, filePath)` | Inverse — clears and rehydrates user data |
| `uploadBackup(userId, file)` | Push to `backups` Supabase Storage bucket |
| `listBackups(userId)` | Remote backup index, user-scoped |

`BackupScheduler` runs periodic local snapshots when the user opted in.
Remote bucket: `SupabaseConstants.backupsBucket`, RLS-scoped to owner.

## Import (Excel)

`DataImportService` consumes Excel workbooks shaped like the Excel export.
Per-entity importers validate FK relationships before insert (e.g.
`_validateBirdParents`, `_validateBreedingPairBirds`) so an import that
references missing rows surfaces a clear `ImportResult` error instead of
producing orphan records.

Supported sheets: birds, breeding pairs, eggs, chicks, health records.
Sheet columns are Turkish-labeled (master locale) — column order is fixed,
not name-based, to survive translation drift.

## Export (Excel + PDF)

| Service | Output |
|---------|--------|
| `ExcelExportService` | `.xlsx` with one sheet per entity type |
| `PdfExportService` | Statistics summary + per-section page builders |
| `PedigreePdfBuilder` (+ chart/table/constants) | Genealogy pedigree PDF with chart + table |

Excel sheets share the column format with the Excel importer, so
export → edit externally → import round-trips cleanly.

## Encryption Hook

`EncryptionService` is optional but injected for both backup directions.
When present, encrypted backups gate restore behind the user's secret;
the codec is `EncryptionPayloadCodec` (envelope, version, IV).
See [[domain/encryption-service]].

## Premium Gating

Backup, full export, and PDF share are entitlement-gated through
`adsServiceProvider` reward states (`isExportRewardActiveProvider`) and
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
