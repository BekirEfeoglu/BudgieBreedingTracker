import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/providers/entity_count_providers.dart';

class _MockBirdsDao extends Mock implements BirdsDao {}

class _MockEggsDao extends Mock implements EggsDao {}

class _MockChicksDao extends Mock implements ChicksDao {}

class _MockBreedingPairsDao extends Mock implements BreedingPairsDao {}

void main() {
  late _MockBirdsDao birdsDao;
  late _MockEggsDao eggsDao;
  late _MockChicksDao chicksDao;
  late _MockBreedingPairsDao breedingPairsDao;

  const userId = 'user-1';

  setUp(() {
    birdsDao = _MockBirdsDao();
    eggsDao = _MockEggsDao();
    chicksDao = _MockChicksDao();
    breedingPairsDao = _MockBreedingPairsDao();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        birdsDaoProvider.overrideWithValue(birdsDao),
        eggsDaoProvider.overrideWithValue(eggsDao),
        chicksDaoProvider.overrideWithValue(chicksDao),
        breedingPairsDaoProvider.overrideWithValue(breedingPairsDao),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('count providers forward to DAO watchers', () {
    test('birdCountProvider -> birdsDao.watchCount', () async {
      when(() => birdsDao.watchCount(userId))
          .thenAnswer((_) => Stream.value(7));

      final container = makeContainer();
      container.listen(birdCountProvider(userId), (_, __) {});
      expect(await container.read(birdCountProvider(userId).future), 7);
      verify(() => birdsDao.watchCount(userId)).called(1);
    });

    test('eggCountProvider -> eggsDao.watchCount', () async {
      when(() => eggsDao.watchCount(userId))
          .thenAnswer((_) => Stream.value(12));

      final container = makeContainer();
      container.listen(eggCountProvider(userId), (_, __) {});
      expect(await container.read(eggCountProvider(userId).future), 12);
    });

    test('chickCountProvider -> chicksDao.watchCount', () async {
      when(() => chicksDao.watchCount(userId))
          .thenAnswer((_) => Stream.value(3));

      final container = makeContainer();
      container.listen(chickCountProvider(userId), (_, __) {});
      expect(await container.read(chickCountProvider(userId).future), 3);
    });

    test('activeBreedingCountProvider -> watchActiveCount', () async {
      when(() => breedingPairsDao.watchActiveCount(userId))
          .thenAnswer((_) => Stream.value(2));

      final container = makeContainer();
      container.listen(activeBreedingCountProvider(userId), (_, __) {});
      expect(
        await container.read(activeBreedingCountProvider(userId).future),
        2,
      );
    });

    test('incubatingEggCountProvider -> watchIncubatingCount', () async {
      when(() => eggsDao.watchIncubatingCount(userId))
          .thenAnswer((_) => Stream.value(4));

      final container = makeContainer();
      container.listen(incubatingEggCountProvider(userId), (_, __) {});
      expect(
        await container.read(incubatingEggCountProvider(userId).future),
        4,
      );
    });

    test('unweanedChicksCountProvider -> watchUnweanedCount', () async {
      when(() => chicksDao.watchUnweanedCount(userId))
          .thenAnswer((_) => Stream.value(5));

      final container = makeContainer();
      container.listen(unweanedChicksCountProvider(userId), (_, __) {});
      expect(
        await container.read(unweanedChicksCountProvider(userId).future),
        5,
      );
      // The midnight-refresh provider fires an initial tick that re-evaluates
      // the stream provider; call count may be >=1 rather than exactly 1.
      verify(() => chicksDao.watchUnweanedCount(userId)).called(greaterThan(0));
    });

    test('family distinguishes different users', () async {
      when(() => birdsDao.watchCount('user-a'))
          .thenAnswer((_) => Stream.value(1));
      when(() => birdsDao.watchCount('user-b'))
          .thenAnswer((_) => Stream.value(9));

      final container = makeContainer();
      container.listen(birdCountProvider('user-a'), (_, __) {});
      container.listen(birdCountProvider('user-b'), (_, __) {});
      expect(await container.read(birdCountProvider('user-a').future), 1);
      expect(await container.read(birdCountProvider('user-b').future), 9);
    });
  });

  group('dashboardStatsProvider', () {
    test('aggregates counts into DashboardStats', () async {
      final container = ProviderContainer(
        overrides: [
          birdCountProvider(userId).overrideWith((_) => Stream.value(10)),
          eggCountProvider(userId).overrideWith((_) => Stream.value(5)),
          chickCountProvider(userId).overrideWith((_) => Stream.value(3)),
          activeBreedingCountProvider(userId)
              .overrideWith((_) => Stream.value(2)),
          incubatingEggCountProvider(userId)
              .overrideWith((_) => Stream.value(4)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(birdCountProvider(userId), (_, __) {});
      container.listen(eggCountProvider(userId), (_, __) {});
      container.listen(chickCountProvider(userId), (_, __) {});
      container.listen(activeBreedingCountProvider(userId), (_, __) {});
      container.listen(incubatingEggCountProvider(userId), (_, __) {});
      await container.read(birdCountProvider(userId).future);
      await container.read(eggCountProvider(userId).future);
      await container.read(chickCountProvider(userId).future);
      await container.read(activeBreedingCountProvider(userId).future);
      await container.read(incubatingEggCountProvider(userId).future);

      final stats = container.read(dashboardStatsProvider(userId));
      expect(stats, isA<AsyncData<DashboardStats>>());
      expect(
        stats.value,
        const DashboardStats(
          totalBirds: 10,
          totalEggs: 5,
          totalChicks: 3,
          activeBreedings: 2,
          incubatingEggs: 4,
        ),
      );
    });

    test('returns AsyncLoading when any source has no value yet', () {
      final container = ProviderContainer(
        overrides: [
          birdCountProvider(userId).overrideWith((_) => const Stream.empty()),
          eggCountProvider(userId).overrideWith((_) => Stream.value(5)),
          chickCountProvider(userId).overrideWith((_) => Stream.value(3)),
          activeBreedingCountProvider(userId)
              .overrideWith((_) => Stream.value(2)),
          incubatingEggCountProvider(userId)
              .overrideWith((_) => Stream.value(4)),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(dashboardStatsProvider(userId));
      expect(stats, isA<AsyncLoading<DashboardStats>>());
    });

    test('falls back to 0 for an errored count', () async {
      final container = ProviderContainer(
        overrides: [
          birdCountProvider(userId)
              .overrideWith((_) => Stream<int>.error(StateError('boom'))),
          eggCountProvider(userId).overrideWith((_) => Stream.value(2)),
          chickCountProvider(userId).overrideWith((_) => Stream.value(1)),
          activeBreedingCountProvider(userId)
              .overrideWith((_) => Stream.value(0)),
          incubatingEggCountProvider(userId)
              .overrideWith((_) => Stream.value(0)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(birdCountProvider(userId), (_, __) {});
      container.listen(eggCountProvider(userId), (_, __) {});
      container.listen(chickCountProvider(userId), (_, __) {});
      container.listen(activeBreedingCountProvider(userId), (_, __) {});
      container.listen(incubatingEggCountProvider(userId), (_, __) {});
      await expectLater(
        container.read(birdCountProvider(userId).future),
        throwsStateError,
      );
      await container.read(eggCountProvider(userId).future);
      await container.read(chickCountProvider(userId).future);
      await container.read(activeBreedingCountProvider(userId).future);
      await container.read(incubatingEggCountProvider(userId).future);

      final stats = container.read(dashboardStatsProvider(userId));
      expect(stats, isA<AsyncData<DashboardStats>>());
      expect(stats.value!.totalBirds, 0);
      expect(stats.value!.totalEggs, 2);
      expect(stats.value!.totalChicks, 1);
    });
  });
}
