import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/genetics_history_dao.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';

void main() {
  late AppDatabase db;
  late GeneticsHistoryDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  GeneticsHistory makeEntry({
    String id = 'hist-1',
    String user = userId,
    String? notes,
    bool isDeleted = false,
    DateTime? createdAt,
  }) {
    return GeneticsHistory(
      id: id,
      userId: user,
      fatherGenotype: const {'mut-1': 'carrier'},
      motherGenotype: const {'mut-1': 'normal'},
      resultsJson: '[]',
      notes: notes,
      isDeleted: isDeleted,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
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

  group('insertItem', () {
    test('inserts and retrieves a single entry', () async {
      final entry = makeEntry();
      await dao.insertItem(entry);

      final result = await dao.getById(entry.id);
      expect(result, isNotNull);
      expect(result!.id, equals(entry.id));
      expect(result.userId, equals(userId));
      expect(result.fatherGenotype, equals(entry.fatherGenotype));
      expect(result.resultsJson, equals('[]'));
    });

    test('upserts on conflict — updates existing entry', () async {
      final original = makeEntry(notes: 'original');
      await dao.insertItem(original);

      final updated = makeEntry(notes: 'updated');
      await dao.insertItem(updated);

      final result = await dao.getById(original.id);
      expect(result!.notes, equals('updated'));
    });
  });

  group('insertAll', () {
    test('inserts multiple entries in a single batch transaction', () async {
      final entries = List.generate(
        5,
        (i) =>
            makeEntry(id: 'hist-${i + 1}', createdAt: DateTime(2024, 1, i + 1)),
      );

      await dao.insertAll(entries);

      final all = await dao.getAll(userId);
      expect(all.length, equals(5));
    });

    test(
      'batch upserts — updates existing entries without duplicates',
      () async {
        final initial = [
          makeEntry(id: 'hist-1', notes: 'before'),
          makeEntry(id: 'hist-2', notes: 'before'),
        ];
        await dao.insertAll(initial);

        final updated = [
          makeEntry(id: 'hist-1', notes: 'after'),
          makeEntry(id: 'hist-3'),
        ];
        await dao.insertAll(updated);

        final all = await dao.getAll(userId);
        expect(all.length, equals(3));

        final entry1 = await dao.getById('hist-1');
        expect(entry1!.notes, equals('after'));
      },
    );

    test('empty list completes without error', () async {
      await dao.insertAll([]);

      final all = await dao.getAll(userId);
      expect(all, isEmpty);
    });
  });

  group('watchAll', () {
    test('emits entries for the given user only', () async {
      await dao.insertItem(makeEntry(id: 'hist-1', user: userId));
      await dao.insertItem(makeEntry(id: 'hist-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('hist-1'));
    });

    test('excludes soft-deleted entries', () async {
      await dao.insertItem(makeEntry(id: 'hist-1'));
      await dao.insertItem(makeEntry(id: 'hist-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
    });

    test('emits newest first (descending createdAt)', () async {
      await dao.insertItem(
        makeEntry(id: 'hist-1', createdAt: DateTime(2024, 1, 1)),
      );
      await dao.insertItem(
        makeEntry(id: 'hist-2', createdAt: DateTime(2024, 1, 3)),
      );
      await dao.insertItem(
        makeEntry(id: 'hist-3', createdAt: DateTime(2024, 1, 2)),
      );

      final results = await dao.watchAll(userId).first;
      expect(
        results.map((e) => e.id).toList(),
        equals(['hist-2', 'hist-3', 'hist-1']),
      );
    });

    test('emits empty list when no entries exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('reactively emits after insertItem', () async {
      final stream = dao.watchAll(userId);
      final emissions = <List<GeneticsHistory>>[];
      final sub = stream.listen(emissions.add);

      await Future<void>.delayed(Duration.zero);
      await dao.insertItem(makeEntry());
      await Future<void>.delayed(Duration.zero);

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.length, equals(1));
      await sub.cancel();
    });
  });

  group('softDelete', () {
    test('hides entry from watchAll and getAll', () async {
      await dao.insertItem(makeEntry());
      await dao.softDelete('hist-1');

      final all = await dao.getAll(userId);
      expect(all, isEmpty);

      final stream = await dao.watchAll(userId).first;
      expect(stream, isEmpty);
    });

    test('entry still retrievable via getById after soft delete', () async {
      await dao.insertItem(makeEntry());
      await dao.softDelete('hist-1');

      final row = await dao.getById('hist-1');
      expect(row, isNotNull);
      expect(row!.isDeleted, isTrue);
    });
  });

  group('hardDelete', () {
    test('permanently removes the entry', () async {
      await dao.insertItem(makeEntry());
      await dao.hardDelete('hist-1');

      final row = await dao.getById('hist-1');
      expect(row, isNull);
    });
  });
}
