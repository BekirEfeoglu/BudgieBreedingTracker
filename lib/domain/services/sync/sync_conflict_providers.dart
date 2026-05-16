import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/models/sync_conflict.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

export 'package:budgie_breeding_tracker/core/models/sync_conflict.dart';

/// Stream count of persisted conflict history records.
final persistedConflictCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  if (userId == 'anonymous') return Stream.value(0);
  final dao = ref.watch(conflictHistoryDaoProvider);
  return dao.watchRecentCount(userId, const Duration(hours: 24));
});

/// Lookup key for record-level conflict badges.
typedef ConflictRecordKey = ({String userId, String table, String recordId});

/// Whether a persisted sync conflict exists for a specific local record.
final conflictExistsForRecordProvider =
    FutureProvider.family<bool, ConflictRecordKey>((ref, key) {
      if (key.userId == 'anonymous') return false;
      final dao = ref.watch(conflictHistoryDaoProvider);
      return dao.existsForRecord(key.userId, key.table, key.recordId);
    });

// ---------------------------------------------------------------------------
// Conflict History (DB-backed, max 50 entries, FIFO)
// ---------------------------------------------------------------------------

class ConflictHistoryNotifier extends Notifier<List<SyncConflict>> {
  static const _maxEntries = 50;

  @override
  List<SyncConflict> build() {
    _restoreFromDb();
    return [];
  }

  Future<void> _restoreFromDb() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final dao = ref.read(conflictHistoryDaoProvider);
      final persisted = await dao.watchAll(userId).first;
      if (persisted.isNotEmpty) {
        state = persisted
            .map(
              (c) => SyncConflict(
                table: c.tableName,
                recordId: c.recordId,
                detectedAt: c.createdAt ?? DateTime.now(),
                description: c.description,
              ),
            )
            .take(_maxEntries)
            .toList();
      }
    } catch (e) {
      AppLogger.debug('[ConflictHistory] Restore failed: $e');
    }
  }

  void addConflict(SyncConflict conflict) {
    state = [conflict, ...state].take(_maxEntries).toList();
  }

  void clear() => state = [];
}

final conflictHistoryProvider =
    NotifierProvider<ConflictHistoryNotifier, List<SyncConflict>>(
      ConflictHistoryNotifier.new,
    );
