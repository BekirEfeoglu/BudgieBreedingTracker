import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

void main() {
  late AppDatabase db;
  late ChicksDao dao;

  const userId = 'user-1';

  Chick makeChick({
    String id = 'chick-1',
    String user = userId,
    ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
    String? birdId,
    DateTime? hatchDate,
    bool isDeleted = false,
  }) {
    return Chick(
      id: id,
      userId: user,
      healthStatus: healthStatus,
      birdId: birdId,
      hatchDate: hatchDate,
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.chicksDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchRecent', () {
    test('returns chicks ordered by hatchDate descending', () async {
      await dao.insertItem(
        makeChick(id: 'c1', hatchDate: DateTime(2024, 1, 1)),
      );
      await dao.insertItem(
        makeChick(id: 'c2', hatchDate: DateTime(2024, 1, 3)),
      );
      await dao.insertItem(
        makeChick(id: 'c3', hatchDate: DateTime(2024, 1, 2)),
      );

      final results = await dao.watchRecent(userId).first;
      expect(results.map((c) => c.id).toList(), equals(['c2', 'c3', 'c1']));
    });

    test('respects limit parameter', () async {
      for (var i = 1; i <= 10; i++) {
        await dao.insertItem(
          makeChick(id: 'c$i', hatchDate: DateTime(2024, 1, i)),
        );
      }

      final results = await dao.watchRecent(userId, limit: 3).first;
      expect(results.length, equals(3));
      expect(results.first.id, equals('c10'));
    });

    test('excludes soft-deleted chicks', () async {
      await dao.insertItem(
        makeChick(id: 'c1', hatchDate: DateTime(2024, 1, 1)),
      );
      await dao.insertItem(
        makeChick(id: 'c2', hatchDate: DateTime(2024, 1, 2), isDeleted: true),
      );

      final results = await dao.watchRecent(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('c1'));
    });

    test('only returns chicks for given userId', () async {
      await dao.insertItem(
        makeChick(id: 'c1', hatchDate: DateTime(2024, 1, 1)),
      );
      await dao.insertItem(
        makeChick(
          id: 'c2',
          user: 'other-user',
          hatchDate: DateTime(2024, 1, 2),
        ),
      );

      final results = await dao.watchRecent(userId).first;
      expect(results.length, equals(1));
    });

    test('returns empty list when no chicks exist', () async {
      final results = await dao.watchRecent(userId).first;
      expect(results, isEmpty);
    });
  });

  group('watchUnweanedCount', () {
    test('counts chicks older than 60 days without birdId', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 90));

      await dao.insertItem(makeChick(id: 'c1', hatchDate: oldDate));
      await dao.insertItem(makeChick(id: 'c2', hatchDate: oldDate));

      final count = await dao.watchUnweanedCount(userId).first;
      expect(count, equals(2));
    });

    test('excludes chicks younger than 60 days', () async {
      final recentDate = DateTime.now().subtract(const Duration(days: 30));
      final oldDate = DateTime.now().subtract(const Duration(days: 90));

      await dao.insertItem(makeChick(id: 'c1', hatchDate: oldDate));
      await dao.insertItem(makeChick(id: 'c2', hatchDate: recentDate));

      final count = await dao.watchUnweanedCount(userId).first;
      expect(count, equals(1));
    });

    test('excludes chicks with birdId (already moved)', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 90));

      await dao.insertItem(makeChick(id: 'c1', hatchDate: oldDate));
      await dao.insertItem(
        makeChick(id: 'c2', hatchDate: oldDate, birdId: 'bird-1'),
      );

      final count = await dao.watchUnweanedCount(userId).first;
      expect(count, equals(1));
    });

    test('excludes unhealthy chicks', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 90));

      await dao.insertItem(makeChick(id: 'c1', hatchDate: oldDate));
      await dao.insertItem(
        makeChick(
          id: 'c2',
          hatchDate: oldDate,
          healthStatus: ChickHealthStatus.deceased,
        ),
      );

      final count = await dao.watchUnweanedCount(userId).first;
      expect(count, equals(1));
    });

    test('excludes soft-deleted chicks', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 90));

      await dao.insertItem(makeChick(id: 'c1', hatchDate: oldDate));
      await dao.insertItem(
        makeChick(id: 'c2', hatchDate: oldDate, isDeleted: true),
      );

      final count = await dao.watchUnweanedCount(userId).first;
      expect(count, equals(1));
    });

    test('returns 0 when no unweaned chicks exist', () async {
      final count = await dao.watchUnweanedCount(userId).first;
      expect(count, equals(0));
    });
  });
}
