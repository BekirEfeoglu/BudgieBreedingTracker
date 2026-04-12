import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_trend_providers.dart';

const _userId = 'user-1';

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

/// Creates a container with overridden stream providers and a loading trend.
ProviderContainer _container({
  List<Egg> eggs = const [],
  List<Chick> chicks = const [],
  List<BreedingPair> pairs = const [],
  AsyncValue<TrendStats>? trendOverride,
}) {
  return ProviderContainer(
    overrides: [
      eggsStreamProvider(_userId).overrideWith(
        (_) => Stream.value(eggs),
      ),
      chicksStreamProvider(_userId).overrideWith(
        (_) => Stream.value(chicks),
      ),
      breedingPairsStreamProvider(_userId).overrideWith(
        (_) => Stream.value(pairs),
      ),
      trendStatsProvider(_userId).overrideWithValue(
        trendOverride ?? const AsyncLoading(),
      ),
    ],
  );
}

Future<void> _awaitStreams(ProviderContainer container) async {
  container.listen(eggsStreamProvider(_userId), (_, __) {});
  await container.read(eggsStreamProvider(_userId).future);
  container.listen(chicksStreamProvider(_userId), (_, __) {});
  await container.read(chicksStreamProvider(_userId).future);
  container.listen(breedingPairsStreamProvider(_userId), (_, __) {});
  await container.read(breedingPairsStreamProvider(_userId).future);
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
      await _awaitStreams(container);

      final value = container.read(quickInsightsProvider(_userId));
      expect(value.hasValue, isTrue);
      final insights = value.requireValue;
      expect(insights.any((i) => i.sentiment == InsightSentiment.positive),
          isTrue);
    });

    test('egg production insight with negative trend', () async {
      final now = DateTime.now();
      final container = _container(
        eggs: [_egg(id: 'e1', layDate: now, status: EggStatus.laid)],
        trendOverride: const AsyncData(TrendStats(eggsTrend: -30)),
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      expect(insights.any((i) => i.sentiment == InsightSentiment.negative),
          isTrue);
    });

    test('egg insight is neutral when trend is loading', () async {
      final now = DateTime.now();
      final container = _container(
        eggs: [_egg(id: 'e1', layDate: now, status: EggStatus.laid)],
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

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
      await _awaitStreams(container);

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
      await _awaitStreams(container);

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
          _chick(
            id: 'c4',
            hatchDate: now,
            health: ChickHealthStatus.deceased,
          ),
        ],
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

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
          _chick(
            id: 'c2',
            hatchDate: now,
            health: ChickHealthStatus.deceased,
          ),
          _chick(
            id: 'c3',
            hatchDate: now,
            health: ChickHealthStatus.deceased,
          ),
        ],
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

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
      await _awaitStreams(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      // Active breeding insight should be neutral sentiment
      expect(insights.length, 1);
      expect(insights.first.sentiment, InsightSentiment.neutral);
    });

    test('no data fallback when all empty', () async {
      final container = _container();
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(quickInsightsProvider(_userId));
      expect(value.hasValue, isTrue);
      final insights = value.requireValue;
      expect(insights, hasLength(1));
      expect(insights.first.sentiment, InsightSentiment.neutral);
    });

    test('returns loading when streams are loading', () {
      final container = ProviderContainer(
        overrides: [
          eggsStreamProvider(_userId).overrideWith(
            (_) => const Stream.empty(),
          ),
          chicksStreamProvider(_userId).overrideWith(
            (_) => Stream.value(<Chick>[]),
          ),
          breedingPairsStreamProvider(_userId).overrideWith(
            (_) => Stream.value(<BreedingPair>[]),
          ),
          trendStatsProvider(_userId).overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);
      // eggs stream never emits so stays loading
      container.listen(eggsStreamProvider(_userId), (_, __) {});

      final value = container.read(quickInsightsProvider(_userId));
      expect(value.isLoading, isTrue);
    });

    test('returns error when a stream has error', () async {
      final container = ProviderContainer(
        overrides: [
          eggsStreamProvider(_userId).overrideWith(
            (_) => Stream.error('egg error'),
          ),
          chicksStreamProvider(_userId).overrideWith(
            (_) => Stream.value(<Chick>[]),
          ),
          breedingPairsStreamProvider(_userId).overrideWith(
            (_) => Stream.value(<BreedingPair>[]),
          ),
          trendStatsProvider(_userId).overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(eggsStreamProvider(_userId), (_, __) {});
      // Allow the error stream to emit
      await Future<void>.delayed(Duration.zero);

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
      await _awaitStreams(container);

      final value = container.read(quickInsightsProvider(_userId));
      final insights = value.requireValue;
      // No active pairs => no breeding insight => fallback
      expect(insights, hasLength(1));
      expect(insights.first.sentiment, InsightSentiment.neutral);
    });
  });
}
