import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/profiles_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/profile_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';

part 'profiles_dao.g.dart';

@DriftAccessor(tables: [ProfilesTable])
class ProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$ProfilesDaoMixin {
  ProfilesDao(super.db);

  /// Watches a single profile by id.
  Stream<Profile?> watchProfile(String id) {
    return (select(profilesTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  /// Gets a single profile by id.
  Future<Profile?> getById(String id) async {
    final row = await (select(
      profilesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Inserts or updates a profile.
  Future<void> upsert(Profile profile) {
    return into(profilesTable).insertOnConflictUpdate(profile.toCompanion());
  }

  /// Permanently deletes a profile.
  Future<int> hardDelete(String id) {
    return (delete(profilesTable)..where((t) => t.id.equals(id))).go();
  }
}
