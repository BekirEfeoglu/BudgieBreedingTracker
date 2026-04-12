import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

void main() {
  late AppDatabase db;
  late IncubationsDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  Incubation makeEntry({
    String id = 'inc-1',
    String user = userId,
    IncubationStatus status = IncubationStatus.active,
    String breedingPairId = 'pair-1',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Incubation(
      id: id,
      userId: user,
      status: status,
      breedingPairId: breedingPairId,
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.incubationsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns incubations for the given userId', () async {
      await dao.insertItem(makeEntry(id: 'inc-1'));
      await dao.insertItem(makeEntry(id: 'inc-2'));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('does not return incubations for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'inc-1', user: userId));
      await dao.insertItem(makeEntry(id: 'inc-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('inc-1'));
    });

    test('returns empty list when no incubations exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns all statuses (no isDeleted filter)', () async {
      await dao.insertItem(
        makeEntry(id: 'inc-1', status: IncubationStatus.active),
      );
      await dao.insertItem(
        makeEntry(id: 'inc-2', status: IncubationStatus.completed),
      );
      await dao.insertItem(
        makeEntry(id: 'inc-3', status: IncubationStatus.cancelled),
      );

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(3));
    });
  });

  group('watchById', () {
    test('returns the incubation when it exists', () async {
      await dao.insertItem(makeEntry(id: 'inc-1'));

      final result = await dao.watchById('inc-1').first;
      expect(result, isNotNull);
      expect(result!.id, equals('inc-1'));
    });

    test('returns null when incubation does not exist', () async {
      final result = await dao.watchById('non-existent').first;
      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('returns incubations for the given userId', () async {
      await dao.insertItem(makeEntry(id: 'inc-1'));
      await dao.insertItem(makeEntry(id: 'inc-2'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('does not return incubations for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'inc-1', user: userId));
      await dao.insertItem(makeEntry(id: 'inc-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no incubations exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the incubation when it exists', () async {
      await dao.insertItem(makeEntry(id: 'inc-1'));

      final result = await dao.getById('inc-1');
      expect(result, isNotNull);
      expect(result!.id, equals('inc-1'));
      expect(result.userId, equals(userId));
    });

    test('returns null when incubation does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });
  });

  group('insertItem', () {
    test('inserts a new incubation', () async {
      await dao.insertItem(makeEntry(id: 'inc-1'));

      final result = await dao.getById('inc-1');
      expect(result, isNotNull);
      expect(result!.status, equals(IncubationStatus.active));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(
        makeEntry(id: 'inc-1', status: IncubationStatus.active),
      );
      await dao.insertItem(
        makeEntry(id: 'inc-1', status: IncubationStatus.completed),
      );

      final result = await dao.getById('inc-1');
      expect(result, isNotNull);
      expect(result!.status, equals(IncubationStatus.completed));
    });
  });

  group('insertAll', () {
    test('inserts multiple incubations in batch', () async {
      final items = [
        makeEntry(id: 'inc-1'),
        makeEntry(id: 'inc-2'),
        makeEntry(id: 'inc-3'),
      ];
      await dao.insertAll(items);

      final results = await dao.getAll(userId);
      expect(results.length, equals(3));
    });

    test('handles empty list gracefully', () async {
      await dao.insertAll([]);

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });

    test('upserts on conflict within batch', () async {
      await dao.insertItem(
        makeEntry(id: 'inc-1', status: IncubationStatus.active),
      );
      await dao.insertAll([
        makeEntry(id: 'inc-1', status: IncubationStatus.completed),
        makeEntry(id: 'inc-2', status: IncubationStatus.active),
      ]);

      final updated = await dao.getById('inc-1');
      expect(updated!.status, equals(IncubationStatus.completed));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('hardDelete', () {
    test('permanently removes the incubation', () async {
      await dao.insertItem(makeEntry(id: 'inc-1'));

      await dao.hardDelete('inc-1');

      final result = await dao.getById('inc-1');
      expect(result, isNull);
    });

    test('does not affect other incubations', () async {
      await dao.insertItem(makeEntry(id: 'inc-1'));
      await dao.insertItem(makeEntry(id: 'inc-2'));

      await dao.hardDelete('inc-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('inc-2'));
    });

    test('is a no-op when incubation does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('watchActive', () {
    test('returns only active incubations for the user', () async {
      await dao.insertItem(
        makeEntry(id: 'inc-1', status: IncubationStatus.active),
      );
      await dao.insertItem(
        makeEntry(id: 'inc-2', status: IncubationStatus.completed),
      );
      await dao.insertItem(
        makeEntry(id: 'inc-3', status: IncubationStatus.cancelled),
      );

      final results = await dao.watchActive(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('inc-1'));
    });

    test('does not return active incubations of another user', () async {
      await dao.insertItem(
        makeEntry(id: 'inc-1', user: userId, status: IncubationStatus.active),
      );
      await dao.insertItem(
        makeEntry(id: 'inc-2', user: otherId, status: IncubationStatus.active),
      );

      final results = await dao.watchActive(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('inc-1'));
    });

    test('returns empty list when no active incubations exist', () async {
      await dao.insertItem(
        makeEntry(id: 'inc-1', status: IncubationStatus.completed),
      );

      final results = await dao.watchActive(userId).first;
      expect(results, isEmpty);
    });
  });

  group('getByBreedingPair', () {
    test('returns incubations for the given breeding pair', () async {
      await dao.insertItem(makeEntry(id: 'inc-1', breedingPairId: 'pair-1'));
      await dao.insertItem(makeEntry(id: 'inc-2', breedingPairId: 'pair-1'));
      await dao.insertItem(makeEntry(id: 'inc-3', breedingPairId: 'pair-2'));

      final results = await dao.getByBreedingPair('pair-1');
      expect(results.length, equals(2));
    });

    test('returns empty list when no incubations match', () async {
      await dao.insertItem(makeEntry(id: 'inc-1', breedingPairId: 'pair-1'));

      final results = await dao.getByBreedingPair('pair-99');
      expect(results, isEmpty);
    });

    test('returns incubations regardless of userId', () async {
      await dao.insertItem(
        makeEntry(id: 'inc-1', user: userId, breedingPairId: 'pair-1'),
      );
      await dao.insertItem(
        makeEntry(id: 'inc-2', user: otherId, breedingPairId: 'pair-1'),
      );

      final results = await dao.getByBreedingPair('pair-1');
      expect(results.length, equals(2));
    });
  });

  group('getByBreedingPairIds', () {
    test('returns incubations matching any of the pair IDs', () async {
      await dao.insertItem(makeEntry(id: 'inc-1', breedingPairId: 'pair-1'));
      await dao.insertItem(makeEntry(id: 'inc-2', breedingPairId: 'pair-2'));
      await dao.insertItem(makeEntry(id: 'inc-3', breedingPairId: 'pair-3'));

      final results = await dao.getByBreedingPairIds(['pair-1', 'pair-3']);
      expect(results.length, equals(2));
      final ids = results.map((r) => r.id).toSet();
      expect(ids, containsAll(['inc-1', 'inc-3']));
    });

    test('returns empty list for empty input', () async {
      await dao.insertItem(makeEntry(id: 'inc-1'));

      final results = await dao.getByBreedingPairIds([]);
      expect(results, isEmpty);
    });

    test('returns empty list when no IDs match', () async {
      await dao.insertItem(makeEntry(id: 'inc-1', breedingPairId: 'pair-1'));

      final results = await dao.getByBreedingPairIds(['pair-99', 'pair-100']);
      expect(results, isEmpty);
    });

    test('returns single match with single ID', () async {
      await dao.insertItem(makeEntry(id: 'inc-1', breedingPairId: 'pair-1'));
      await dao.insertItem(makeEntry(id: 'inc-2', breedingPairId: 'pair-2'));

      final results = await dao.getByBreedingPairIds(['pair-2']);
      expect(results.length, equals(1));
      expect(results.first.id, equals('inc-2'));
    });
  });
}
