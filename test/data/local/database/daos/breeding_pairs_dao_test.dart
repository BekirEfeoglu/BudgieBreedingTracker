import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';

void main() {
  late AppDatabase db;
  late BreedingPairsDao dao;

  const userId = 'user-1';

  const otherId = 'user-2';

  BreedingPair makePair({
    String id = 'bp-1',
    String user = userId,
    String? maleId = 'bird-1',
    String? femaleId = 'bird-2',
    BreedingStatus status = BreedingStatus.active,
    bool isDeleted = false,
    DateTime? createdAt,
  }) {
    return BreedingPair(
      id: id,
      userId: user,
      maleId: maleId,
      femaleId: femaleId,
      status: status,
      isDeleted: isDeleted,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.breedingPairsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('insertItem', () {
    test('inserts and retrieves a single pair', () async {
      final pair = makePair();
      await dao.insertItem(pair);

      final result = await dao.getById(pair.id);
      expect(result, isNotNull);
      expect(result!.id, equals('bp-1'));
      expect(result.maleId, equals('bird-1'));
      expect(result.femaleId, equals('bird-2'));
    });

    test('upserts on conflict — updates existing', () async {
      await dao.insertItem(makePair(status: BreedingStatus.active));
      await dao.insertItem(makePair(status: BreedingStatus.completed));

      final result = await dao.getById('bp-1');
      expect(result!.status, equals(BreedingStatus.completed));
    });
  });

  group('insertAll', () {
    test('inserts multiple pairs in batch', () async {
      final pairs = List.generate(3, (i) => makePair(id: 'bp-${i + 1}'));
      await dao.insertAll(pairs);

      final all = await dao.getAll(userId);
      expect(all.length, equals(3));
    });

    test('empty list completes without error', () async {
      await dao.insertAll([]);

      final all = await dao.getAll(userId);
      expect(all, isEmpty);
    });
  });

  group('watchAll', () {
    test('returns non-deleted pairs for user', () async {
      await dao.insertItem(makePair(id: 'bp-1'));
      await dao.insertItem(makePair(id: 'bp-2', isDeleted: true));
      await dao.insertItem(makePair(id: 'bp-3', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('bp-1'));
    });

    test('emits empty list when no pairs exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });
  });

  group('watchById', () {
    test('emits single pair', () async {
      await dao.insertItem(makePair());

      final result = await dao.watchById('bp-1').first;
      expect(result, isNotNull);
      expect(result!.id, equals('bp-1'));
    });

    test('emits null for non-existent id', () async {
      final result = await dao.watchById('nonexistent').first;
      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('excludes soft-deleted pairs', () async {
      await dao.insertItem(makePair(id: 'bp-1'));
      await dao.insertItem(makePair(id: 'bp-2', isDeleted: true));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('scoped by userId', () async {
      await dao.insertItem(makePair(id: 'bp-1', user: userId));
      await dao.insertItem(makePair(id: 'bp-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });
  });

  group('softDelete', () {
    test('hides pair from watchAll and getAll', () async {
      await dao.insertItem(makePair());
      await dao.softDelete('bp-1');

      final all = await dao.getAll(userId);
      expect(all, isEmpty);
    });

    test('pair still retrievable via getById', () async {
      await dao.insertItem(makePair());
      await dao.softDelete('bp-1');

      final result = await dao.getById('bp-1');
      expect(result, isNotNull);
      expect(result!.isDeleted, isTrue);
    });
  });

  group('hardDelete', () {
    test('permanently removes the pair', () async {
      await dao.insertItem(makePair());
      await dao.hardDelete('bp-1');

      final result = await dao.getById('bp-1');
      expect(result, isNull);
    });
  });

  group('watchActiveCount', () {
    test('counts active and ongoing pairs', () async {
      await dao.insertItem(makePair(id: 'bp-1', status: BreedingStatus.active));
      await dao.insertItem(
        makePair(id: 'bp-2', status: BreedingStatus.ongoing),
      );
      await dao.insertItem(
        makePair(id: 'bp-3', status: BreedingStatus.completed),
      );

      final count = await dao.watchActiveCount(userId).first;
      expect(count, equals(2));
    });

    test('excludes soft-deleted', () async {
      await dao.insertItem(makePair(id: 'bp-1', isDeleted: true));

      final count = await dao.watchActiveCount(userId).first;
      expect(count, equals(0));
    });
  });

  group('watchActive', () {
    test('returns only active status pairs', () async {
      await dao.insertItem(makePair(id: 'bp-1', status: BreedingStatus.active));
      await dao.insertItem(
        makePair(id: 'bp-2', status: BreedingStatus.ongoing),
      );
      await dao.insertItem(
        makePair(id: 'bp-3', status: BreedingStatus.completed),
      );

      final results = await dao.watchActive(userId).first;
      expect(results.length, equals(1));
      expect(results.first.status, equals(BreedingStatus.active));
    });
  });

  group('getByBirdId', () {
    test('finds pairs where bird is male', () async {
      await dao.insertItem(makePair(id: 'bp-1', maleId: 'bird-x'));

      final results = await dao.getByBirdId('bird-x');
      expect(results.length, equals(1));
    });

    test('finds pairs where bird is female', () async {
      await dao.insertItem(makePair(id: 'bp-1', femaleId: 'bird-y'));

      final results = await dao.getByBirdId('bird-y');
      expect(results.length, equals(1));
    });

    test('excludes soft-deleted pairs', () async {
      await dao.insertItem(
        makePair(id: 'bp-1', maleId: 'bird-x', isDeleted: true),
      );

      final results = await dao.getByBirdId('bird-x');
      expect(results, isEmpty);
    });
  });

  group('watchActiveLimited', () {
    test('returns active and ongoing pairs', () async {
      await dao.insertItem(makePair(id: 'bp-1', status: BreedingStatus.active));
      await dao.insertItem(
        makePair(id: 'bp-2', status: BreedingStatus.ongoing),
      );
      await dao.insertItem(
        makePair(id: 'bp-3', status: BreedingStatus.completed),
      );

      final results = await dao.watchActiveLimited(userId).first;
      expect(results.length, equals(2));
      expect(results.map((p) => p.id).toSet(), containsAll(['bp-1', 'bp-2']));
    });

    test('respects limit parameter', () async {
      for (var i = 1; i <= 5; i++) {
        await dao.insertItem(
          makePair(
            id: 'bp-$i',
            status: BreedingStatus.active,
            createdAt: DateTime(2024, 1, i),
          ),
        );
      }

      final results = await dao.watchActiveLimited(userId, limit: 2).first;
      expect(results.length, equals(2));
    });

    test('orders by createdAt descending', () async {
      await dao.insertItem(
        makePair(id: 'bp-1', createdAt: DateTime(2024, 1, 1)),
      );
      await dao.insertItem(
        makePair(id: 'bp-2', createdAt: DateTime(2024, 1, 3)),
      );
      await dao.insertItem(
        makePair(id: 'bp-3', createdAt: DateTime(2024, 1, 2)),
      );

      final results = await dao.watchActiveLimited(userId).first;
      expect(
        results.map((p) => p.id).toList(),
        equals(['bp-2', 'bp-3', 'bp-1']),
      );
    });

    test('excludes soft-deleted pairs', () async {
      await dao.insertItem(makePair(id: 'bp-1'));
      await dao.insertItem(makePair(id: 'bp-2', isDeleted: true));

      final results = await dao.watchActiveLimited(userId).first;
      expect(results.length, equals(1));
    });

    test('only returns pairs for given userId', () async {
      await dao.insertItem(makePair(id: 'bp-1'));
      await dao.insertItem(makePair(id: 'bp-2', user: 'other-user'));

      final results = await dao.watchActiveLimited(userId).first;
      expect(results.length, equals(1));
    });

    test('returns empty list when no active pairs exist', () async {
      await dao.insertItem(
        makePair(id: 'bp-1', status: BreedingStatus.completed),
      );

      final results = await dao.watchActiveLimited(userId).first;
      expect(results, isEmpty);
    });
  });
}
