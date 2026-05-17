part of 'app_database.dart';

// ---------------------------------------------------------------------------
// Performance indexes — called from both onCreate and schema upgrades.
// Uses IF NOT EXISTS so it's safe to call idempotently.
// ---------------------------------------------------------------------------

/// Creates performance indexes on all tables.
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

  // --- Composite (user_id, gender, is_deleted) for statistics aggregation ---
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_birds_user_gender_deleted '
    'ON birds (user_id, gender, is_deleted)',
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

  // --- Composite (user_id, status) for incubations active count queries ---
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_incubations_user_status '
    'ON incubations (user_id, status)',
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
    'CREATE INDEX IF NOT EXISTS idx_notification_schedules_user_scheduled '
    'ON notification_schedules (user_id, scheduled_at)',
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
    'CREATE INDEX IF NOT EXISTS idx_eggs_incubation_status_deleted '
    'ON eggs (incubation_id, status, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_chicks_egg '
    'ON chicks (egg_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_chicks_egg_deleted '
    'ON chicks (egg_id, is_deleted)',
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
    'CREATE INDEX IF NOT EXISTS idx_health_records_bird_deleted '
    'ON health_records (bird_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_growth_measurements_chick '
    'ON growth_measurements (chick_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_growth_measurements_chick_date '
    'ON growth_measurements (chick_id, measurement_date)',
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
    'CREATE INDEX IF NOT EXISTS idx_photos_entity_user '
    'ON photos (entity_id, entity_type, user_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_incubations_breeding_pair '
    'ON incubations (breeding_pair_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_incubations_breeding_pair_status '
    'ON incubations (breeding_pair_id, status)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_clutches_breeding '
    'ON clutches (breeding_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_clutches_breeding_deleted '
    'ON clutches (breeding_id, is_deleted)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_events_bird '
    'ON events (bird_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_events_bird_deleted '
    'ON events (bird_id, is_deleted)',
  );

  // --- Notification badge/count queries ---
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_notifications_user_read '
    'ON notifications (user_id, read)',
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
