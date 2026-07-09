import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/health_records_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/health_record_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';

part 'health_records_dao.g.dart';

@DriftAccessor(tables: [HealthRecordsTable])
class HealthRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$HealthRecordsDaoMixin {
  HealthRecordsDao(super.db);

  /// Watches all non-deleted health records for a user, ordered by date descending.
  Stream<List<HealthRecord>> watchAll(String userId) {
    return (select(healthRecordsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Watches a single health record by id.
  Stream<HealthRecord?> watchById(String id) {
    return (select(healthRecordsTable)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  /// Gets all non-deleted health records for a user.
  Future<List<HealthRecord>> getAll(String userId) async {
    final rows = await (select(
      healthRecordsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Gets a single health record by id.
  Future<HealthRecord?> getById(String id) async {
    final row =
        await (select(healthRecordsTable)
              ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
            .getSingleOrNull();
    return row?.toModel();
  }

  Future<HealthRecord?> getByIdIncludingDeleted(String id) async {
    final row = await (select(
      healthRecordsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Inserts or updates a health record.
  Future<void> insertItem(HealthRecord model) {
    return into(healthRecordsTable).insertOnConflictUpdate(model.toCompanion());
  }

  /// Batch inserts health records.
  Future<void> insertAll(List<HealthRecord> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        healthRecordsTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  /// Updates a health record.
  Future<bool> updateItem(HealthRecord model) {
    return update(healthRecordsTable).replace(model.toCompanion());
  }

  /// Soft-deletes a health record by setting isDeleted to true.
  Future<void> softDelete(String id) {
    return (update(healthRecordsTable)..where((t) => t.id.equals(id))).write(
      HealthRecordsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently deletes a health record.
  Future<int> hardDelete(String id) {
    return (delete(healthRecordsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Watches the count of non-deleted health records for a user.
  Stream<int> watchCount(String userId) {
    final countExpr = healthRecordsTable.id.count();
    return (selectOnly(healthRecordsTable)
          ..addColumns([countExpr])
          ..where(
            healthRecordsTable.userId.equals(userId) &
                healthRecordsTable.isDeleted.equals(false),
          ))
        .watchSingle()
        .map((row) => row.read(countExpr) ?? 0);
  }

  /// Watches non-deleted health records for a specific bird.
  Stream<List<HealthRecord>> watchByBird(String birdId) {
    return (select(healthRecordsTable)
          ..where((t) => t.birdId.equals(birdId) & t.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Watches non-deleted health records for a specific chick.
  Stream<List<HealthRecord>> watchByChick(String chickId) {
    return (select(healthRecordsTable)
          ..where((t) => t.chickId.equals(chickId) & t.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Gets the latest health records for a specific bird, ordered by date descending.
  Future<List<HealthRecord>> getLatest(String birdId, {int limit = 5}) async {
    final rows =
        await (select(healthRecordsTable)
              ..where(
                (t) => t.birdId.equals(birdId) & t.isDeleted.equals(false),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(limit))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Gets the latest health records for a specific chick, ordered by date descending.
  Future<List<HealthRecord>> getLatestForChick(
    String chickId, {
    int limit = 5,
  }) async {
    final rows =
        await (select(healthRecordsTable)
              ..where(
                (t) => t.chickId.equals(chickId) & t.isDeleted.equals(false),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(limit))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Watches a per-type record count in the date range `[from, to]`.
  ///
  /// Statistics.md mandates SQL-side aggregation. Health records grow
  /// unbounded over time; pulling them all into Dart on every dashboard
  /// rebuild is wasteful when only counts are needed. Range bounds are
  /// passed as ISO-8601 strings (matches `DateTimeColumn` storage).
  Stream<Map<String, int>> watchCountsByTypeInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) {
    final query = customSelect(
      'SELECT type, COUNT(*) AS cnt '
      'FROM health_records '
      'WHERE user_id = ? AND is_deleted = 0 '
      'AND date >= ? AND date <= ? '
      'GROUP BY type',
      variables: [
        Variable.withString(userId),
        Variable.withDateTime(from),
        Variable.withDateTime(to),
      ],
      readsFrom: {healthRecordsTable},
    );
    return query.watch().map((rows) {
      final result = <String, int>{};
      for (final row in rows) {
        result[row.read<String>('type')] = row.read<int>('cnt');
      }
      return result;
    });
  }

  /// Busiest month by health record count (statistics.md SQL aggregation).
  /// UTC-based month bucketing (matches `record.date.year`/`.month` on the
  /// UTC-normalized `DateTime` loaded from the DB) — deliberately NOT
  /// `'localtime'`, to stay faithful to the previous Dart-side behavior.
  /// Ties broken by the smaller month key, mirroring the previous Dart
  /// `_maxEntry` helper's ascending-key tiebreak.
  Stream<({String month, int count})?> watchBusiestMonth(String userId) {
    final query = customSelect(
      "SELECT strftime('%Y-%m', date) AS month, COUNT(*) AS cnt "
      'FROM health_records '
      'WHERE user_id = ? AND is_deleted = 0 '
      'GROUP BY month '
      'ORDER BY cnt DESC, month ASC '
      'LIMIT 1',
      variables: [Variable.withString(userId)],
      readsFrom: {healthRecordsTable},
    );
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final row = rows.single;
      return (month: row.read<String>('month'), count: row.read<int>('cnt'));
    });
  }

  /// Most-visited bird by health record count. Ties broken by the smaller
  /// bird id, mirroring the previous Dart `_maxEntry` helper.
  Stream<({String birdId, int count})?> watchBusiestBird(String userId) {
    final query = customSelect(
      'SELECT bird_id, COUNT(*) AS cnt '
      'FROM health_records '
      'WHERE user_id = ? AND is_deleted = 0 AND bird_id IS NOT NULL '
      'GROUP BY bird_id '
      'ORDER BY cnt DESC, bird_id ASC '
      'LIMIT 1',
      variables: [Variable.withString(userId)],
      readsFrom: {healthRecordsTable},
    );
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final row = rows.single;
      return (birdId: row.read<String>('bird_id'), count: row.read<int>('cnt'));
    });
  }

  /// Average treatment/follow-up duration in days, across records with a
  /// follow-up date not before the record date. Uses UTC-midnight-normalized
  /// day counting (`julianday(date(x))`), matching
  /// `date_utils.DateUtils.dayDiff`. Returns `null` when no record qualifies
  /// (SQL `AVG` over zero rows is `NULL`).
  Stream<double?> watchAverageTreatmentDays(String userId) {
    final query = customSelect(
      'SELECT AVG(julianday(date(follow_up_date)) - julianday(date(date))) '
      'AS avg_days '
      'FROM health_records '
      'WHERE user_id = ? AND is_deleted = 0 '
      'AND follow_up_date IS NOT NULL AND follow_up_date >= date',
      variables: [Variable.withString(userId)],
      readsFrom: {healthRecordsTable},
    );
    return query.watch().map((rows) => rows.single.read<double?>('avg_days'));
  }
}
