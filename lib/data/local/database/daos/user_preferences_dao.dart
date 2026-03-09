import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/user_preferences_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/user_preference_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/user_preference_model.dart';

part 'user_preferences_dao.g.dart';

@DriftAccessor(tables: [UserPreferencesTable])
class UserPreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$UserPreferencesDaoMixin {
  UserPreferencesDao(super.db);

  Stream<UserPreference?> watchByUser(String userId) {
    return (select(userPreferencesTable)
          ..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<UserPreference?> getByUser(String userId) async {
    final row = await (select(userPreferencesTable)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    return row?.toModel();
  }

  Future<void> upsert(UserPreference model) {
    return into(userPreferencesTable)
        .insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> hardDelete(String id) {
    return (delete(userPreferencesTable)..where((t) => t.id.equals(id))).go();
  }
}
