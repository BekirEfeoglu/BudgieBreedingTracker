import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/genetics_history_dao.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';

/// Regression coverage for Task 5b: `GeneticsHistory.fatherPhaseOverrides`
/// must survive a real Drift round-trip (insert -> DAO read -> mapper),
/// not just the in-memory model/serializer. Prior to schema v28 the Drift
/// table had no matching column, so the override was silently dropped on
/// reload.
void main() {
  late AppDatabase db;
  late GeneticsHistoryDao dao;

  const userId = 'user-1';

  GeneticsHistory makeEntry({
    String id = 'hist-1',
    Map<String, String>? fatherPhaseOverrides,
  }) {
    return GeneticsHistory(
      id: id,
      userId: userId,
      fatherGenotype: const {'ino': 'heterozygous', 'slate': 'heterozygous'},
      motherGenotype: const {'ino': 'normal', 'slate': 'normal'},
      fatherPhaseOverrides: fatherPhaseOverrides,
      resultsJson: '[]',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.geneticsHistoryDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('fatherPhaseOverrides Drift round-trip', () {
    test(
      'survives insert -> DAO read -> mapper when overrides are set',
      () async {
        final entry = makeEntry(
          fatherPhaseOverrides: const {'ino|slate': 'coupling'},
        );
        await dao.insertItem(entry);

        final result = await dao.getById(entry.id);

        expect(result, isNotNull);
        expect(
          result!.fatherPhaseOverrides,
          equals({'ino|slate': 'coupling'}),
        );
      },
    );

    test('round-trips multiple linkage-pair overrides', () async {
      final entry = makeEntry(
        fatherPhaseOverrides: const {
          'ino|slate': 'coupling',
          'cinnamon|ino': 'repulsion',
        },
      );
      await dao.insertItem(entry);

      final result = await dao.getById(entry.id);

      expect(
        result!.fatherPhaseOverrides,
        equals({'ino|slate': 'coupling', 'cinnamon|ino': 'repulsion'}),
      );
    });

    test('round-trips to null when no override was saved', () async {
      final entry = makeEntry();
      await dao.insertItem(entry);

      final result = await dao.getById(entry.id);

      expect(result, isNotNull);
      expect(result!.fatherPhaseOverrides, isNull);
    });

    test('survives watchAll stream read, not just getById', () async {
      final entry = makeEntry(
        fatherPhaseOverrides: const {'ino|slate': 'repulsion'},
      );
      await dao.insertItem(entry);

      final results = await dao.watchAll(userId).first;

      expect(results, hasLength(1));
      expect(
        results.single.fatherPhaseOverrides,
        equals({'ino|slate': 'repulsion'}),
      );
    });
  });
}
