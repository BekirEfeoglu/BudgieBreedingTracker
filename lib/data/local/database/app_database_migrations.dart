part of 'app_database.dart';

// ---------------------------------------------------------------------------
// Migration helpers — one per schema version bump.
// All functions receive a [Migrator] and the [AppDatabase] instance (for
// [customStatement] calls). They are private to the library via the `part`
// directive.
// ---------------------------------------------------------------------------

/// Migration v1 -> v2: placeholder for future schema changes.
Future<void> _migrateV1ToV2(AppDatabase db, Migrator m) async {
  // Example:
  // await m.addColumn(db.birdsTable, db.birdsTable.someNewColumn);
}

/// Migration v2 -> v3: Add 6 new tables.
Future<void> _migrateV2ToV3(AppDatabase db, Migrator m) async {
  await m.createTable(db.clutchesTable);
  await m.createTable(db.nestsTable);
  await m.createTable(db.photosTable);
  await m.createTable(db.userPreferencesTable);
  await m.createTable(db.eventRemindersTable);
  await m.createTable(db.notificationSchedulesTable);
}

/// Migration v3 -> v4: Update existing 'laid' eggs to 'incubating'
/// for eggs that belong to an incubation.
Future<void> _migrateV3ToV4(AppDatabase db, Migrator m) async {
  await db.customStatement(
    "UPDATE eggs SET status = 'incubating' "
    "WHERE status = 'laid' AND incubation_id IS NOT NULL AND is_deleted = 0",
  );
}

/// Migration v4 -> v5: Add color_mutation column to birds table.
Future<void> _migrateV4ToV5(AppDatabase db, Migrator m) async {
  await m.addColumn(db.birdsTable, db.birdsTable.colorMutation);
}

/// Migration v5 -> v6: Add userId, isDeleted, updatedAt to event_reminders.
Future<void> _migrateV5ToV6(AppDatabase db, Migrator m) async {
  await db.customStatement(
    "ALTER TABLE event_reminders ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
  );
  await db.customStatement(
    'ALTER TABLE event_reminders ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
  );
  await db.customStatement(
    'ALTER TABLE event_reminders ADD COLUMN updated_at TEXT',
  );
}

/// Migration v6 -> v7: Add mutations and genotype_info to birds.
Future<void> _migrateV6ToV7(AppDatabase db, Migrator m) async {
  await m.addColumn(db.birdsTable, db.birdsTable.mutations);
  await m.addColumn(db.birdsTable, db.birdsTable.genotypeInfo);
}

/// Migration v7 -> v8: Add genetics_history table.
Future<void> _migrateV7ToV8(AppDatabase db, Migrator m) async {
  await m.createTable(db.geneticsHistoryTable);
}

/// Migration v8 -> v9: Add performance indexes to all tables.
Future<void> _migrateV8ToV9(AppDatabase db, Migrator m) async {
  await _createPerformanceIndexes(db);
}

/// Migration v9 -> v10: Add composite index for nests status queries.
Future<void> _migrateV9ToV10(AppDatabase db, Migrator m) async {
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_nests_user_status_deleted '
    'ON nests (user_id, status, is_deleted)',
  );
}

/// Migration v10 -> v11: Add composite index for breeding_pairs status queries.
Future<void> _migrateV10ToV11(AppDatabase db, Migrator m) async {
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_user_status_deleted '
    'ON breeding_pairs (user_id, status, is_deleted)',
  );
}

/// Migration v11 -> v12: Add UNIQUE constraint on sync_metadata(table_name, record_id).
///
/// Prevents duplicate sync entries for the same entity.
/// First removes existing duplicates, then creates the UNIQUE index.
Future<void> _migrateV11ToV12(AppDatabase db, Migrator m) async {
  await db.customStatement(
    'DELETE FROM sync_metadata WHERE rowid NOT IN '
    '(SELECT MIN(rowid) FROM sync_metadata GROUP BY table_name, record_id)',
  );
  await db.customStatement(
    'DROP INDEX IF EXISTS idx_sync_metadata_table_record',
  );
  await db.customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_metadata_table_record_unique '
    'ON sync_metadata(table_name, record_id)',
  );
}

/// Migration v12 -> v13: Add cleanupDaysOld column to notification_settings.
Future<void> _migrateV12ToV13(AppDatabase db, Migrator m) async {
  await m.addColumn(
    db.notificationSettingsTable,
    db.notificationSettingsTable.cleanupDaysOld,
  );
}

