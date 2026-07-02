import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/providers/entity_count_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_trend_providers.dart';

const _userId = 'user-1';

class _MockEggsDao extends Mock implements EggsDao {}

class _MockChicksDao extends Mock implements ChicksDao {}

Egg _egg({
  required String id,
  required DateTime layDate,
  EggStatus status = EggStatus.laid,
}) {
  return Egg(
    id: id,
    userId: _userId,
    layDate: layDate,
    status: status,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Chick _chick({
  required String id,
  ChickHealthStatus health = ChickHealthStatus.healthy,
  DateTime? hatchDate,
}) {
  return Chick(
    id: id,
    userId: _userId,
    healthStatus: health,
    hatchDate: hatchDate,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

BreedingPair _pair({
  required String id,
  required BreedingStatus status,
  DateTime? pairingDate,
}) {
  return BreedingPair(
    id: id,
    userId: _userId,
    status: status,
    pairingDate: pairingDate,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

/// Creates a container with DAO-mocked period stats and a (possibly
/// loading) trend override. `quickInsightsProvider` now reads
/// `eggsDaoProvider.watchPeriodEggStats` / `chicksDaoProvider
/// .watchPeriodChickStats` / `activeBreedingCountProvider` directly
/// (SQL-aggregate) instead of the full eggs/chicks/pairs streams — the
/// mocks below compute the same aggregate a real SQL query would produce
/// for these fixtures (all dated "now", so always within any default
/// period window; period-boundary filtering itself is covered by
/// test/data/local/database/daos/eggs_dao_test.dart and
/// chicks_dao_test.dart).
ProviderContainer _container({
  List<Egg> eggs = const [],
  List<Chick> chicks = const [],
  List<BreedingPair> pairs = const [],
  AsyncValue<TrendStats>? trendOverride,
}) {
  final eggsDao = _MockEggsDao();
  final fertile = eggs
      .where(
        (e) => e.status == EggStatus.fertile || e.status == EggStatus.hatched,
      )
      .length;
  final infertile = eggs.where((e) => e.status == EggStatus.infertile).length;
  when(() => eggsDao.watchPeriodEggStats(any(), any(), any())).thenAnswer(
    (_) => Stream.value((
      total: eggs.length,
      fertile: fertile,
      infertile: infertile,
    )),
  );

  final chicksDao = _MockChicksDao();
  final deceased = chicks
      .where((c) => c.healthStatus == ChickHealthStatus.deceased)
      .length;
  when(
    () => chicksDao.watchPeriodChickStats(any(), any(), any()),
  ).thenAnswer((_) => Stream.value((total: chicks.length, deceased: deceased)));

  final activePairCount = pairs
      .where(
        (p) =>
            p.status == BreedingStatus.active ||
            p.status == BreedingStatus.ongoing,
      )
      .length;

  return ProviderContainer(
    overrides: [
      eggsDaoProvider.overrideWithValue(eggsDao),
      chicksDaoProvider.overrideWithValue(chicksDao),
      activeBreedingCountProvider(
        _userId,
      ).overrideWith((_) => Stream.value(activePairCount)),
      trendStatsProvider(
        _userId,
      ).overrideWithValue(trendOverride ?? const AsyncLoading()),
    ],
  );
}

Future<void> _awaitInsights(ProviderContainer container) async {
  container.listen(quickInsightsProvider(_userId), (_, __) {});
  // 3 independent Stream.value-backed providers (eggStats, chickStats,
  // activeBreedingCount) need to settle.
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('quickInsightsProvider', () {
    test('egg production insight with positive trend', () async {
      final now = DateTime.now();
      final container = _container(
        eggs: [
          _egg(id: 'e1', layDate: now, status: EggStatus.fertile),
          _egg(id: 'e2', layDate: now, status: EggStatus.incubating),
        ],
        trendOverride: const AsyncData(TrendStats(eggsTrend: 25)),
      );
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      expect(value.hasValue, isTrue);
      final insights = value.requireValue;
      expect(
        insights.any((i) => i.sentiment == InsightSentiment.positive),
        isTrue,
      );
    });

    test('egg production insight with negative trend', () async {
      final now = DateTime.now();
      final container = _container(
        eggs: [_egg(id: 'e1', layDate: now, status: EggStatus.laid)],
        trendOverride: const AsyncData(TrendStats(eggsTrend: -30)),
      );
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      expect(
        insights.any((i) => i.sentiment == InsightSentiment.negative),
        isTrue,
      );
    });

    test('egg insight is neutral when trend is loading', () async {
      final now = DateTime.now();
      final container = _container(
        eggs: [_egg(id: 'e1', layDate: now, status: EggStatus.laid)],
      );
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      expect(insights.first.sentiment, InsightSentiment.neutral);
    });

    test('fertility rate positive when >= 50%', () async {
      final now = DateTime.now();
      final container = _container(
        eggs: [
          _egg(id: 'e1', layDate: now, status: EggStatus.fertile),
          _egg(id: 'e2', layDate: now, status: EggStatus.hatched),
          _egg(id: 'e3', layDate: now, status: EggStatus.infertile),
        ],
      );
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      // 2 fertile out of 3 checked => 67% >= 50% => positive
      final fertilityInsight = insights.where(
        (i) => i.sentiment == InsightSentiment.positive,
      );
      expect(fertilityInsight, isNotEmpty);
    });

    test('fertility rate negative when < 50%', () async {
      final now = DateTime.now();
      final container = _container(
        eggs: [
          _egg(id: 'e1', layDate: now, status: EggStatus.fertile),
          _egg(id: 'e2', layDate: now, status: EggStatus.infertile),
          _egg(id: 'e3', layDate: now, status: EggStatus.infertile),
        ],
      );
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      // 1 fertile out of 3 checked => 33% < 50% => negative
      final negativeInsights = insights.where(
        (i) => i.sentiment == InsightSentiment.negative,
      );
      expect(negativeInsights, isNotEmpty);
    });

    test('chick survival positive when >= 70%', () async {
      final now = DateTime.now();
      final container = _container(
        chicks: [
          _chick(id: 'c1', hatchDate: now),
          _chick(id: 'c2', hatchDate: now),
          _chick(id: 'c3', hatchDate: now),
          _chick(id: 'c4', hatchDate: now, health: ChickHealthStatus.deceased),
        ],
      );
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      // 3 survived out of 4 => 75% >= 70% => positive
      final positiveInsights = insights.where(
        (i) => i.sentiment == InsightSentiment.positive,
      );
      expect(positiveInsights, isNotEmpty);
    });

    test('chick survival negative when < 70%', () async {
      final now = DateTime.now();
      final container = _container(
        chicks: [
          _chick(id: 'c1', hatchDate: now),
          _chick(id: 'c2', hatchDate: now, health: ChickHealthStatus.deceased),
          _chick(id: 'c3', hatchDate: now, health: ChickHealthStatus.deceased),
        ],
      );
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      // 1 survived out of 3 => 33% < 70% => negative
      final negativeInsights = insights.where(
        (i) => i.sentiment == InsightSentiment.negative,
      );
      expect(negativeInsights, isNotEmpty);
    });

    test('active breeding insight is always neutral', () async {
      final container = _container(
        pairs: [
          _pair(id: 'p1', status: BreedingStatus.active),
          _pair(id: 'p2', status: BreedingStatus.ongoing),
        ],
      );
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      // Active breeding insight should be neutral sentiment
      expect(insights.length, 1);
      expect(insights.first.sentiment, InsightSentiment.neutral);
    });

    test('no data fallback when all empty', () async {
      final container = _container();
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      expect(value.hasValue, isTrue);
      final insights = value.requireValue;
      expect(insights, hasLength(1));
      expect(insights.first.sentiment, InsightSentiment.neutral);
    });

    test('returns loading when streams are loading', () async {
      final eggsDao = _MockEggsDao();
      // Never emits — stays loading.
      when(
        () => eggsDao.watchPeriodEggStats(any(), any(), any()),
      ).thenAnswer((_) => const Stream.empty());
      final chicksDao = _MockChicksDao();
      when(
        () => chicksDao.watchPeriodChickStats(any(), any(), any()),
      ).thenAnswer((_) => Stream.value((total: 0, deceased: 0)));

      final container = ProviderContainer(
        overrides: [
          eggsDaoProvider.overrideWithValue(eggsDao),
          chicksDaoProvider.overrideWithValue(chicksDao),
          activeBreedingCountProvider(
            _userId,
          ).overrideWith((_) => Stream.value(0)),
          trendStatsProvider(_userId).overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(quickInsightsProvider(_userId), (_, __) {});
      await Future<void>.delayed(Duration.zero);

      final value = container.read(quickInsightsProvider(_userId));
      expect(value.isLoading, isTrue);
    });

    test('returns error when a stream has error', () async {
      final eggsDao = _MockEggsDao();
      when(
        () => eggsDao.watchPeriodEggStats(any(), any(), any()),
      ).thenAnswer((_) => Stream.error('egg error'));
      final chicksDao = _MockChicksDao();
      when(
        () => chicksDao.watchPeriodChickStats(any(), any(), any()),
      ).thenAnswer((_) => Stream.value((total: 0, deceased: 0)));

      final container = ProviderContainer(
        overrides: [
          eggsDaoProvider.overrideWithValue(eggsDao),
          chicksDaoProvider.overrideWithValue(chicksDao),
          activeBreedingCountProvider(
            _userId,
          ).overrideWith((_) => Stream.value(0)),
          trendStatsProvider(_userId).overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(quickInsightsProvider(_userId), (_, __) {});
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      final value = container.read(quickInsightsProvider(_userId));
      expect(value.hasError, isTrue);
    });

    test('completed pairs are not counted as active', () async {
      final container = _container(
        pairs: [
          _pair(id: 'p1', status: BreedingStatus.completed),
          _pair(id: 'p2', status: BreedingStatus.cancelled),
        ],
      );
      addTearDown(container.dispose);
      await _awaitInsights(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      // No active pairs => no breeding insight => fallback
      expect(insights, hasLength(1));
      expect(insights.first.sentiment, InsightSentiment.neutral);
    });
  });
}
