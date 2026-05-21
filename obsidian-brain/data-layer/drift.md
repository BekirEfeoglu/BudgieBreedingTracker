# Drift (Local Database)

Source: `.claude/rules/data-layer.md`, `.claude/rules/migrations.md`

## Overview

- **Package**: drift ^2.31.0 (type-safe SQLite ORM)
- **Schema version**: 24 (in `app_database.dart`)
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
    if (from < 24) {
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

## Performance

- Indexed columns for frequently filtered fields (gender, species, breeding pair ID)
- Use `.watch()` streams for reactive UI — avoid polling
- Batch inserts/updates in transactions
- Profile with `Stopwatch()..start()` + `AppLogger.debug('perf', '...')`

## Code Generation

After modifying any table or DAO:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## See Also

- [[data-layer/tables-catalog]] — list of all 20 tables
- [[data-layer/migrations]] — migration workflow
- [[data-layer/repositories]] — how DAOs are used
