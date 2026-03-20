import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/notification_settings_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/notification_settings_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';

part 'notification_settings_dao.g.dart';

@DriftAccessor(tables: [NotificationSettingsTable])
class NotificationSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationSettingsDaoMixin {
  NotificationSettingsDao(super.db);

  Stream<NotificationSettings?> watchByUser(String userId) {
    return (select(notificationSettingsTable)
          ..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<NotificationSettings?> getByUser(String userId) async {
    final row = await (select(
      notificationSettingsTable,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    return row?.toModel();
  }

  Future<void> upsert(NotificationSettings model) {
    return into(
      notificationSettingsTable,
    ).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> hardDelete(String id) {
    return (delete(
      notificationSettingsTable,
    )..where((t) => t.id.equals(id))).go();
  }
}
