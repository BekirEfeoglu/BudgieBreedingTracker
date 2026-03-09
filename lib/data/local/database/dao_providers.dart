import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/health_records_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/growth_measurements_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/events_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notifications_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_settings_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/profiles_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/nests_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/photos_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/user_preferences_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/event_reminders_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_schedules_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/genetics_history_dao.dart';

/// Riverpod providers for all Drift DAOs.
///
/// Each provider extracts its DAO from the shared [AppDatabase] instance.

final birdsDaoProvider = Provider<BirdsDao>((ref) {
  return ref.watch(appDatabaseProvider).birdsDao;
});

final eggsDaoProvider = Provider<EggsDao>((ref) {
  return ref.watch(appDatabaseProvider).eggsDao;
});

final chicksDaoProvider = Provider<ChicksDao>((ref) {
  return ref.watch(appDatabaseProvider).chicksDao;
});

final incubationsDaoProvider = Provider<IncubationsDao>((ref) {
  return ref.watch(appDatabaseProvider).incubationsDao;
});

final breedingPairsDaoProvider = Provider<BreedingPairsDao>((ref) {
  return ref.watch(appDatabaseProvider).breedingPairsDao;
});

final healthRecordsDaoProvider = Provider<HealthRecordsDao>((ref) {
  return ref.watch(appDatabaseProvider).healthRecordsDao;
});

final growthMeasurementsDaoProvider = Provider<GrowthMeasurementsDao>((ref) {
  return ref.watch(appDatabaseProvider).growthMeasurementsDao;
});

final eventsDaoProvider = Provider<EventsDao>((ref) {
  return ref.watch(appDatabaseProvider).eventsDao;
});

final notificationsDaoProvider = Provider<NotificationsDao>((ref) {
  return ref.watch(appDatabaseProvider).notificationsDao;
});

final notificationSettingsDaoProvider =
    Provider<NotificationSettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).notificationSettingsDao;
});

final profilesDaoProvider = Provider<ProfilesDao>((ref) {
  return ref.watch(appDatabaseProvider).profilesDao;
});

final syncMetadataDaoProvider = Provider<SyncMetadataDao>((ref) {
  return ref.watch(appDatabaseProvider).syncMetadataDao;
});

final clutchesDaoProvider = Provider<ClutchesDao>((ref) {
  return ref.watch(appDatabaseProvider).clutchesDao;
});

final nestsDaoProvider = Provider<NestsDao>((ref) {
  return ref.watch(appDatabaseProvider).nestsDao;
});

final photosDaoProvider = Provider<PhotosDao>((ref) {
  return ref.watch(appDatabaseProvider).photosDao;
});

final userPreferencesDaoProvider = Provider<UserPreferencesDao>((ref) {
  return ref.watch(appDatabaseProvider).userPreferencesDao;
});

final eventRemindersDaoProvider = Provider<EventRemindersDao>((ref) {
  return ref.watch(appDatabaseProvider).eventRemindersDao;
});

final notificationSchedulesDaoProvider =
    Provider<NotificationSchedulesDao>((ref) {
  return ref.watch(appDatabaseProvider).notificationSchedulesDao;
});

final geneticsHistoryDaoProvider = Provider<GeneticsHistoryDao>((ref) {
  return ref.watch(appDatabaseProvider).geneticsHistoryDao;
});
