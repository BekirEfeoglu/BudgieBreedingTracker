import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';

/// Lightweight count streams for dashboards (SQL COUNT instead of full list).
/// Shared across home, statistics, and profile features to avoid cross-feature
/// imports and redundant full-entity loads.
final birdCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(birdsDaoProvider).watchCount(userId);
});

final eggCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(eggsDaoProvider).watchCount(userId);
});

final chickCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(chicksDaoProvider).watchCount(userId);
});

final activeBreedingCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(breedingPairsDaoProvider).watchActiveCount(userId);
});

final incubatingEggCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(eggsDaoProvider).watchIncubatingCount(userId);
});

/// Dashboard statistics computed from lightweight count streams.
/// Uses SQL COUNT queries instead of loading full entity lists.
final dashboardStatsProvider = Provider.family<AsyncValue<DashboardStats>, String>((
  ref,
  userId,
) {
  final birdsCount = ref.watch(birdCountProvider(userId));
  final eggsCount = ref.watch(eggCountProvider(userId));
  final chicksCount = ref.watch(chickCountProvider(userId));
  final abCount = ref.watch(activeBreedingCountProvider(userId));
  final ieCount = ref.watch(incubatingEggCountProvider(userId));

  final all = [birdsCount, eggsCount, chicksCount, abCount, ieCount];

  // Keep loading only while waiting for the first value and no fallback has been applied.
  if (all.any((c) => c.isLoading && !c.hasValue && !c.hasError)) {
    return const AsyncLoading();
  }

  int countOrZero(AsyncValue<int> value, String label) {
    // IMPROVED: include error details for better debugging
    if (value.hasError) {
      AppLogger.warning(
        '[dashboardStatsProvider] $label count failed, using 0 fallback: '
        '${value.error}',
      );
    }
    return value.value ?? 0;
  }

  return AsyncData(
    DashboardStats(
      totalBirds: countOrZero(birdsCount, 'birds'),
      totalEggs: countOrZero(eggsCount, 'eggs'),
      totalChicks: countOrZero(chicksCount, 'chicks'),
      activeBreedings: countOrZero(abCount, 'activeBreeding'),
      incubatingEggs: countOrZero(ieCount, 'incubatingEggs'),
    ),
  );
});

StreamController<DateTime> _midnightTicker() {
  late final StreamController<DateTime> controller;
  Timer? timer;

  void scheduleNextTick() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
    timer = Timer(delay, () {
      if (controller.isClosed) return;
      controller.add(DateTime.now());
      scheduleNextTick();
    });
  }

  controller = StreamController<DateTime>(
    onListen: () {
      controller.add(DateTime.now());
      scheduleNextTick();
    },
    onCancel: () {
      timer?.cancel();
    },
  );

  return controller;
}

final _unweanedCountRefreshProvider = StreamProvider<DateTime>((ref) {
  final controller = _midnightTicker();
  ref.onDispose(controller.close);
  return controller.stream;
});

/// Count of chicks ready to move to birds (60+ days old and not yet moved) — SQL COUNT.
final unweanedChicksCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  ref.watch(_unweanedCountRefreshProvider);
  return ref.watch(chicksDaoProvider).watchUnweanedCount(userId);
});
