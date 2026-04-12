import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

void main() {
  late AppDatabase db;
  late EggsDao dao;

  const userId = 'user-1';

  Egg makeEgg({
    String id = 'egg-1',
    String user = userId,
    EggStatus status = EggStatus.incubating,
    DateTime? layDate,
    bool isDeleted = false,
  }) {
    return Egg(
      id: id,
      userId: user,
      status: status,
      layDate: layDate ?? DateTime(2024, 1, 1),
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.eggsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchIncubatingLimited', () {
    test('returns only incubating eggs', () async {
      await dao.insertItem(makeEgg(id: 'e1', status: EggStatus.incubating));
      await dao.insertItem(makeEgg(id: 'e2', status: EggStatus.hatched));
      await dao.insertItem(makeEgg(id: 'e3', status: EggStatus.laid));

      final results = await dao.watchIncubatingLimited(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('e1'));
    });

    test('respects limit parameter', () async {
      for (var i = 1; i <= 10; i++) {
        await dao.insertItem(makeEgg(id: 'e$i', layDate: DateTime(2024, 1, i)));
      }

      final results = await dao.watchIncubatingLimited(userId, limit: 3).first;
      expect(results.length, equals(3));
    });

    test('orders by layDate ascending (oldest first)', () async {
      await dao.insertItem(makeEgg(id: 'e1', layDate: DateTime(2024, 1, 3)));
      await dao.insertItem(makeEgg(id: 'e2', layDate: DateTime(2024, 1, 1)));
      await dao.insertItem(makeEgg(id: 'e3', layDate: DateTime(2024, 1, 2)));

      final results = await dao.watchIncubatingLimited(userId).first;
      expect(results.map((e) => e.id).toList(), equals(['e2', 'e3', 'e1']));
    });

    test('excludes soft-deleted eggs', () async {
      await dao.insertItem(makeEgg(id: 'e1'));
      await dao.insertItem(makeEgg(id: 'e2', isDeleted: true));

      final results = await dao.watchIncubatingLimited(userId).first;
      expect(results.length, equals(1));
    });

    test('only returns eggs for given userId', () async {
      await dao.insertItem(makeEgg(id: 'e1'));
      await dao.insertItem(makeEgg(id: 'e2', user: 'other-user'));

      final results = await dao.watchIncubatingLimited(userId).first;
      expect(results.length, equals(1));
    });

    test('returns empty list when no incubating eggs exist', () async {
      await dao.insertItem(makeEgg(id: 'e1', status: EggStatus.hatched));

      final results = await dao.watchIncubatingLimited(userId).first;
      expect(results, isEmpty);
    });
  });
}
