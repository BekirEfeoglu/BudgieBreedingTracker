import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Enums
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/reminder_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

import 'package:budgie_breeding_tracker/data/local/database/tables/birds_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/eggs_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/chicks_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/incubations_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/breeding_pairs_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/profiles_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/events_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/health_records_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/notifications_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/notification_settings_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/growth_measurements_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/sync_metadata_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/clutches_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/nests_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/photos_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/user_preferences_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/event_reminders_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/notification_schedules_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/genetics_history_table.dart';

import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/profiles_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/events_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/health_records_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notifications_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/growth_measurements_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/nests_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/photos_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/user_preferences_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/event_reminders_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_schedules_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_settings_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/genetics_history_dao.dart';

// Converters
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    BirdsTable,
    EggsTable,
    ChicksTable,
    IncubationsTable,
    BreedingPairsTable,
    ProfilesTable,
    EventsTable,
    HealthRecordsTable,
    NotificationsTable,
    NotificationSettingsTable,
    GrowthMeasurementsTable,
    SyncMetadataTable,
    ClutchesTable,
    NestsTable,
    PhotosTable,
    UserPreferencesTable,
    EventRemindersTable,
    NotificationSchedulesTable,
    GeneticsHistoryTable,
  ],
  daos: [
    BirdsDao,
    EggsDao,
    ChicksDao,
    IncubationsDao,
    BreedingPairsDao,
    ProfilesDao,
    EventsDao,
    HealthRecordsDao,
    NotificationsDao,
    NotificationSettingsDao,
    GrowthMeasurementsDao,
    SyncMetadataDao,
    ClutchesDao,
    NestsDao,
    PhotosDao,
    UserPreferencesDao,
    EventRemindersDao,
    NotificationSchedulesDao,
    GeneticsHistoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with a custom query executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createPerformanceIndexes();
    },
    onUpgrade: (m, from, to) async {
      // Run migrations sequentially from the old version to the new one.
      for (var i = from + 1; i <= to; i++) {
        switch (i) {
          case 2:
            await _migrateV1ToV2(m);
          case 3:
            await _migrateV2ToV3(m);
          case 4:
            await _migrateV3ToV4(m);
          case 5:
            await _migrateV4ToV5(m);
          case 6:
            await _migrateV5ToV6(m);
          case 7:
            await _migrateV6ToV7(m);
          case 8:
            await _migrateV7ToV8(m);
          case 9:
            await _migrateV8ToV9(m);
          case 10:
            await _migrateV9ToV10(m);
          case 11:
            await _migrateV10ToV11(m);
          case 12:
            await _migrateV11ToV12(m);
          case 13:
            await _migrateV12ToV13(m);
          case 14:
            await _migrateV13ToV14(m);
        }
      }
    },
    beforeOpen: (details) async {
      // Enable foreign keys for every connection.
      await customStatement('PRAGMA foreign_keys = ON');

      // Quick integrity check to detect early corruption.
      final result = await customSelect('PRAGMA integrity_check').get();
      if (result.isNotEmpty) {
        final status = result.first.data.values.first as String?;
        if (status != null && status != 'ok') {
          AppLogger.error('[DB] Integrity check failed: $status');
        }
      }
    },
  );

  /// Migration v1 -> v2: placeholder for future schema changes.
  ///
  /// Add concrete ALTER TABLE / CREATE TABLE statements here
  /// when new columns or tables are introduced.
  Future<void> _migrateV1ToV2(Migrator m) async {
    // Example:
    // await m.addColumn(birdsTable, birdsTable.someNewColumn);
    // await m.createTable(someNewTable);
  }

  /// Migration v2 -> v3: Add 6 new tables.
  Future<void> _migrateV2ToV3(Migrator m) async {
    await m.createTable(clutchesTable);
    await m.createTable(nestsTable);
    await m.createTable(photosTable);
    await m.createTable(userPreferencesTable);
    await m.createTable(eventRemindersTable);
    await m.createTable(notificationSchedulesTable);
  }

  /// Migration v3 -> v4: Update existing 'laid' eggs to 'incubating'
  /// for eggs that belong to an incubation.
  Future<void> _migrateV3ToV4(Migrator m) async {
    await customStatement(
      "UPDATE eggs SET status = 'incubating' "
      "WHERE status = 'laid' AND incubation_id IS NOT NULL AND is_deleted = 0",
    );
  }

  /// Migration v4 -> v5: Add color_mutation column to birds table.
  Future<void> _migrateV4ToV5(Migrator m) async {
    await m.addColumn(birdsTable, birdsTable.colorMutation);
  }

  /// Migration v5 -> v6: Add userId, isDeleted, updatedAt to event_reminders.
  Future<void> _migrateV5ToV6(Migrator m) async {
    // EventReminders: add userId, isDeleted, updatedAt columns
    await customStatement(
      "ALTER TABLE event_reminders ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
    );
    await customStatement(
      'ALTER TABLE event_reminders ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'ALTER TABLE event_reminders ADD COLUMN updated_at TEXT',
    );
  }

  /// Migration v6 -> v7: Add mutations and genotype_info to birds.
  Future<void> _migrateV6ToV7(Migrator m) async {
    await m.addColumn(birdsTable, birdsTable.mutations);
    await m.addColumn(birdsTable, birdsTable.genotypeInfo);
  }

  /// Migration v7 -> v8: Add genetics_history table.
  Future<void> _migrateV7ToV8(Migrator m) async {
    await m.createTable(geneticsHistoryTable);
  }

  /// Migration v8 -> v9: Add performance indexes to all tables.
  Future<void> _migrateV8ToV9(Migrator m) async {
    await _createPerformanceIndexes();
  }

  /// Migration v9 -> v10: Add composite index for nests status queries.
  Future<void> _migrateV9ToV10(Migrator m) async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_nests_user_status_deleted '
      'ON nests (user_id, status, is_deleted)',
    );
  }

  /// Migration v10 -> v11: Add composite index for breeding_pairs status queries.
  Future<void> _migrateV10ToV11(Migrator m) async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_user_status_deleted '
      'ON breeding_pairs (user_id, status, is_deleted)',
    );
  }

  /// Migration v11 -> v12: Add UNIQUE constraint on sync_metadata(table_name, record_id).
  ///
  /// Prevents duplicate sync entries for the same entity.
  /// First removes existing duplicates, then creates the UNIQUE index.
  Future<void> _migrateV11ToV12(Migrator m) async {
    // Remove duplicate sync_metadata rows (keep the earliest by rowid)
    await customStatement(
      'DELETE FROM sync_metadata WHERE rowid NOT IN '
      '(SELECT MIN(rowid) FROM sync_metadata GROUP BY table_name, record_id)',
    );
    // Drop the old non-unique index (the UNIQUE index covers the same columns)
    await customStatement(
      'DROP INDEX IF EXISTS idx_sync_metadata_table_record',
    );
    // Create UNIQUE index
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_metadata_table_record_unique '
      'ON sync_metadata(table_name, record_id)',
    );
  }

  /// Migration v12 -> v13: Add cleanupDaysOld column to notification_settings.
  Future<void> _migrateV12ToV13(Migrator m) async {
    await m.addColumn(
      notificationSettingsTable,
      notificationSettingsTable.cleanupDaysOld,
    );
  }

  /// Migration v13 -> v14: normalize Species enum aliases.
  ///
  /// Replaces Turkish alias values (muhabbet, kanarya, ispinoz) with their
  /// canonical English equivalents (budgie, canary, finch).
  Future<void> _migrateV13ToV14(Migrator m) async {
    await customStatement(
      "UPDATE birds SET species = 'budgie' WHERE species = 'muhabbet'",
    );
    await customStatement(
      "UPDATE birds SET species = 'canary' WHERE species = 'kanarya'",
    );
    await customStatement(
      "UPDATE birds SET species = 'finch' WHERE species = 'ispinoz'",
    );
  }

  /// Creates performance indexes on all tables.
  ///
  /// Uses IF NOT EXISTS so it's safe to call from both onCreate and onUpgrade.
  /// Composite index on (user_id, is_deleted) covers the most common query
  /// pattern. FK columns are indexed for join/lookup performance.
  Future<void> _createPerformanceIndexes() async {
    // --- Composite (user_id, is_deleted) indexes for soft-delete tables ---
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_birds_user_deleted '
      'ON birds (user_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_eggs_user_deleted '
      'ON eggs (user_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_chicks_user_deleted '
      'ON chicks (user_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_user_deleted '
      'ON breeding_pairs (user_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_events_user_deleted '
      'ON events (user_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_health_records_user_deleted '
      'ON health_records (user_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_clutches_user_deleted '
      'ON clutches (user_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_nests_user_deleted '
      'ON nests (user_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_event_reminders_user_deleted '
      'ON event_reminders (user_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_genetics_history_user_deleted '
      'ON genetics_history (user_id, is_deleted)',
    );

    // --- Composite (user_id, status, is_deleted) for filtered status queries ---
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_nests_user_status_deleted '
      'ON nests (user_id, status, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_user_status_deleted '
      'ON breeding_pairs (user_id, status, is_deleted)',
    );

    // --- userId-only indexes for tables without is_deleted ---
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_incubations_user '
      'ON incubations (user_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_growth_measurements_user '
      'ON growth_measurements (user_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_notifications_user '
      'ON notifications (user_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_notification_settings_user '
      'ON notification_settings (user_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_notification_schedules_user '
      'ON notification_schedules (user_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_user_preferences_user '
      'ON user_preferences (user_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_photos_user '
      'ON photos (user_id)',
    );

    // --- FK indexes for join/lookup performance ---
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_eggs_clutch '
      'ON eggs (clutch_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_eggs_incubation '
      'ON eggs (incubation_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_chicks_egg '
      'ON chicks (egg_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_male '
      'ON breeding_pairs (male_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_breeding_pairs_female '
      'ON breeding_pairs (female_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_health_records_bird '
      'ON health_records (bird_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_growth_measurements_chick '
      'ON growth_measurements (chick_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_event_reminders_event '
      'ON event_reminders (event_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_photos_entity '
      'ON photos (entity_id, entity_type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_incubations_breeding_pair '
      'ON incubations (breeding_pair_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_clutches_breeding '
      'ON clutches (breeding_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_events_bird '
      'ON events (bird_id)',
    );

    // --- Sync metadata indexes (critical for sync performance) ---
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_metadata_user_status '
      'ON sync_metadata (user_id, status)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_metadata_table_record_unique '
      'ON sync_metadata (table_name, record_id)',
    );
  }

  /// Deletes ALL data belonging to [userId] from every table.
  ///
  /// Uses a transaction so the wipe is atomic (all-or-nothing).
  /// Tables are deleted child-first to respect FK constraints.
  Future<void> clearAllUserData(String userId) async {
    await transaction(() async {
      // Layer 7 – deepest children
      await customStatement(
        'DELETE FROM growth_measurements WHERE user_id = ?',
        [userId],
      );
      await customStatement('DELETE FROM event_reminders WHERE user_id = ?', [
        userId,
      ]);
      // Layer 6 – leaf entities
      await customStatement('DELETE FROM health_records WHERE user_id = ?', [
        userId,
      ]);
      await customStatement('DELETE FROM photos WHERE user_id = ?', [userId]);
      await customStatement('DELETE FROM notifications WHERE user_id = ?', [
        userId,
      ]);
      await customStatement(
        'DELETE FROM notification_settings WHERE user_id = ?',
        [userId],
      );
      await customStatement(
        'DELETE FROM notification_schedules WHERE user_id = ?',
        [userId],
      );
      await customStatement('DELETE FROM events WHERE user_id = ?', [userId]);
      // Layer 5
      await customStatement('DELETE FROM chicks WHERE user_id = ?', [userId]);
      // Layer 4
      await customStatement('DELETE FROM eggs WHERE user_id = ?', [userId]);
      // Layer 3
      await customStatement('DELETE FROM incubations WHERE user_id = ?', [
        userId,
      ]);
      await customStatement('DELETE FROM clutches WHERE user_id = ?', [userId]);
      // Layer 2
      await customStatement('DELETE FROM breeding_pairs WHERE user_id = ?', [
        userId,
      ]);
      // Layer 1
      await customStatement('DELETE FROM birds WHERE user_id = ?', [userId]);
      await customStatement('DELETE FROM nests WHERE user_id = ?', [userId]);
      // Local-only entities
      await customStatement('DELETE FROM genetics_history WHERE user_id = ?', [
        userId,
      ]);
      await customStatement('DELETE FROM user_preferences WHERE user_id = ?', [
        userId,
      ]);
      // Sync metadata
      await customStatement('DELETE FROM sync_metadata WHERE user_id = ?', [
        userId,
      ]);
      // Profile (id = userId)
      await customStatement('DELETE FROM profiles WHERE id = ?', [userId]);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budgie_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
