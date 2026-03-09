import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/growth_measurements_dao.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';

void main() {
  late AppDatabase db;
  late GrowthMeasurementsDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  GrowthMeasurement makeEntry({
    String id = 'gm-1',
    String user = userId,
    String chickId = 'chick-1',
    double weight = 25.0,
    DateTime? measurementDate,
    double? height,
    double? wingLength,
    double? tailLength,
    String? notes,
  }) {
    return GrowthMeasurement(
      id: id,
      chickId: chickId,
      weight: weight,
      measurementDate: measurementDate ?? DateTime(2024, 2, 1),
      userId: user,
      height: height,
      wingLength: wingLength,
      tailLength: tailLength,
      notes: notes,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.growthMeasurementsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns measurements for the given userId', () async {
      await dao.insertItem(makeEntry(id: 'gm-1', user: userId));
      await dao.insertItem(makeEntry(id: 'gm-2', user: userId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('does not return measurements for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'gm-1', user: userId));
      await dao.insertItem(makeEntry(id: 'gm-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('gm-1'));
    });

    test('returns empty list when no measurements exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns all measurements without isDeleted filter', () async {
      await dao.insertItem(makeEntry(id: 'gm-1', weight: 20.0));
      await dao.insertItem(makeEntry(id: 'gm-2', weight: 30.0));
      await dao.insertItem(makeEntry(id: 'gm-3', weight: 40.0));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(3));
    });
  });

  group('watchById', () {
    test('returns the measurement when it exists', () async {
      await dao.insertItem(makeEntry(id: 'gm-1'));

      final result = await dao.watchById('gm-1').first;
      expect(result, isNotNull);
      expect(result!.id, equals('gm-1'));
      expect(result.weight, equals(25.0));
    });

    test('returns null when measurement does not exist', () async {
      final result = await dao.watchById('non-existent').first;
      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('returns measurements for the given userId', () async {
      await dao.insertItem(makeEntry(id: 'gm-1'));
      await dao.insertItem(makeEntry(id: 'gm-2'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('does not return measurements for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'gm-1', user: userId));
      await dao.insertItem(makeEntry(id: 'gm-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no measurements exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the measurement when it exists', () async {
      await dao.insertItem(makeEntry(id: 'gm-1'));

      final result = await dao.getById('gm-1');
      expect(result, isNotNull);
      expect(result!.id, equals('gm-1'));
      expect(result.userId, equals(userId));
      expect(result.chickId, equals('chick-1'));
    });

    test('returns null when measurement does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });
  });

  group('insertItem', () {
    test('inserts a new measurement', () async {
      await dao.insertItem(makeEntry(id: 'gm-1'));

      final result = await dao.getById('gm-1');
      expect(result, isNotNull);
      expect(result!.weight, equals(25.0));
      expect(result.chickId, equals('chick-1'));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(makeEntry(id: 'gm-1', weight: 25.0));
      await dao.insertItem(makeEntry(id: 'gm-1', weight: 30.0));

      final result = await dao.getById('gm-1');
      expect(result, isNotNull);
      expect(result!.weight, equals(30.0));
    });

    test('stores all optional fields correctly', () async {
      await dao.insertItem(
        makeEntry(
          id: 'gm-1',
          height: 5.5,
          wingLength: 3.2,
          tailLength: 2.8,
          notes: 'Healthy growth',
        ),
      );

      final result = await dao.getById('gm-1');
      expect(result, isNotNull);
      expect(result!.height, equals(5.5));
      expect(result.wingLength, equals(3.2));
      expect(result.tailLength, equals(2.8));
      expect(result.notes, equals('Healthy growth'));
    });
  });

  group('insertAll', () {
    test('inserts multiple measurements in batch', () async {
      final items = [
        makeEntry(id: 'gm-1'),
        makeEntry(id: 'gm-2'),
        makeEntry(id: 'gm-3'),
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
      await dao.insertItem(makeEntry(id: 'gm-1', weight: 25.0));
      await dao.insertAll([
        makeEntry(id: 'gm-1', weight: 30.0),
        makeEntry(id: 'gm-2', weight: 35.0),
      ]);

      final updated = await dao.getById('gm-1');
      expect(updated!.weight, equals(30.0));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('hardDelete', () {
    test('permanently removes the measurement', () async {
      await dao.insertItem(makeEntry(id: 'gm-1'));

      await dao.hardDelete('gm-1');

      final result = await dao.getById('gm-1');
      expect(result, isNull);
    });

    test('does not affect other measurements', () async {
      await dao.insertItem(makeEntry(id: 'gm-1'));
      await dao.insertItem(makeEntry(id: 'gm-2'));

      await dao.hardDelete('gm-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('gm-2'));
    });

    test('is a no-op when measurement does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('watchByChick', () {
    test('returns measurements for the specific chick', () async {
      await dao.insertItem(makeEntry(id: 'gm-1', chickId: 'chick-1'));
      await dao.insertItem(makeEntry(id: 'gm-2', chickId: 'chick-1'));
      await dao.insertItem(makeEntry(id: 'gm-3', chickId: 'chick-2'));

      final results = await dao.watchByChick('chick-1').first;
      expect(results.length, equals(2));
    });

    test('returns measurements ordered by date ascending', () async {
      await dao.insertItem(
        makeEntry(
          id: 'gm-1',
          chickId: 'chick-1',
          measurementDate: DateTime(2024, 2, 3),
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'gm-2',
          chickId: 'chick-1',
          measurementDate: DateTime(2024, 2, 1),
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'gm-3',
          chickId: 'chick-1',
          measurementDate: DateTime(2024, 2, 2),
        ),
      );

      final results = await dao.watchByChick('chick-1').first;
      expect(
        results.map((m) => m.id).toList(),
        equals(['gm-2', 'gm-3', 'gm-1']),
      );
    });

    test(
      'returns empty list when no measurements exist for the chick',
      () async {
        await dao.insertItem(makeEntry(id: 'gm-1', chickId: 'chick-1'));

        final results = await dao.watchByChick('chick-99').first;
        expect(results, isEmpty);
      },
    );
  });

  group('getLatest', () {
    test('returns the most recent measurement by date', () async {
      await dao.insertItem(
        makeEntry(
          id: 'gm-1',
          chickId: 'chick-1',
          measurementDate: DateTime(2024, 2, 1),
          weight: 20.0,
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'gm-2',
          chickId: 'chick-1',
          measurementDate: DateTime(2024, 2, 3),
          weight: 30.0,
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'gm-3',
          chickId: 'chick-1',
          measurementDate: DateTime(2024, 2, 2),
          weight: 25.0,
        ),
      );

      final result = await dao.getLatest('chick-1');
      expect(result, isNotNull);
      expect(result!.id, equals('gm-2'));
      expect(result.weight, equals(30.0));
    });

    test('returns null when no measurements exist for the chick', () async {
      final result = await dao.getLatest('chick-99');
      expect(result, isNull);
    });

    test('returns only for the specified chick', () async {
      await dao.insertItem(
        makeEntry(
          id: 'gm-1',
          chickId: 'chick-1',
          measurementDate: DateTime(2024, 2, 1),
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'gm-2',
          chickId: 'chick-2',
          measurementDate: DateTime(2024, 2, 5),
        ),
      );

      final result = await dao.getLatest('chick-1');
      expect(result, isNotNull);
      expect(result!.id, equals('gm-1'));
      expect(result.chickId, equals('chick-1'));
    });
  });
}