/// Migration v13 -> v14: normalize Species enum aliases.
///
/// Replaces Turkish alias values (muhabbet, kanarya, ispinoz) with their
/// canonical English equivalents (budgie, canary, finch).
Future<void> _migrateV13ToV14(AppDatabase db, Migrator m) async {
  await db.customStatement(
    "UPDATE birds SET species = 'budgie' WHERE species = 'muhabbet'",
  );
  await db.customStatement(
    "UPDATE birds SET species = 'canary' WHERE species = 'kanarya'",
  );
  await db.customStatement(
    "UPDATE birds SET species = 'finch' WHERE species = 'ispinoz'",
  );
}

/// Migration v14 -> v15: Add banding columns to chicks and chickId to events.
Future<void> _migrateV14ToV15(AppDatabase db, Migrator m) async {
  await db.customStatement(
    'ALTER TABLE chicks ADD COLUMN banding_day INTEGER NOT NULL DEFAULT 10',
  );
  await db.customStatement('ALTER TABLE chicks ADD COLUMN banding_date TEXT');
  await db.customStatement('ALTER TABLE events ADD COLUMN chick_id TEXT');
}

/// Migration v15 -> v16: Add conflict_history table for sync conflict tracking.
Future<void> _migrateV15ToV16(AppDatabase db, Migrator m) async {
  await m.createTable(db.conflictHistoryTable);
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_conflict_history_user_created '
    'ON conflict_history (user_id, created_at)',
  );
}

/// Migration v16 -> v17: Add bandingEnabled column to notification_settings
/// and composite index on notification_schedules for stale cleanup queries.
Future<void> _migrateV16ToV17(AppDatabase db, Migrator m) async {
  await m.addColumn(
    db.notificationSettingsTable,
    db.notificationSettingsTable.bandingEnabled,
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_notification_schedules_user_scheduled '
    'ON notification_schedules (user_id, scheduled_at)',
  );
}

/// Migration v17 -> v18: Add species to incubations and backfill from birds.
Future<void> _migrateV17ToV18(AppDatabase db, Migrator m) async {
  final hasSpeciesColumn = await _tableHasColumn(db, 'incubations', 'species');
  if (!hasSpeciesColumn) {
    await m.addColumn(db.incubationsTable, db.incubationsTable.species);
  }
  await db.customStatement('''
    UPDATE incubations
    SET species = COALESCE(
      (
        SELECT birds.species
        FROM breeding_pairs
        JOIN birds ON birds.id = breeding_pairs.male_id
        WHERE breeding_pairs.id = incubations.breeding_pair_id
      ),
      'budgie'
    )
    WHERE species = 'budgie'
  ''');
}

/// Migration v18 -> v19: Normalize missing incubation species to unknown.
///
/// Existing rows already store an explicit species value. This migration keeps
/// data intact and only corrects truly missing/empty values.
Future<void> _migrateV18ToV19(AppDatabase db, Migrator m) async {
  await db.customStatement(
    "UPDATE incubations SET species = 'unknown' "
    "WHERE species IS NULL OR TRIM(species) = ''",
  );
}

/// Migration v19 -> v20: Add calculation_version column to genetics_history.
///
/// Tracks the calculation engine version at the time of save, enabling
/// stale-entry detection when recombination constants or allele resolver
/// logic changes. Null means "saved before versioning was introduced".
Future<void> _migrateV19ToV20(AppDatabase db, Migrator m) async {
  final hasColumn = await _tableHasColumn(
    db,
    'genetics_history',
    'calculation_version',
  );
  if (!hasColumn) {
    await db.customStatement(
      'ALTER TABLE genetics_history ADD COLUMN calculation_version INTEGER',
    );
  }
}

Future<void> _migrateV20ToV21(AppDatabase db, Migrator m) async {
  final hasColumn = await _tableHasColumn(db, 'profiles', 'grace_period_until');
  if (!hasColumn) {
    await db.customStatement(
      'ALTER TABLE profiles ADD COLUMN grace_period_until INTEGER',
    );
  }
}

/// Checks whether [tableName] has a column named [columnName] via PRAGMA.
///
/// Internal migration helper only — [tableName] and [columnName] must be
/// hardcoded string literals, never user input.
Future<bool> _tableHasColumn(
  AppDatabase db,
  String tableName,
  String columnName,
) async {
  assertSafeIdentifier(tableName);
  assertSafeIdentifier(columnName);
  final result = await db.customSelect("PRAGMA table_info('$tableName')").get();
  return result.any((row) => row.data['name'] == columnName);
}

// Performance indexes are in app_database_indexes.dart (part file)
