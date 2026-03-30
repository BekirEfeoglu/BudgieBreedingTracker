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
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
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
import 'package:budgie_breeding_tracker/data/local/database/tables/conflict_history_table.dart';

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
import 'package:budgie_breeding_tracker/data/local/database/daos/conflict_history_dao.dart';

// Converters
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

part 'app_database.g.dart';
part 'app_database_migrations.dart';
part 'app_database_indexes.dart';

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
    ConflictHistoryTable,
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
    ConflictHistoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with a custom query executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 19;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createPerformanceIndexes(this);
    },
    onUpgrade: (m, from, to) async {
      // Run migrations sequentially from the old version to the new one.
      for (var i = from + 1; i <= to; i++) {
        switch (i) {
          case 2:
            await _migrateV1ToV2(this, m);
          case 3:
            await _migrateV2ToV3(this, m);
          case 4:
            await _migrateV3ToV4(this, m);
          case 5:
            await _migrateV4ToV5(this, m);
          case 6:
            await _migrateV5ToV6(this, m);
          case 7:
            await _migrateV6ToV7(this, m);
          case 8:
            await _migrateV7ToV8(this, m);
          case 9:
            await _migrateV8ToV9(this, m);
          case 10:
            await _migrateV9ToV10(this, m);
          case 11:
            await _migrateV10ToV11(this, m);
          case 12:
            await _migrateV11ToV12(this, m);
          case 13:
            await _migrateV12ToV13(this, m);
          case 14:
            await _migrateV13ToV14(this, m);
          case 15:
            await _migrateV14ToV15(this, m);
          case 16:
            await _migrateV15ToV16(this, m);
          case 17:
            await _migrateV16ToV17(this, m);
          case 18:
            await _migrateV17ToV18(this, m);
          case 19:
            await _migrateV18ToV19(this, m);
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
      await customStatement('DELETE FROM conflict_history WHERE user_id = ?', [
        userId,
      ]);
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
