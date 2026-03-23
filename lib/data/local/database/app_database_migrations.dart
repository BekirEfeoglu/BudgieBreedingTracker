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

// ---------------------------------------------------------------------------
// Performance indexes — called from both onCreate and onUpgrade.
// ---------------------------------------------------------------------------

/// Creates performance indexes on all tables.
///
/// Uses IF NOT EXISTS so it's safe to call from both onCreate and onUpgrade.
Future<void> _createPerformanceIndexes(AppDatabase db) async {
  // --- Composite (user_id, is_deleted) indexes for soft-delete tables ---
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_birds_user_deleted '
    'ON birds (user_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_eggs_user_deleted '
    'ON eggs (user_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_chicks_user_deleted '
    'ON chicks (user_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_user_deleted '
    'ON breeding_pairs (user_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_events_user_deleted '
    'ON events (user_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_health_records_user_deleted '
    'ON health_records (user_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_clutches_user_deleted '
    'ON clutches (user_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_nests_user_deleted '
    'ON nests (user_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_event_reminders_user_deleted '
    'ON event_reminders (user_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_genetics_history_user_deleted '
    'ON genetics_history (user_id, is_deleted)',
  );

  // --- Composite (user_id, status, is_deleted) for filtered status queries ---
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_nests_user_status_deleted '
    'ON nests (user_id, status, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_user_status_deleted '
    'ON breeding_pairs (user_id, status, is_deleted)',
  );

  // --- userId-only indexes for tables without is_deleted ---
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_incubations_user '
    'ON incubations (user_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_growth_measurements_user '
    'ON growth_measurements (user_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_notifications_user '
    'ON notifications (user_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_notification_settings_user '
    'ON notification_settings (user_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_notification_schedules_user '
    'ON notification_schedules (user_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_user_preferences_user '
    'ON user_preferences (user_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_photos_user '
    'ON photos (user_id)',
  );

  // --- FK indexes for join/lookup performance ---
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_eggs_clutch '
    'ON eggs (clutch_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_eggs_incubation '
    'ON eggs (incubation_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_chicks_egg '
    'ON chicks (egg_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_male '
    'ON breeding_pairs (male_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_female '
    'ON breeding_pairs (female_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_health_records_bird '
    'ON health_records (bird_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_growth_measurements_chick '
    'ON growth_measurements (chick_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_event_reminders_event '
    'ON event_reminders (event_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_photos_entity '
    'ON photos (entity_id, entity_type)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_incubations_breeding_pair '
    'ON incubations (breeding_pair_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_clutches_breeding '
    'ON clutches (breeding_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_events_bird '
    'ON events (bird_id)',
  );

  // --- Sync metadata indexes (critical for sync performance) ---
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sync_metadata_user_status '
    'ON sync_metadata (user_id, status)',
  );
  await db.customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_metadata_table_record_unique '
    'ON sync_metadata (table_name, record_id)',
  );
}
