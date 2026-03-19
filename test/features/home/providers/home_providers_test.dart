import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';

import '../../../helpers/mocks.dart';

class MockChicksDao extends Mock implements ChicksDao {}

class MockBreedingPairsDao extends Mock implements BreedingPairsDao {}

BreedingPair _pair({required String id, required BreedingStatus status}) {
  return BreedingPair(
    id: id,
    userId: 'user-1',
    status: status,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Chick _chick({
  required String id,
  DateTime? hatchDate,
  DateTime? createdAt,
  String? birdId,
  ChickHealthStatus status = ChickHealthStatus.healthy,
}) {
  return Chick(
    id: id,
    userId: 'user-1',
    hatchDate: hatchDate,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    birdId: birdId,
    healthStatus: status,
  );
}

Egg _egg({
  required String id,
  required DateTime layDate,
  EggStatus status = EggStatus.laid,
}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: layDate,
    status: status,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  const userId = 'user-1';

  late MockEggsDao mockEggsDao;
  late MockChicksDao mockChicksDao;
  late MockBreedingPairsDao mockBreedingPairsDao;

  setUp(() {
    mockEggsDao = MockEggsDao();
    mockChicksDao = MockChicksDao();
    mockBreedingPairsDao = MockBreedingPairsDao();
  });

  group('dashboardStatsProvider', () {
    test('returns AsyncLoading when any source is loading', () {
      final container = ProviderContainer(
        overrides: [
          birdCountProvider(userId).overrideWith((_) => const Stream.empty()),
          eggCountProvider(userId).overrideWith((_) => Stream.value(2)),
          chickCountProvider(userId).overrideWith((_) => Stream.value(3)),
          activeBreedingCountProvider(
            userId,
          ).overrideWith((_) => Stream.value(4)),
          incubatingEggCountProvider(
            userId,
          ).overrideWith((_) => Stream.value(5)),
        ],
      );
      addTearDown(container.dispose);

      final value = container.read(dashboardStatsProvider(userId));
      expect(value, isA<AsyncLoading<DashboardStats>>());
    });

    test('falls back to 0 when a source errors', () async {
      final container = ProviderContainer(
        overrides: [
          birdCountProvider(userId).overrideWith((_) => Stream.value(1)),
          eggCountProvider(
            userId,
          ).overrideWith((_) => Stream<int>.error(StateError('count failed'))),
          chickCountProvider(userId).overrideWith((_) => Stream.value(3)),
          activeBreedingCountProvider(
            userId,
          ).overrideWith((_) => Stream.value(4)),
          incubatingEggCountProvider(
            userId,
          ).overrideWith((_) => Stream.value(5)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(birdCountProvider(userId), (_, __) {});
      await container.read(birdCountProvider(userId).future);
      container.listen(chickCountProvider(userId), (_, __) {});
      await container.read(chickCountProvider(userId).future);
      container.listen(activeBreedingCountProvider(userId), (_, __) {});
      await container.read(activeBreedingCountProvider(userId).future);
      container.listen(incubatingEggCountProvider(userId), (_, __) {});
      await container.read(incubatingEggCountProvider(userId).future);
      await Future<void>.delayed(Duration.zero);
      container.listen(eggCountProvider(userId), (_, __) {});
      await expectLater(
        container.read(eggCountProvider(userId).future),
        throwsStateError,
      );

      final value = container.read(dashboardStatsProvider(userId));
      expect(value.hasValue, isTrue);
      final stats = value.requireValue;
      expect(stats.totalBirds, 1);
      expect(stats.totalEggs, 0);
      expect(stats.totalChicks, 3);
      expect(stats.activeBreedings, 4);
      expect(stats.incubatingEggs, 5);
    });

    test('returns AsyncData when all counts are ready', () async {
      final container = ProviderContainer(
        overrides: [
          birdCountProvider(userId).overrideWith((_) => Stream.value(10)),
          eggCountProvider(userId).overrideWith((_) => Stream.value(7)),
          chickCountProvider(userId).overrideWith((_) => Stream.value(4)),
          activeBreedingCountProvider(
            userId,
          ).overrideWith((_) => Stream.value(2)),
          incubatingEggCountProvider(
            userId,
          ).overrideWith((_) => Stream.value(3)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(birdCountProvider(userId), (_, __) {});
      await container.read(birdCountProvider(userId).future);
      container.listen(eggCountProvider(userId), (_, __) {});
      await container.read(eggCountProvider(userId).future);
      container.listen(chickCountProvider(userId), (_, __) {});
      await container.read(chickCountProvider(userId).future);
      container.listen(activeBreedingCountProvider(userId), (_, __) {});
      await container.read(activeBreedingCountProvider(userId).future);
      container.listen(incubatingEggCountProvider(userId), (_, __) {});
      await container.read(incubatingEggCountProvider(userId).future);
      final asyncStats = container.read(dashboardStatsProvider(userId));
      expect(asyncStats.hasValue, isTrue);
      final stats = asyncStats.requireValue;
      expect(stats.totalBirds, 10);
      expect(stats.totalEggs, 7);
      expect(stats.totalChicks, 4);
      expect(stats.activeBreedings, 2);
      expect(stats.incubatingEggs, 3);
    });
  });

  group('recentChicksProvider', () {
    test('passes through DAO watchRecent stream', () async {
      // DAO handles sorting and limit; provider just wires DAO to UI
      final sortedChicks = [
        _chick(id: 'c4', hatchDate: DateTime(2024, 1, 15)),
        _chick(id: 'c6', hatchDate: DateTime(2024, 1, 13)),
        _chick(id: 'c2', hatchDate: DateTime(2024, 1, 12)),
        _chick(id: 'c1', hatchDate: DateTime(2024, 1, 10)),
        _chick(id: 'c3', hatchDate: DateTime(2024, 1, 8)),
      ];
      when(
        () => mockChicksDao.watchRecent(userId, limit: 5),
      ).thenAnswer((_) => Stream.value(sortedChicks));

      final container = ProviderContainer(
        overrides: [chicksDaoProvider.overrideWithValue(mockChicksDao)],
      );
      addTearDown(container.dispose);

      container.listen(recentChicksProvider(userId), (_, __) {});
      await container.read(recentChicksProvider(userId).future);
      final asyncResult = container.read(recentChicksProvider(userId));
      expect(asyncResult.hasValue, isTrue);
      final result = asyncResult.requireValue;
      expect(result, hasLength(5));
      expect(result.first.id, 'c4');
    });

    test('handles empty chick list from DAO', () async {
      when(
        () => mockChicksDao.watchRecent(userId, limit: 5),
      ).thenAnswer((_) => Stream.value([]));

      final container = ProviderContainer(
        overrides: [chicksDaoProvider.overrideWithValue(mockChicksDao)],
      );
      addTearDown(container.dispose);

      container.listen(recentChicksProvider(userId), (_, __) {});
      await container.read(recentChicksProvider(userId).future);
      final asyncResult = container.read(recentChicksProvider(userId));
      expect(asyncResult.hasValue, isTrue);
      expect(asyncResult.requireValue, isEmpty);
    });
  });

  group('activeBreedingsForDashboardProvider', () {
    test('passes through DAO watchActiveLimited stream', () async {
      // DAO handles filtering and limit; provider just wires DAO to UI
      final activePairs = [
        _pair(id: 'p1', status: BreedingStatus.active),
        _pair(id: 'p2', status: BreedingStatus.ongoing),
        _pair(id: 'p3', status: BreedingStatus.active),
      ];
      when(
        () => mockBreedingPairsDao.watchActiveLimited(userId, limit: 3),
      ).thenAnswer((_) => Stream.value(activePairs));

      final container = ProviderContainer(
        overrides: [
          breedingPairsDaoProvider.overrideWithValue(mockBreedingPairsDao),
        ],
      );
      addTearDown(container.dispose);

      container.listen(activeBreedingsForDashboardProvider(userId), (_, __) {});
      await container.read(activeBreedingsForDashboardProvider(userId).future);
      final asyncResult = container.read(
        activeBreedingsForDashboardProvider(userId),
      );
      expect(asyncResult.hasValue, isTrue);
      final result = asyncResult.requireValue;
      expect(result.map((e) => e.id), ['p1', 'p2', 'p3']);
    });
  });

  group('unweanedChicksCountProvider', () {
    test('passes through DAO watchUnweanedCount stream', () async {
      // DAO handles SQL COUNT with 60-day filter; provider just wires
      when(
        () => mockChicksDao.watchUnweanedCount(userId),
      ).thenAnswer((_) => Stream.value(3));

      final container = ProviderContainer(
        overrides: [chicksDaoProvider.overrideWithValue(mockChicksDao)],
      );
      addTearDown(container.dispose);

      container.listen(unweanedChicksCountProvider(userId), (_, __) {});
      await container.read(unweanedChicksCountProvider(userId).future);
      final asyncCount = container.read(unweanedChicksCountProvider(userId));
      expect(asyncCount.hasValue, isTrue);
      expect(asyncCount.requireValue, 3);
    });
  });

  group('incubatingEggsSummaryProvider', () {
    test('computes days remaining and sorts by nearest hatch', () async {
      final now = DateTime.now();
      // DAO returns incubating eggs already filtered; provider computes daysRemaining
      final incubatingEggs = [
        _egg(
          id: 'inc-3',
          layDate: now.subtract(const Duration(days: 17)),
          status: EggStatus.incubating,
        ),
        _egg(
          id: 'inc-1',
          layDate: now.subtract(const Duration(days: 16)),
          status: EggStatus.incubating,
        ),
        _egg(
          id: 'inc-4',
          layDate: now.subtract(const Duration(days: 12)),
          status: EggStatus.incubating,
        ),
      ];
      when(
        () => mockEggsDao.watchIncubatingLimited(userId, limit: 3),
      ).thenAnswer((_) => Stream.value(incubatingEggs));

      final container = ProviderContainer(
        overrides: [eggsDaoProvider.overrideWithValue(mockEggsDao)],
      );
      addTearDown(container.dispose);

      container.listen(incubatingEggsLimitedProvider(userId), (_, __) {});
      await container.read(incubatingEggsLimitedProvider(userId).future);
      final asyncResult = container.read(incubatingEggsSummaryProvider(userId));
      expect(asyncResult.hasValue, isTrue);
      final result = asyncResult.requireValue;

      expect(result, hasLength(3));
      expect(result.first.egg.id, 'inc-3');
      expect(result.every((s) => s.egg.status == EggStatus.incubating), isTrue);
      expect(result[0].daysRemaining <= result[1].daysRemaining, isTrue);
      expect(result[1].daysRemaining <= result[2].daysRemaining, isTrue);
    });
  });
}
