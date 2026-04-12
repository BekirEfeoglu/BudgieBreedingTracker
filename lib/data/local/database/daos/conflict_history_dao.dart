import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/conflict_history_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/conflict_history_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';

part 'conflict_history_dao.g.dart';

@DriftAccessor(tables: [ConflictHistoryTable])
class ConflictHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ConflictHistoryDaoMixin {
  ConflictHistoryDao(super.db);

  Stream<List<ConflictHistory>> watchAll(String userId) {
    return (select(conflictHistoryTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(100))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<int> watchRecentCount(String userId, Duration since) {
    final cutoff = DateTime.now().subtract(since);
    final count = conflictHistoryTable.id.count();
    return (selectOnly(conflictHistoryTable)
          ..addColumns([count])
          ..where(conflictHistoryTable.userId.equals(userId) &
              conflictHistoryTable.createdAt.isBiggerOrEqualValue(cutoff)))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  Future<void> insert(ConflictHistory conflict) {
    return into(conflictHistoryTable)
        .insertOnConflictUpdate(conflict.toCompanion());
  }

  Future<int> deleteOlderThan(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (delete(conflictHistoryTable)
          ..where((t) => t.createdAt.isSmallerOrEqualValue(cutoff)))
        .go();
  }

  Future<int> deleteAll(String userId) {
    return (delete(conflictHistoryTable)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }
}
