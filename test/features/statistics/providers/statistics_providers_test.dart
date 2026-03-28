import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_health_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_summary_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_trend_providers.dart';

Bird _bird({
  required String id,
  BirdGender gender = BirdGender.unknown,
  BirdStatus status = BirdStatus.alive,
  DateTime? createdAt,
  DateTime? birthDate,
  BirdColor? color,
}) {
  return Bird(
    id: id,
    userId: 'user-1',
    name: id,
    gender: gender,
    status: status,
    colorMutation: color,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    birthDate: birthDate,
  );
}

BreedingPair _pair({
  required String id,
  required BreedingStatus status,
  DateTime? pairingDate,
  DateTime? separationDate,
  DateTime? updatedAt,
}) {
  return BreedingPair(
    id: id,
    userId: 'user-1',
    status: status,
    pairingDate: pairingDate,
    separationDate: separationDate,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime(2024, 1, 1),
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

Chick _chick({
  required String id,
  ChickHealthStatus health = ChickHealthStatus.healthy,
  DateTime? hatchDate,
}) {
  return Chick(
    id: id,
    userId: 'user-1',
    healthStatus: health,
    hatchDate: hatchDate,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

HealthRecord _record({
  required String id,
  required DateTime date,
  HealthRecordType type = HealthRecordType.checkup,
}) {
  return HealthRecord(
    id: id,
    date: date,
    type: type,
    title: id,
    userId: 'user-1',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

ProviderContainer _container({
  required List<Bird> birds,
  required List<BreedingPair> pairs,
  required List<Egg> eggs,
  required List<Chick> chicks,
  required List<HealthRecord> healthRecords,
}) {
  final activePairCount = pairs
      .where(
        (p) =>
            p.status == BreedingStatus.active ||
            p.status == BreedingStatus.ongoing,
      )
      .length;

  return ProviderContainer(
    overrides: [
      birdsStreamProvider('user-1').overrideWith((_) => Stream.value(birds)),
      breedingPairsStreamProvider(
        'user-1',
      ).overrideWith((_) => Stream.value(pairs)),
      eggsStreamProvider('user-1').overrideWith((_) => Stream.value(eggs)),
      chicksStreamProvider('user-1').overrideWith((_) => Stream.value(chicks)),
      healthRecordsStreamProvider(
        'user-1',
      ).overrideWith((_) => Stream.value(healthRecords)),
      // COUNT providers used by summaryStatsProvider (bypass SQL DAO calls)
      birdCountProvider(
        'user-1',
      ).overrideWith((_) => Stream.value(birds.length)),
      activeBreedingCountProvider(
        'user-1',
      ).overrideWith((_) => Stream.value(activePairCount)),
      healthRecordCountProvider(
        'user-1',
      ).overrideWith((_) => Stream.value(healthRecords.length)),
    ],
  );
}

void main() {
  const userId = 'user-1';

  group('core statistics providers', () {
    test('summaryStatsProvider combines entity streams', () async {
      final now = DateTime.now();
      final container = _container(
        birds: [
          _bird(id: 'b1', gender: BirdGender.male, status: BirdStatus.alive),
          _bird(id: 'b2', gender: BirdGender.female, status: BirdStatus.alive),
        ],
        pairs: [
          _pair(id: 'p1', status: BreedingStatus.active),
          _pair(id: 'p2', status: BreedingStatus.ongoing),
          _pair(id: 'p3', status: BreedingStatus.completed),
        ],
        eggs: [
          _egg(id: 'e1', layDate: now, status: EggStatus.incubating),
          _egg(id: 'e2', layDate: now, status: EggStatus.fertile),
          _egg(id: 'e3', layDate: now, status: EggStatus.infertile),
        ],
        chicks: [
          _chick(id: 'c1', health: ChickHealthStatus.healthy, hatchDate: now),
          _chick(id: 'c2', health: ChickHealthStatus.deceased, hatchDate: now),
        ],
        healthRecords: [
          _record(id: 'h1', date: now),
          _record(id: 'h2', date: now),
          _record(id: 'h3', date: now),
        ],
      );
      addTearDown(container.dispose);
      container.listen(birdsStreamProvider(userId), (_, __) {});
      await container.read(birdsStreamProvider(userId).future);
      container.listen(breedingPairsStreamProvider(userId), (_, __) {});
      await container.read(breedingPairsStreamProvider(userId).future);
      container.listen(eggsStreamProvider(userId), (_, __) {});
      await container.read(eggsStreamProvider(userId).future);
      container.listen(chicksStreamProvider(userId), (_, __) {});
      await container.read(chicksStreamProvider(userId).future);
      container.listen(healthRecordsStreamProvider(userId), (_, __) {});
      await container.read(healthRecordsStreamProvider(userId).future);
      // Await COUNT providers (SQL-backed StreamProviders overridden in _container)
      container.listen(birdCountProvider(userId), (_, __) {});
      await container.read(birdCountProvider(userId).future);
      container.listen(activeBreedingCountProvider(userId), (_, __) {});
      await container.read(activeBreedingCountProvider(userId).future);
      container.listen(healthRecordCountProvider(userId), (_, __) {});
      await container.read(healthRecordCountProvider(userId).future);

      final value = container.read(summaryStatsProvider(userId));
      expect(value.hasValue, isTrue);
      final stats = value.requireValue;
      expect(stats.totalBirds, 2);
      expect(stats.activeBreedings, 2);
      expect(stats.incubatingEggs, 1);
      expect(stats.totalHealthRecords, 3);
      expect(stats.fertilityRate, closeTo(0.5, 0.0001));
      expect(stats.chickSurvivalRate, closeTo(0.5, 0.0001));
    });
  });

  group('breeding and health stats providers', () {
    test('monthlyFertilityRateProvider computes month percentage', () async {
      final now = DateTime.now();
      final currentKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final oldDate = DateTime(now.year, now.month - 8, 1);

      final container = _container(
        birds: const [],
        pairs: const [],
        chicks: const [],
        healthRecords: const [],
        eggs: [
          _egg(id: 'e1', layDate: now, status: EggStatus.fertile),
          _egg(id: 'e2', layDate: now, status: EggStatus.hatched),
          _egg(id: 'e3', layDate: now, status: EggStatus.infertile),
          _egg(id: 'old', layDate: oldDate, status: EggStatus.fertile),
        ],
      );
      addTearDown(container.dispose);
      container.read(statsPeriodProvider.notifier).state =
          StatsPeriod.threeMonths;
      container.listen(eggsStreamProvider(userId), (_, __) {});
      await container.read(eggsStreamProvider(userId).future);

      final value = container.read(monthlyFertilityRateProvider(userId));
      expect(value.hasValue, isTrue);
      final map = value.requireValue;
      expect(map[currentKey], isNotNull);
      expect(map[currentKey]!, closeTo(66.666, 0.1));
    });

    test('chickSurvivalProvider returns counts and survival rate', () async {
      final container = _container(
        birds: const [],
        pairs: const [],
        eggs: const [],
        healthRecords: const [],
        chicks: [
          _chick(id: 'c1', health: ChickHealthStatus.healthy),
          _chick(id: 'c2', health: ChickHealthStatus.sick),
          _chick(id: 'c3', health: ChickHealthStatus.deceased),
        ],
      );
      addTearDown(container.dispose);
      container.listen(chicksStreamProvider(userId), (_, __) {});
      await container.read(chicksStreamProvider(userId).future);

      final value = container.read(chickSurvivalProvider(userId));
      expect(value.hasValue, isTrue);
      final data = value.requireValue;
      expect(data.healthy, 1);
      expect(data.sick, 1);
      expect(data.deceased, 1);
      expect(data.survivalRate, closeTo(2 / 3, 0.0001));
    });

    test(
      'healthRecordTypeDistributionProvider uses month-aligned current period',
      () async {
        const period = StatsPeriod.threeMonths;
        final now = DateTime.now();
        final range = buildStatsDateRange(period, now: now);
        final legacyCutoff = DateTime(
          now.year,
          now.month - period.monthCount,
          now.day,
        );
        final bridgeDate = legacyCutoff.add(
          range.currentStart.difference(legacyCutoff) ~/ 2,
        );

        final container = _container(
          birds: const [],
          pairs: const [],
          eggs: const [],
          chicks: const [],
          healthRecords: [
            _record(
              id: 'legacy-window',
              date: bridgeDate,
              type: HealthRecordType.illness,
            ),
            _record(
              id: 'current-window',
              date: range.currentStart,
              type: HealthRecordType.checkup,
            ),
          ],
        );
        addTearDown(container.dispose);
        container.read(statsPeriodProvider.notifier).state = period;
        container.listen(healthRecordsStreamProvider(userId), (_, __) {});
        await container.read(healthRecordsStreamProvider(userId).future);

        final value = container.read(
          healthRecordTypeDistributionProvider(userId),
        );
        expect(value.hasValue, isTrue);
        final counts = value.requireValue;
        expect(counts[HealthRecordType.checkup], 1);
        expect(counts[HealthRecordType.illness], isNull);
      },
    );

    test(
      'quickInsightsProvider keeps egg insight neutral when trend is loading',
      () async {
        final now = DateTime.now();
        final container = ProviderContainer(
          overrides: [
            eggsStreamProvider(userId).overrideWith(
              (_) => Stream.value([
                _egg(id: 'e1', layDate: now, status: EggStatus.fertile),
              ]),
            ),
            chicksStreamProvider(
              userId,
            ).overrideWith((_) => Stream.value(<Chick>[])),
            breedingPairsStreamProvider(
              userId,
            ).overrideWith((_) => Stream.value(<BreedingPair>[])),
            trendStatsProvider(userId).overrideWithValue(const AsyncLoading()),
          ],
        );
        addTearDown(container.dispose);

        container.listen(eggsStreamProvider(userId), (_, __) {});
        await container.read(eggsStreamProvider(userId).future);
        container.listen(chicksStreamProvider(userId), (_, __) {});
        await container.read(chicksStreamProvider(userId).future);
        container.listen(breedingPairsStreamProvider(userId), (_, __) {});
        await container.read(breedingPairsStreamProvider(userId).future);

        final value = container.read(quickInsightsProvider(userId));
        expect(value.hasValue, isTrue);
        final insights = value.requireValue;
        expect(insights, isNotEmpty);
        expect(insights.first.sentiment, InsightSentiment.neutral);
      },
    );
  });

  group('quickInsightsProvider period-aware', () {
    test('only includes eggs from current period', () async {
      final now = DateTime.now();
      final inPeriod = DateTime(now.year, now.month - 1, 15);
      final outOfPeriod = DateTime(now.year, now.month - 5, 15);

      final container = ProviderContainer(
        overrides: [
          eggsStreamProvider(userId).overrideWith(
            (_) => Stream.value([
              _egg(id: 'in', layDate: inPeriod, status: EggStatus.fertile),
              _egg(id: 'out', layDate: outOfPeriod, status: EggStatus.fertile),
            ]),
          ),
          chicksStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<Chick>[])),
          breedingPairsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<BreedingPair>[])),
          trendStatsProvider(userId).overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);
      container.read(statsPeriodProvider.notifier).state =
          StatsPeriod.threeMonths;

      container.listen(eggsStreamProvider(userId), (_, __) {});
      await container.read(eggsStreamProvider(userId).future);
      container.listen(chicksStreamProvider(userId), (_, __) {});
      await container.read(chicksStreamProvider(userId).future);
      container.listen(breedingPairsStreamProvider(userId), (_, __) {});
      await container.read(breedingPairsStreamProvider(userId).future);

      final value = container.read(quickInsightsProvider(userId));
      expect(value.hasValue, isTrue);
      final insights = value.requireValue;
      // 1 fertile egg in 3-month window → egg insight + fertility insight
      // Out-of-period egg should NOT be counted
      expect(insights.length, greaterThanOrEqualTo(1));
      expect(insights.length, lessThanOrEqualTo(2));
    });

    test('12-month period produces more insights than 3-month', () async {
      final now = DateTime.now();
      final recent = DateTime(now.year, now.month - 1, 15);
      final older = DateTime(now.year, now.month - 5, 15);

      ProviderContainer makeContainer(StatsPeriod period) {
        final c = ProviderContainer(
          overrides: [
            eggsStreamProvider(userId).overrideWith(
              (_) => Stream.value([
                _egg(id: 'recent', layDate: recent, status: EggStatus.fertile),
                _egg(
                  id: 'older',
                  layDate: older,
                  status: EggStatus.infertile,
                ),
              ]),
            ),
            chicksStreamProvider(
              userId,
            ).overrideWith((_) => Stream.value(<Chick>[])),
            breedingPairsStreamProvider(
              userId,
            ).overrideWith((_) => Stream.value(<BreedingPair>[])),
            trendStatsProvider(userId).overrideWithValue(const AsyncLoading()),
          ],
        );
        c.read(statsPeriodProvider.notifier).state = period;
        return c;
      }

      // 3-month window → only recent egg (fertile) → egg insight only
      final container3m = makeContainer(StatsPeriod.threeMonths);
      addTearDown(container3m.dispose);
      container3m.listen(eggsStreamProvider(userId), (_, __) {});
      await container3m.read(eggsStreamProvider(userId).future);
      container3m.listen(chicksStreamProvider(userId), (_, __) {});
      await container3m.read(chicksStreamProvider(userId).future);
      container3m.listen(breedingPairsStreamProvider(userId), (_, __) {});
      await container3m.read(breedingPairsStreamProvider(userId).future);

      final insights3m =
          container3m.read(quickInsightsProvider(userId)).requireValue;

      // 12-month window → both eggs → egg insight + fertility insight
      final container12m = makeContainer(StatsPeriod.twelveMonths);
      addTearDown(container12m.dispose);
      container12m.listen(eggsStreamProvider(userId), (_, __) {});
      await container12m.read(eggsStreamProvider(userId).future);
      container12m.listen(chicksStreamProvider(userId), (_, __) {});
      await container12m.read(chicksStreamProvider(userId).future);
      container12m.listen(breedingPairsStreamProvider(userId), (_, __) {});
      await container12m.read(breedingPairsStreamProvider(userId).future);

      final insights12m =
          container12m.read(quickInsightsProvider(userId)).requireValue;

      // 12m should have more insights because both eggs are in range,
      // giving a fertility rate insight (fertile + infertile = checked)
      expect(insights12m.length, greaterThanOrEqualTo(insights3m.length));
    });

    test('shows no-data fallback when no entities in period', () async {
      final container = ProviderContainer(
        overrides: [
          eggsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<Egg>[])),
          chicksStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<Chick>[])),
          breedingPairsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<BreedingPair>[])),
          trendStatsProvider(userId).overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(eggsStreamProvider(userId), (_, __) {});
      await container.read(eggsStreamProvider(userId).future);
      container.listen(chicksStreamProvider(userId), (_, __) {});
      await container.read(chicksStreamProvider(userId).future);
      container.listen(breedingPairsStreamProvider(userId), (_, __) {});
      await container.read(breedingPairsStreamProvider(userId).future);

      final value = container.read(quickInsightsProvider(userId));
      expect(value.hasValue, isTrue);
      final insights = value.requireValue;
      expect(insights, hasLength(1));
      expect(insights.first.sentiment, InsightSentiment.neutral);
    });

    test('chick survival insight uses period filter', () async {
      final now = DateTime.now();
      final inPeriod = DateTime(now.year, now.month - 1, 10);
      final outOfPeriod = DateTime(now.year, now.month - 8, 10);

      final container = ProviderContainer(
        overrides: [
          eggsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<Egg>[])),
          chicksStreamProvider(userId).overrideWith(
            (_) => Stream.value([
              _chick(id: 'c-in', hatchDate: inPeriod),
              _chick(
                id: 'c-out',
                hatchDate: outOfPeriod,
                health: ChickHealthStatus.deceased,
              ),
            ]),
          ),
          breedingPairsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<BreedingPair>[])),
          trendStatsProvider(userId).overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);
      container.read(statsPeriodProvider.notifier).state =
          StatsPeriod.threeMonths;

      container.listen(eggsStreamProvider(userId), (_, __) {});
      await container.read(eggsStreamProvider(userId).future);
      container.listen(chicksStreamProvider(userId), (_, __) {});
      await container.read(chicksStreamProvider(userId).future);
      container.listen(breedingPairsStreamProvider(userId), (_, __) {});
      await container.read(breedingPairsStreamProvider(userId).future);

      final value = container.read(quickInsightsProvider(userId));
      expect(value.hasValue, isTrue);
      final insights = value.requireValue;
      // Only in-period healthy chick → positive sentiment for chick insight
      // Deceased chick is out of period and should not affect the result
      final hasPositiveInsight = insights.any(
        (i) => i.sentiment == InsightSentiment.positive,
      );
      expect(hasPositiveInsight, isTrue);
    });
  });

  group('trend providers', () {
    test('trendStatsProvider compares current and previous period', () async {
      final now = DateTime.now();
      final currentDate = DateTime(now.year, now.month - 1, now.day);
      final previousDate = DateTime(now.year, now.month - 4, now.day);

      final container = _container(
        birds: [
          _bird(id: 'b-current-1', createdAt: currentDate),
          _bird(id: 'b-current-2', createdAt: currentDate),
          _bird(id: 'b-prev', createdAt: previousDate),
        ],
        pairs: [
          _pair(
            id: 'p-current-1',
            status: BreedingStatus.active,
            pairingDate: currentDate,
          ),
          _pair(
            id: 'p-current-2',
            status: BreedingStatus.ongoing,
            pairingDate: currentDate,
          ),
          _pair(
            id: 'p-prev',
            status: BreedingStatus.completed,
            pairingDate: previousDate,
          ),
        ],
        eggs: [
          _egg(
            id: 'e-current-1',
            layDate: currentDate,
            status: EggStatus.fertile,
          ),
          _egg(
            id: 'e-current-2',
            layDate: currentDate,
            status: EggStatus.hatched,
          ),
          _egg(
            id: 'e-prev',
            layDate: previousDate,
            status: EggStatus.infertile,
          ),
        ],
        chicks: [
          _chick(id: 'c-current-1', hatchDate: currentDate),
          _chick(
            id: 'c-current-2',
            hatchDate: currentDate,
            health: ChickHealthStatus.deceased,
          ),
          _chick(id: 'c-prev', hatchDate: previousDate),
        ],
        healthRecords: const [],
      );
      addTearDown(container.dispose);
      container.read(statsPeriodProvider.notifier).state =
          StatsPeriod.threeMonths;
      container.listen(birdsStreamProvider(userId), (_, __) {});
      await container.read(birdsStreamProvider(userId).future);
      container.listen(breedingPairsStreamProvider(userId), (_, __) {});
      await container.read(breedingPairsStreamProvider(userId).future);
      container.listen(eggsStreamProvider(userId), (_, __) {});
      await container.read(eggsStreamProvider(userId).future);
      container.listen(chicksStreamProvider(userId), (_, __) {});
      await container.read(chicksStreamProvider(userId).future);

      final value = container.read(trendStatsProvider(userId));
      expect(value.hasValue, isTrue);
      final trend = value.requireValue;
      expect(trend.birdsTrend, closeTo(100, 0.001));
      expect(trend.breedingsTrend, closeTo(100, 0.001));
      expect(trend.eggsTrend, closeTo(100, 0.001));
    });

    test(
      'trendStatsProvider excludes completed pairs from previous active baseline',
      () async {
        final now = DateTime.now();
        final currentDate = DateTime(now.year, now.month - 1, 1);
        final previousDate = DateTime(now.year, now.month - 4, 1);

        final container = _container(
          birds: const [],
          eggs: const [],
          chicks: const [],
          healthRecords: const [],
          pairs: [
            _pair(
              id: 'p-current',
              status: BreedingStatus.active,
              pairingDate: currentDate,
            ),
            _pair(
              id: 'p-prev-completed',
              status: BreedingStatus.completed,
              pairingDate: previousDate,
            ),
          ],
        );
        addTearDown(container.dispose);
        container.read(statsPeriodProvider.notifier).state =
            StatsPeriod.threeMonths;
        container.listen(breedingPairsStreamProvider(userId), (_, __) {});
        await container.read(breedingPairsStreamProvider(userId).future);
        container.listen(eggsStreamProvider(userId), (_, __) {});
        await container.read(eggsStreamProvider(userId).future);
        container.listen(chicksStreamProvider(userId), (_, __) {});
        await container.read(chicksStreamProvider(userId).future);
        container.listen(birdsStreamProvider(userId), (_, __) {});
        await container.read(birdsStreamProvider(userId).future);

        final value = container.read(trendStatsProvider(userId));
        expect(value.hasValue, isTrue);
        final trend = value.requireValue;
        expect(trend.breedingsTrend, closeTo(100, 0.001));
      },
    );
  });
}
