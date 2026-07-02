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
    String? clutchId,
    DateTime? hatchDate,
    bool isDeleted = false,
  }) {
    return Chick(
      id: id,
      userId: user,
      healthStatus: healthStatus,
      birdId: birdId,
      clutchId: clutchId,
      hatchDate: hatchDate,
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Insert a minimal parent bird row to satisfy FK constraints.
  Future<void> insertBird(String id) async {
    await db.customStatement(
      'INSERT OR IGNORE INTO birds (id, name, gender, user_id, status, species, is_deleted) '
      "VALUES ('$id', 'Test', 'male', 'user-1', 'alive', 'budgie', 0)",
    );
  }

  /// Insert a minimal breeding pair row for the top-pair JOIN tests.
  Future<void> insertBreedingPair(
    String id, {
    String user = userId,
    bool isDeleted = false,
  }) async {
    await db.customStatement(
      'INSERT OR IGNORE INTO breeding_pairs (id, user_id, status, is_deleted) '
      "VALUES ('$id', '$user', 'active', ${isDeleted ? 1 : 0})",
    );
  }

  /// Insert a minimal clutch row referencing [breedingId] for the
  /// top-pair JOIN tests.
  Future<void> insertClutch(
    String id,
    String? breedingId, {
    String user = userId,
    bool isDeleted = false,
  }) async {
    final breedingIdSql = breedingId == null ? 'NULL' : "'$breedingId'";
    await db.customStatement(
      'INSERT OR IGNORE INTO clutches (id, user_id, breeding_id, status, is_deleted) '
      "VALUES ('$id', '$user', $breedingIdSql, 'active', ${isDeleted ? 1 : 0})",
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.chicksDao;
    // Pre-create parent bird referenced by test fixtures.
    await insertBird('bird-1');
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

  group('watchMostProductiveSeason', () {
    // Explicit UTC dates: mappers normalize DateTime to UTC on write/read,
    // so an ambiguous local DateTime crossing midnight can round-trip into
    // a different calendar year than the literal suggests.
    test('returns the year with the most hatched chicks', () async {
      await dao.insertItem(
        makeChick(id: 'c1', hatchDate: DateTime.utc(2025, 3, 1)),
      );
      await dao.insertItem(
        makeChick(id: 'c2', hatchDate: DateTime.utc(2025, 4, 1)),
      );
      await dao.insertItem(
        makeChick(id: 'c3', hatchDate: DateTime.utc(2024, 1, 1)),
      );

      final result = await dao.watchMostProductiveSeason(userId).first;

      expect(result?.year, equals(2025));
      expect(result?.count, equals(2));
    });

    test('breaks ties by the smaller year', () async {
      await dao.insertItem(
        makeChick(id: 'c1', hatchDate: DateTime.utc(2024, 1, 1)),
      );
      await dao.insertItem(
        makeChick(id: 'c2', hatchDate: DateTime.utc(2025, 1, 1)),
      );

      final result = await dao.watchMostProductiveSeason(userId).first;

      expect(result?.year, equals(2024));
    });

    test(
      'excludes chicks without a hatch date and soft-deleted chicks',
      () async {
        await dao.insertItem(
          makeChick(id: 'c1', hatchDate: DateTime.utc(2025, 1, 1)),
        );
        await dao.insertItem(makeChick(id: 'c2', hatchDate: null));
        await dao.insertItem(
          makeChick(
            id: 'c3',
            hatchDate: DateTime.utc(2025, 1, 1),
            isDeleted: true,
          ),
        );

        final result = await dao.watchMostProductiveSeason(userId).first;

        expect(result?.year, equals(2025));
        expect(result?.count, equals(1));
      },
    );

    test('returns null when there are no chicks', () async {
      final result = await dao.watchMostProductiveSeason(userId).first;
      expect(result, isNull);
    });
  });

  group('watchTopPairByChickCount', () {
    test('returns the breeding pair with the most chicks', () async {
      await insertBreedingPair('pair-1');
      await insertBreedingPair('pair-2');
      await insertClutch('clutch-1', 'pair-1');
      await insertClutch('clutch-2', 'pair-2');
      await dao.insertItem(makeChick(id: 'c1', clutchId: 'clutch-1'));
      await dao.insertItem(makeChick(id: 'c2', clutchId: 'clutch-1'));
      await dao.insertItem(makeChick(id: 'c3', clutchId: 'clutch-2'));

      final result = await dao.watchTopPairByChickCount(userId).first;

      expect(result?.pairId, equals('pair-1'));
      expect(result?.count, equals(2));
    });

    test('excludes chicks linked to a soft-deleted breeding pair', () async {
      await insertBreedingPair('pair-1', isDeleted: true);
      await insertClutch('clutch-1', 'pair-1');
      await dao.insertItem(makeChick(id: 'c1', clutchId: 'clutch-1'));

      final result = await dao.watchTopPairByChickCount(userId).first;

      expect(result, isNull);
    });

    test(
      'excludes chicks linked to a soft-deleted clutch even when the '
      'breeding pair is still live',
      () async {
        // A clutch can be soft-deleted (e.g. merged/corrected) while its
        // chicks and the breeding pair both stay live — those chicks must
        // not count toward the pair's "most productive pair" record.
        await insertBreedingPair('pair-1');
        await insertClutch('clutch-1', 'pair-1', isDeleted: true);
        await dao.insertItem(makeChick(id: 'c1', clutchId: 'clutch-1'));
        await dao.insertItem(makeChick(id: 'c2', clutchId: 'clutch-1'));

        final result = await dao.watchTopPairByChickCount(userId).first;

        expect(result, isNull);
      },
    );

    test('excludes chicks with no clutch or an unlinked clutch', () async {
      await insertClutch('clutch-1', null);
      await dao.insertItem(makeChick(id: 'c1', clutchId: 'clutch-1'));
      await dao.insertItem(makeChick(id: 'c2'));

      final result = await dao.watchTopPairByChickCount(userId).first;

      expect(result, isNull);
    });

    test('returns null when there are no chicks', () async {
      final result = await dao.watchTopPairByChickCount(userId).first;
      expect(result, isNull);
    });
  });

  group('watchDistinctHatchYears', () {
    test('returns the set of years present in hatch_date', () async {
      await dao.insertItem(
        makeChick(id: 'c1', hatchDate: DateTime.utc(2024, 3, 1)),
      );
      await dao.insertItem(
        makeChick(id: 'c2', hatchDate: DateTime.utc(2024, 6, 1)),
      );
      await dao.insertItem(
        makeChick(id: 'c3', hatchDate: DateTime.utc(2025, 1, 1)),
      );
      await dao.insertItem(makeChick(id: 'c4', hatchDate: null));

      final result = await dao.watchDistinctHatchYears(userId).first;

      expect(result, equals({2024, 2025}));
    });

    test('excludes soft-deleted chicks', () async {
      await dao.insertItem(
        makeChick(id: 'c1', hatchDate: DateTime.utc(2024, 1, 1)),
      );
      await dao.insertItem(
        makeChick(
          id: 'c2',
          hatchDate: DateTime.utc(2025, 1, 1),
          isDeleted: true,
        ),
      );

      final result = await dao.watchDistinctHatchYears(userId).first;

      expect(result, equals({2024}));
    });

    test('returns an empty set when there are no chicks', () async {
      final result = await dao.watchDistinctHatchYears(userId).first;
      expect(result, isEmpty);
    });
  });

  group('watchSeasonChickStats', () {
    test('returns total and live counts for the given year', () async {
      await dao.insertItem(
        makeChick(
          id: 'c1',
          hatchDate: DateTime.utc(2024, 3, 1),
          healthStatus: ChickHealthStatus.healthy,
        ),
      );
      await dao.insertItem(
        makeChick(
          id: 'c2',
          hatchDate: DateTime.utc(2024, 4, 1),
          healthStatus: ChickHealthStatus.deceased,
        ),
      );
      await dao.insertItem(
        makeChick(
          id: 'c3',
          hatchDate: DateTime.utc(2025, 1, 1),
          healthStatus: ChickHealthStatus.healthy,
        ),
      );

      final result = await dao.watchSeasonChickStats(userId, 2024).first;

      expect(result.total, equals(2));
      expect(result.live, equals(1));
    });

    test('returns zero counts when no chicks match the year', () async {
      final result = await dao.watchSeasonChickStats(userId, 2024).first;
      expect(result.total, equals(0));
      expect(result.live, equals(0));
    });
  });

  group('watchPeriodChickStats', () {
    test('returns total, deceased within the [from, to) window', () async {
      await dao.insertItem(
        makeChick(
          id: 'c1',
          hatchDate: DateTime.utc(2025, 3, 5),
          healthStatus: ChickHealthStatus.healthy,
        ),
      );
      await dao.insertItem(
        makeChick(
          id: 'c2',
          hatchDate: DateTime.utc(2025, 3, 10),
          healthStatus: ChickHealthStatus.deceased,
        ),
      );
      // Exactly at the exclusive upper bound — must be excluded.
      await dao.insertItem(
        makeChick(id: 'c3', hatchDate: DateTime.utc(2025, 4, 1)),
      );
      // Before the window — must be excluded.
      await dao.insertItem(
        makeChick(id: 'c4', hatchDate: DateTime.utc(2025, 2, 28)),
      );

      final result = await dao
          .watchPeriodChickStats(
            userId,
            DateTime.utc(2025, 3, 1),
            DateTime.utc(2025, 4, 1),
          )
          .first;

      expect(result.total, equals(2));
      expect(result.deceased, equals(1));
    });

    test('returns zero counts when nothing falls in the window', () async {
      final result = await dao
          .watchPeriodChickStats(
            userId,
            DateTime.utc(2025, 3, 1),
            DateTime.utc(2025, 4, 1),
          )
          .first;

      expect(result.total, equals(0));
      expect(result.deceased, equals(0));
    });
  });
}
