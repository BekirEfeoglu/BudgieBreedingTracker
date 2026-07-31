# Drift (Local Database)

Source: `.claude/rules/data-layer.md`, `.claude/rules/migrations.md`

## Overview

- **Package**: drift ^2.31.0 (type-safe SQLite ORM)
- **Schema version**: 30 (v30 enforces one active chick link per egg and adds the visible-calendar range index)
- **Tables**: 20
- **DAOs**: 20
- **Mappers**: 20
- **Converters**: `lib/data/local/database/converters/enum_converters.dart`

## Key Locations

```
lib/data/local/database/
├── app_database.dart       DriftDatabase + schemaVersion + migration
├── tables/                 20 table definitions
├── daos/                   20 DAO classes
├── mappers/                20 Mapper classes (Drift ↔ Freezed model)
└── converters/
    └── enum_converters.dart
```

## Import Rule

**Always import tables directly** from the table file — never via `app_database.dart`:

```dart
// CORRECT
import 'package:budgie/data/local/database/tables/birds_table.dart';

// WRONG
import 'package:budgie/data/local/database/app_database.dart'; // in DAO
```

## Circular FK References (drift_dev codegen crash)

A **bidirectional** typed FK between two tables makes their table files import each
other AND forms a reference cycle in drift_dev's module graph. drift_dev 2.31
intermittently crashes on it with `Circular error when deserializing drift
modules` — build-order dependent, so it fails some CI runners and not others, and
codegen retries do NOT clear it (a clean retry re-hits the same analysis order).
This surfaced as an Xcode Cloud post-clone failure (`build_runner` exit 1, ~33s)
even after 8 retries; only a source fix resolves it.

**Rule:** never close a `.references()` cycle. Keep the primary child→parent FK as
`.references()`; declare the *back-reference* with a raw `.customConstraint(...)`
and drop the offending import so no typed module edge is created.

```dart
// clutches.incubationId keeps the typed reference (primary child→parent FK):
TextColumn get incubationId => text().nullable().references(IncubationsTable, #id)();

// incubations.clutchId would CLOSE the cycle → break it with a raw constraint
// (no import of clutches_table.dart, no typed edge). Identical generated SQL:
TextColumn get clutchId =>
    text().nullable().customConstraint('NULL REFERENCES clutches (id)')();
```

`.customConstraint()` emits the FK string verbatim into the column's SQL and is
opaque to the module graph — the `REFERENCES clutches (id)` constraint is
preserved 1:1 (verify in `app_database.g.dart`), so there is no schema change and
no version bump. Prefer `.customConstraint()` over dropping the FK entirely; the
`NULL ` prefix marks the column nullable per Drift's documented pattern. See
[[log]] 2026-07-09 for the clutches↔incubations fix.

## Query Patterns

```dart
// Enum filter — use .equalsValue(), NOT .equals()
select(birds)..where((t) => t.gender.equalsValue(BirdGender.male));

// Stream for reactive UI
select(birds).watch()

// Batch insert (idempotent)
await db.batch((batch) {
  batch.insertAll(birdsTable, entries,
    mode: InsertMode.insertOrReplace);
});
```

## Migration Pattern

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 25) {
      await m.addColumn(birds, birds.ringNumber);
    }
    // Sequential, no skipping
  },
);
```

**Version bump checklist**:
- [ ] Increment `schemaVersion` sequentially (never skip)
- [ ] Add `onUpgrade` handler
- [ ] Provide `DEFAULT` value for `NOT NULL` columns
- [ ] Add index if column is used in filters
- [ ] Test: fresh DB + upgrade from previous version
- [ ] Regenerate `.g.dart` with `dart run build_runner build`

### Shared index helpers must guard missing tables, not just missing columns

`_createPerformanceIndexes` (`app_database_indexes.dart`) is called from several
historical upgrade steps, so it runs against schemas far older than HEAD.
`CREATE INDEX IF NOT EXISTS` guards only the **index name** — a missing target
column or table still throws and aborts the entire `onUpgrade` transaction,
which to the user means the database never opens at all.

Two guards live in `app_database_migrations.dart`:
`_tableHasColumn` (`PRAGMA table_info`) and `_tableExists`
(`sqlite_master WHERE type='table'`, added 2026-07-25).

Canonical incident (2026-07-25): the helper created
`idx_conflict_history_user_table_record` unconditionally, but it is also invoked
from the historical **v8→v9** step while `conflict_history` is only created in
**v15→v16**. Every device upgrading from schema **≤8** aborted with
`no such table: conflict_history`. Fix: `_tableExists` guard in the helper plus
creating the index inside `_migrateV15ToV16` so v16+ upgraders still get it.
Regression: `test/data/local/database/app_database_legacy_upgrade_test.dart`
(upgrades from v8 and v21). See `.claude/rules/migrations.md`
§ Ortak index helper'ları and Anti-Pattern 11.

## Performance

- Indexed columns for frequently filtered fields (gender, species, breeding pair ID)
- Use `.watch()` streams for reactive UI — avoid polling
- Batch inserts/updates in transactions
- Profile with `Stopwatch()..start()` + `AppLogger.debug('perf query: ${sw.elapsed}')` (single message arg — no tag param)

## Code Generation

After modifying any table or DAO:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## See Also

- [[data-layer/tables-catalog]] — list of all 20 tables
- [[data-layer/migrations]] — migration workflow
- [[data-layer/repositories]] — how DAOs are used
