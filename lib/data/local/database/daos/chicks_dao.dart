import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/breeding_pairs_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/chicks_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/clutches_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/chick_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

part 'chicks_dao.g.dart';

@DriftAccessor(
  tables: [ChicksTable, ClutchesTable, BreedingPairsTable],
)
class ChicksDao extends DatabaseAccessor<AppDatabase> with _$ChicksDaoMixin {
  ChicksDao(super.db);

  Stream<List<Chick>> watchAll(String userId) {
    return (select(chicksTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<Chick?> watchById(String id) {
    return (select(chicksTable)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<Chick>> getAll(String userId) async {
    final rows = await (select(
      chicksTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<Chick?> getById(String id) async {
    final row =
        await (select(chicksTable)
              ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
            .getSingleOrNull();
    return row?.toModel();
  }

  Future<Chick?> getByIdIncludingDeleted(String id) async {
    final row = await (select(
      chicksTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(Chick model) {
    return into(chicksTable).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<Chick> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        chicksTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> updateItem(Chick model) {
    return update(chicksTable).replace(model.toCompanion());
  }

  Future<void> softDelete(String id) {
    return (update(chicksTable)..where((t) => t.id.equals(id))).write(
      ChicksTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(chicksTable)..where((t) => t.id.equals(id))).go();
  }

  /// Reactive count of all non-deleted chicks for a user (lightweight).
  Stream<int> watchCount(String userId) {
    final count = chicksTable.id.count();
    return (selectOnly(chicksTable)
          ..addColumns([count])
          ..where(
            chicksTable.userId.equals(userId) &
                chicksTable.isDeleted.equals(false),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  Stream<List<Chick>> watchByClutch(String clutchId) {
    return (select(chicksTable)..where(
          (t) => t.clutchId.equals(clutchId) & t.isDeleted.equals(false),
        ))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<Chick?> getByEggId(String eggId) async {
    final row =
        await (select(chicksTable)
              ..where((t) => t.eggId.equals(eggId) & t.isDeleted.equals(false)))
            .getSingleOrNull();
    return row?.toModel();
  }

  Future<List<Chick>> getByEggIds(List<String> eggIds) async {
    if (eggIds.isEmpty) return [];
    final rows = await (select(
      chicksTable,
    )..where((t) => t.eggId.isIn(eggIds) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<List<Chick>> getUnweaned(String userId) async {
    final rows =
        await (select(chicksTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.weanDate.isNull() &
                  t.isDeleted.equals(false),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Recent chicks sorted by hatch date descending (SQL LIMIT).
  Stream<List<Chick>> watchRecent(String userId, {int limit = 5}) {
    return (select(chicksTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.hatchDate)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Watches monthly hatched-chick counts: `'YYYY-MM' → count`.
  ///
  /// Counts non-deleted chicks bucketed by `hatch_date` month. statistics.md
  /// mandates SQL-side aggregation; previously the chart provider walked
  /// the full chick list in Dart on every emission.
  Stream<Map<String, int>> watchMonthlyHatched(String userId) {
    final query = customSelect(
      "SELECT strftime('%Y-%m', hatch_date, 'localtime') AS month, COUNT(*) AS cnt "
      'FROM chicks '
      'WHERE user_id = ? AND is_deleted = 0 AND hatch_date IS NOT NULL '
      'GROUP BY month ORDER BY month',
      variables: [Variable.withString(userId)],
      readsFrom: {chicksTable},
    );
    return query.watch().map((rows) {
      final result = <String, int>{};
      for (final row in rows) {
        result[row.read<String>('month')] = row.read<int>('cnt');
      }
      return result;
    });
  }

  /// Most productive hatch year (chicks grouped by hatch year), for the
  /// personal-records highlight card. Ties broken by smallest year, mirroring
  /// the previous Dart `_maxEntry` helper's ascending-key tiebreak.
  Stream<({int year, int count})?> watchMostProductiveSeason(String userId) {
    final query = customSelect(
      "SELECT CAST(strftime('%Y', hatch_date) AS INTEGER) AS year, "
      'COUNT(*) AS cnt '
      'FROM chicks '
      'WHERE user_id = ? AND hatch_date IS NOT NULL AND is_deleted = 0 '
      'GROUP BY year '
      'ORDER BY cnt DESC, year ASC '
      'LIMIT 1',
      variables: [Variable.withString(userId)],
      readsFrom: {chicksTable},
    );
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final row = rows.single;
      return (year: row.read<int>('year'), count: row.read<int>('cnt'));
    });
  }

  /// Breeding pair with the most hatched chicks (joined via clutch ->
  /// breeding pair), restricted to non-deleted pairs — mirrors the previous
  /// Dart-side `validPairIds.contains(pairId)` guard. Ties broken by
  /// smallest pair id, mirroring `_maxEntry`'s ascending-key tiebreak.
  Stream<({String pairId, int count})?> watchTopPairByChickCount(
    String userId,
  ) {
    final query = customSelect(
      'SELECT cl.breeding_id AS pair_id, COUNT(*) AS cnt '
      'FROM chicks c '
      'INNER JOIN clutches cl ON c.clutch_id = cl.id '
      'INNER JOIN breeding_pairs bp ON cl.breeding_id = bp.id '
      'WHERE c.user_id = ? AND c.is_deleted = 0 '
      'AND cl.breeding_id IS NOT NULL AND cl.is_deleted = 0 '
      'AND bp.is_deleted = 0 '
      'GROUP BY cl.breeding_id '
      'ORDER BY cnt DESC, pair_id ASC '
      'LIMIT 1',
      variables: [Variable.withString(userId)],
      readsFrom: {chicksTable, clutchesTable, breedingPairsTable},
    );
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final row = rows.single;
      return (
        pairId: row.read<String>('pair_id'),
        count: row.read<int>('cnt'),
      );
    });
  }

  /// Distinct calendar years present in `hatch_date`, for the season-
  /// comparison highlight card (statistics.md SQL aggregation requirement).
  /// UTC-based (matches `chick.hatchDate.year` on the UTC-normalized
  /// DateTime).
  Stream<Set<int>> watchDistinctHatchYears(String userId) {
    final query = customSelect(
      "SELECT DISTINCT CAST(strftime('%Y', hatch_date) AS INTEGER) AS year "
      'FROM chicks '
      'WHERE user_id = ? AND is_deleted = 0 AND hatch_date IS NOT NULL',
      variables: [Variable.withString(userId)],
      readsFrom: {chicksTable},
    );
    return query.watch().map(
      (rows) => rows.map((row) => row.read<int>('year')).toSet(),
    );
  }

  /// Chick totals within a `[from, to)` hatch-date window (total hatched,
  /// deceased) — for period-aware trend/insight providers (statistics.md
  /// SQL aggregation requirement). `to` is an exclusive upper bound,
  /// matching `StatsDateRange.isInCurrent`/`isInPrevious` semantics.
  Stream<({int total, int deceased})> watchPeriodChickStats(
    String userId,
    DateTime from,
    DateTime to,
  ) {
    final query = customSelect(
      'SELECT COUNT(*) AS total, '
      'SUM(CASE WHEN health_status = ? THEN 1 ELSE 0 END) AS deceased_count '
      'FROM chicks '
      'WHERE user_id = ? AND is_deleted = 0 '
      'AND hatch_date >= ? AND hatch_date < ?',
      variables: [
        Variable.withString(ChickHealthStatus.deceased.name),
        Variable.withString(userId),
        Variable.withDateTime(from),
        Variable.withDateTime(to),
      ],
      readsFrom: {chicksTable},
    );
    return query.watch().map((rows) {
      final row = rows.single;
      return (
        total: row.read<int>('total'),
        deceased: row.read<int?>('deceased_count') ?? 0,
      );
    });
  }

  /// Chick totals for a single calendar hatch [year] (total hatched, live —
  /// not deceased), for the season-comparison highlight card.
  Stream<({int total, int live})> watchSeasonChickStats(
    String userId,
    int year,
  ) {
    final query = customSelect(
      'SELECT COUNT(*) AS total, '
      'SUM(CASE WHEN health_status != ? THEN 1 ELSE 0 END) AS live_count '
      'FROM chicks '
      "WHERE user_id = ? AND is_deleted = 0 AND strftime('%Y', hatch_date) = ?",
      variables: [
        Variable.withString(ChickHealthStatus.deceased.name),
        Variable.withString(userId),
        Variable.withString(year.toString()),
      ],
      readsFrom: {chicksTable},
    );
    return query.watch().map((rows) {
      final row = rows.single;
      return (
        total: row.read<int>('total'),
        live: row.read<int?>('live_count') ?? 0,
      );
    });
  }

  /// Watches chick counts grouped by health status: enum name → count.
  ///
  /// statistics.md mandates SQL-side aggregation; `chickSurvivalProvider`
  /// previously pulled the full chick list via `chicksStreamProvider` (with
  /// per-chick photo URL resolution) and counted healthy/sick/deceased in
  /// Dart on every emission — the same anti-pattern already fixed here for
  /// `watchMonthlyHatched`.
  Stream<Map<String, int>> watchHealthStatusCounts(String userId) {
    final query = customSelect(
      'SELECT health_status, COUNT(*) AS cnt '
      'FROM chicks '
      'WHERE user_id = ? AND is_deleted = 0 '
      'GROUP BY health_status',
      variables: [Variable.withString(userId)],
      readsFrom: {chicksTable},
    );
    return query.watch().map((rows) {
      final result = <String, int>{};
      for (final row in rows) {
        result[row.read<String>('health_status')] = row.read<int>('cnt');
      }
      return result;
    });
  }

  /// Count of chicks that are 60+ days old, not yet moved to birds, and alive.
  Stream<int> watchUnweanedCount(String userId) {
    final count = chicksTable.id.count();
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    return (selectOnly(chicksTable)
          ..addColumns([count])
          ..where(
            chicksTable.userId.equals(userId) &
                chicksTable.isDeleted.equals(false) &
                chicksTable.birdId.isNull() &
                chicksTable.healthStatus.equalsValue(
                  ChickHealthStatus.healthy,
                ) &
                chicksTable.hatchDate.isSmallerOrEqualValue(cutoff),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }
}
