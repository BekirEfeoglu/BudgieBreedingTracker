import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

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
    String? incubationId = 'inc-1',
  }) {
    return Egg(
      id: id,
      userId: user,
      status: status,
      layDate: layDate ?? DateTime(2024, 1, 1),
      incubationId: incubationId,
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  Incubation makeIncubation({
    required String id,
    Species species = Species.budgie,
  }) {
    return Incubation(
      id: id,
      userId: userId,
      species: species,
      status: IncubationStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.eggsDao;
    await db.incubationsDao.insertItem(makeIncubation(id: 'inc-1'));
  });

  tearDown(() async {
    await db.close();
  });

  group('watchIncubatingLimited', () {
    test('returns active eggs in an incubation', () async {
      await dao.insertItem(
        makeEgg(
          id: 'e1',
          status: EggStatus.laid,
          layDate: DateTime(2024, 1, 1),
        ),
      );
      await dao.insertItem(
        makeEgg(
          id: 'e2',
          status: EggStatus.fertile,
          layDate: DateTime(2024, 1, 2),
        ),
      );
      await dao.insertItem(
        makeEgg(
          id: 'e3',
          status: EggStatus.incubating,
          layDate: DateTime(2024, 1, 3),
        ),
      );
      await dao.insertItem(makeEgg(id: 'e4', status: EggStatus.hatched));
      await dao.insertItem(makeEgg(id: 'e5', status: EggStatus.infertile));
      await dao.insertItem(makeEgg(id: 'e6', status: EggStatus.damaged));
      await dao.insertItem(makeEgg(id: 'e7', status: EggStatus.discarded));
      await dao.insertItem(
        makeEgg(id: 'e8', status: EggStatus.laid, incubationId: null),
      );

      final results = await dao.watchIncubatingLimited(userId).first;
      expect(results.map((e) => e.id), equals(['e1', 'e2', 'e3']));
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

  group('incubating egg counts', () {
    test('counts active eggs in an incubation', () async {
      await dao.insertItem(makeEgg(id: 'e1', status: EggStatus.laid));
      await dao.insertItem(makeEgg(id: 'e2', status: EggStatus.fertile));
      await dao.insertItem(makeEgg(id: 'e3', status: EggStatus.incubating));
      await dao.insertItem(makeEgg(id: 'e4', status: EggStatus.infertile));
      await dao.insertItem(
        makeEgg(id: 'e5', status: EggStatus.laid, incubationId: null),
      );

      final count = await dao.watchIncubatingCount(userId).first;
      expect(count, 3);
    });

    test('getIncubating returns active eggs in an incubation', () async {
      await dao.insertItem(makeEgg(id: 'e1', status: EggStatus.laid));
      await dao.insertItem(makeEgg(id: 'e2', status: EggStatus.fertile));
      await dao.insertItem(makeEgg(id: 'e3', status: EggStatus.incubating));
      await dao.insertItem(makeEgg(id: 'e4', status: EggStatus.discarded));

      final results = await dao.getIncubating(userId);
      expect(results.map((e) => e.id), unorderedEquals(['e1', 'e2', 'e3']));
    });
  });

  group('watchMonthlyProductionBySpecies', () {
    test('counts non-deleted eggs joined by incubation species', () async {
      await db.incubationsDao.insertItem(
        makeIncubation(id: 'budgie-inc', species: Species.budgie),
      );
      await db.incubationsDao.insertItem(
        makeIncubation(id: 'canary-inc', species: Species.canary),
      );

      await dao.insertItem(
        makeEgg(
          id: 'e1',
          layDate: DateTime(2024, 1, 5),
          incubationId: 'budgie-inc',
        ),
      );
      await dao.insertItem(
        makeEgg(
          id: 'e2',
          layDate: DateTime(2024, 1, 6),
          incubationId: 'budgie-inc',
          isDeleted: true,
        ),
      );
      await dao.insertItem(
        makeEgg(
          id: 'e3',
          layDate: DateTime(2024, 1, 7),
          incubationId: 'canary-inc',
        ),
      );
      await dao.insertItem(
        makeEgg(
          id: 'e4',
          layDate: DateTime(2024, 2, 1),
          incubationId: 'budgie-inc',
        ),
      );

      final results = await dao
          .watchMonthlyProductionBySpecies(userId, Species.budgie.toJson())
          .first;

      expect(results, equals({'2024-01': 1, '2024-02': 1}));
    });
  });

  group('watchMonthlyFertility', () {
    test('aggregates fertile/hatched/infertile counts per month', () async {
      // Same month — January 2024
      await dao.insertItem(
        makeEgg(
          id: 'jan-fertile',
          layDate: DateTime(2024, 1, 5),
          status: EggStatus.fertile,
        ),
      );
      await dao.insertItem(
        makeEgg(
          id: 'jan-hatched',
          layDate: DateTime(2024, 1, 10),
          status: EggStatus.hatched,
        ),
      );
      await dao.insertItem(
        makeEgg(
          id: 'jan-infertile',
          layDate: DateTime(2024, 1, 15),
          status: EggStatus.infertile,
        ),
      );
      // status: laid → undetermined, excluded from both fertile and total.
      await dao.insertItem(
        makeEgg(
          id: 'jan-laid',
          layDate: DateTime(2024, 1, 20),
          status: EggStatus.laid,
        ),
      );
      // Soft-deleted → excluded entirely.
      await dao.insertItem(
        makeEgg(
          id: 'jan-deleted',
          layDate: DateTime(2024, 1, 22),
          status: EggStatus.fertile,
          isDeleted: true,
        ),
      );
      // Different month — February 2024
      await dao.insertItem(
        makeEgg(
          id: 'feb-fertile',
          layDate: DateTime(2024, 2, 3),
          status: EggStatus.fertile,
        ),
      );

      final result = await dao.watchMonthlyFertility(userId).first;

      // Jan: fertile + hatched = 2 fertile, fertile + hatched + infertile = 3 total
      expect(result['2024-01']?.fertile, 2);
      expect(result['2024-01']?.total, 3);
      // Feb: 1 fertile, 1 total
      expect(result['2024-02']?.fertile, 1);
      expect(result['2024-02']?.total, 1);
    });

    test('filters by species via incubation join when species provided',
        () async {
      await db.incubationsDao.insertItem(
        makeIncubation(id: 'budgie-inc', species: Species.budgie),
      );
      await db.incubationsDao.insertItem(
        makeIncubation(id: 'canary-inc', species: Species.canary),
      );

      await dao.insertItem(
        makeEgg(
          id: 'budgie-fertile',
          layDate: DateTime(2024, 1, 5),
          incubationId: 'budgie-inc',
          status: EggStatus.fertile,
        ),
      );
      await dao.insertItem(
        makeEgg(
          id: 'canary-fertile',
          layDate: DateTime(2024, 1, 6),
          incubationId: 'canary-inc',
          status: EggStatus.fertile,
        ),
      );
      await dao.insertItem(
        makeEgg(
          id: 'canary-infertile',
          layDate: DateTime(2024, 1, 7),
          incubationId: 'canary-inc',
          status: EggStatus.infertile,
        ),
      );

      final result = await dao
          .watchMonthlyFertility(userId, species: Species.budgie.toJson())
          .first;

      // Only the budgie incubation row counts; canary rows ignored.
      expect(result['2024-01']?.fertile, 1);
      expect(result['2024-01']?.total, 1);
    });

    test('returns empty map when user has no eggs', () async {
      final result = await dao.watchMonthlyFertility(userId).first;
      expect(result, isEmpty);
    });
  });
}
