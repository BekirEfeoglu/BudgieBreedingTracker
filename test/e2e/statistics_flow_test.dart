@Tags(['e2e'])
library;

import 'dart:async';

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
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_health_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_summary_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_trend_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

import '../helpers/e2e_test_harness.dart';

Future<T> _awaitData<T>(ProviderContainer container, dynamic provider) async {
  final completer = Completer<T>();
  late final ProviderSubscription<AsyncValue<T>> subscription;
  subscription = container.listen<AsyncValue<T>>(provider, (_, next) {
    if (next.hasValue && !completer.isCompleted) {
      completer.complete(next.requireValue);
      return;
    }
    if (next.hasError && !completer.isCompleted) {
      completer.completeError(
        next.error!,
        next.stackTrace ?? StackTrace.current,
      );
    }
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
}

void main() {
  ensureE2EBinding();

  final now = DateTime.now();
  final birds = <Bird>[
    const Bird(
      id: 'b1',
      userId: 'test-user',
      name: 'A',
      gender: BirdGender.male,
    ),
    const Bird(
      id: 'b2',
      userId: 'test-user',
      name: 'B',
      gender: BirdGender.female,
    ),
  ];
  final pairs = <BreedingPair>[
    BreedingPair(
      id: 'p1',
      userId: 'test-user',
      status: BreedingStatus.active,
      pairingDate: now.subtract(const Duration(days: 10)),
    ),
  ];
  final eggs = <Egg>[
    Egg(
      id: 'e1',
      userId: 'test-user',
      layDate: now.subtract(const Duration(days: 5)),
      status: EggStatus.fertile,
    ),
    Egg(
      id: 'e2',
      userId: 'test-user',
      layDate: now.subtract(const Duration(days: 4)),
      status: EggStatus.hatched,
    ),
  ];
  final chicks = <Chick>[
    Chick(
      id: 'c1',
      userId: 'test-user',
      hatchDate: now.subtract(const Duration(days: 3)),
      healthStatus: ChickHealthStatus.healthy,
    ),
  ];
  final health = <HealthRecord>[
    HealthRecord(
      id: 'h1',
      userId: 'test-user',
      title: 'Kontrol',
      type: HealthRecordType.checkup,
      date: now.subtract(const Duration(days: 2)),
    ),
    HealthRecord(
      id: 'h2',
      userId: 'test-user',
      title: 'Hastalik',
      type: HealthRecordType.illness,
      date: now.subtract(const Duration(days: 1)),
    ),
  ];

  group('Statistics Flow E2E', () {
    test(
      'GIVEN statistics summary tab WHEN data exists THEN total birds, active breeding, egg counts and fertility ratio are correct',
      () async {
        final container = createTestContainer(
          defaultBirdCount: birds.length,
          defaultActiveBreedingCount: 1,
          defaultHealthRecordCount: health.length,
          overrides: [
            birdsStreamProvider.overrideWith((_, __) => Stream.value(birds)),
            breedingPairsStreamProvider.overrideWith(
              (_, __) => Stream.value(pairs),
            ),
            eggsStreamProvider.overrideWith((_, __) => Stream.value(eggs)),
            chicksStreamProvider.overrideWith((_, __) => Stream.value(chicks)),
            healthRecordsStreamProvider.overrideWith(
              (_, __) => Stream.value(health),
            ),
          ],
        );
        addTearDown(container.dispose);

        final summary = await _awaitData(
          container,
          summaryStatsProvider('test-user'),
        );

        expect(summary.totalBirds, 2);
        expect(summary.activeBreedings, 1);
        expect(summary.incubatingEggs, 0);
        expect(summary.fertilityRate, closeTo(1.0, 0.001));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN breeding statistics tab WHEN last 3 months selected THEN trend datasets are produced for charts',
      () async {
        final container = createTestContainer(
          overrides: [
            breedingPairsStreamProvider.overrideWith(
              (_, __) => Stream.value(pairs),
            ),
            eggsStreamProvider.overrideWith((_, __) => Stream.value(eggs)),
          ],
        );
        addTearDown(container.dispose);

        container.read(statsPeriodProvider.notifier).state =
            StatsPeriod.threeMonths;

        final outcomes = await _awaitData(
          container,
          monthlyBreedingOutcomesProvider('test-user'),
        );
        final eggSeries = await _awaitData(
          container,
          monthlyEggProductionProvider('test-user'),
        );

        expect(outcomes.completed.length, 3);
        expect(eggSeries.length, 3);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN health statistics tab WHEN records are loaded THEN illness/checkup distributions and survival metrics are produced',
      () async {
        final container = createTestContainer(
          overrides: [
            healthRecordsStreamProvider.overrideWith(
              (_, __) => Stream.value(health),
            ),
            chicksStreamProvider.overrideWith((_, __) => Stream.value(chicks)),
          ],
        );
        addTearDown(container.dispose);

        final typeDist = await _awaitData(
          container,
          healthRecordTypeDistributionProvider('test-user'),
        );
        final survival = await _awaitData(
          container,
          chickSurvivalProvider('test-user'),
        );

        expect(typeDist[HealthRecordType.illness], 1);
        expect(typeDist[HealthRecordType.checkup], 1);
        expect(survival.survivalRate, closeTo(1.0, 0.001));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN trend tab WHEN 6 month data is loaded THEN trend and quick insight providers return non-empty analysis',
      () async {
        final container = createTestContainer(
          overrides: [
            birdsStreamProvider.overrideWith((_, __) => Stream.value(birds)),
            breedingPairsStreamProvider.overrideWith(
              (_, __) => Stream.value(pairs),
            ),
            eggsStreamProvider.overrideWith((_, __) => Stream.value(eggs)),
            chicksStreamProvider.overrideWith((_, __) => Stream.value(chicks)),
          ],
        );
        addTearDown(container.dispose);

        container.read(statsPeriodProvider.notifier).state =
            StatsPeriod.sixMonths;

        final trend = await _awaitData(
          container,
          trendStatsProvider('test-user'),
        );
        final insights = await _awaitData(
          container,
          quickInsightsProvider('test-user'),
        );

        expect(trend.eggsTrend, isA<double>());
        expect(insights, isNotEmpty);
      },
      timeout: e2eTimeout,
    );
  });
}
