import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/egg_species_resolver.dart';

/// Lightweight count streams for dashboard (SQL COUNT instead of full list).
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
    if (value.hasError) {
      AppLogger.warning(
        '[dashboardStatsProvider] $label count failed, using 0 fallback: ${value.error}',
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

/// Recent chicks sorted by hatch date (max 5) — DAO-level SQL LIMIT.
final recentChicksProvider = StreamProvider.family<List<Chick>, String>((
  ref,
  userId,
) {
  return ref.watch(chicksDaoProvider).watchRecent(userId, limit: 5);
});

/// Active breeding pairs (active + ongoing) — DAO-level SQL LIMIT.
final activeBreedingsForDashboardProvider =
    StreamProvider.family<List<BreedingPair>, String>((ref, userId) {
      return ref
          .watch(breedingPairsDaoProvider)
          .watchActiveLimited(userId, limit: 3);
    });

Stream<DateTime> _midnightTicker() {
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

  return controller.stream;
}

final _unweanedCountRefreshProvider = StreamProvider<DateTime>((ref) {
  return _midnightTicker();
});

/// Count of chicks ready to move to birds (60+ days old and not yet moved) — SQL COUNT.
final unweanedChicksCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  ref.watch(_unweanedCountRefreshProvider);
  return ref.watch(chicksDaoProvider).watchUnweanedCount(userId);
});

/// Summary of incubating eggs with remaining days until expected hatch.
@immutable
class IncubatingEggSummary {
  final Egg egg;
  final Species species;
  final int daysRemaining;
  final double progressPercent;

  const IncubatingEggSummary({
    required this.egg,
    required this.species,
    required this.daysRemaining,
    required this.progressPercent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncubatingEggSummary &&
          runtimeType == other.runtimeType &&
          egg == other.egg &&
          species == other.species &&
          daysRemaining == other.daysRemaining &&
          progressPercent == other.progressPercent;

  @override
  int get hashCode => Object.hash(egg, species, daysRemaining, progressPercent);
}

final incubatingEggsSummaryProvider =
    FutureProvider.family<List<IncubatingEggSummary>, String>((
      ref,
      userId,
    ) async {
      final eggs = await ref.watch(
        incubatingEggsLimitedProvider(userId).future,
      );
      final now = DateTime.now();

      final speciesMap = await resolveEggSpeciesBatch(ref, eggs);

      final summaries = eggs.map((egg) {
        final species = speciesMap[egg.id] ?? Species.unknown;
        final expectedHatch = egg.expectedHatchDateFor(species: species);
        final remaining = expectedHatch.difference(now).inDays;
        return IncubatingEggSummary(
          egg: egg,
          species: species,
          daysRemaining: remaining,
          progressPercent: egg.progressPercentFor(species: species),
        );
      }).toList();

      summaries.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
      return summaries;
    });

/// Incubating eggs with SQL LIMIT (for dashboard).
final incubatingEggsLimitedProvider = StreamProvider.family<List<Egg>, String>((
  ref,
  userId,
) {
  return ref.watch(eggsDaoProvider).watchIncubatingLimited(userId, limit: 3);
});

/// Pulls the user profile from Supabase to local DB once per session.
final profileSyncProvider = FutureProvider.family<void, String>((
  ref,
  userId,
) async {
  if (userId == 'anonymous') return;
  final repo = ref.watch(profileRepositoryProvider);
  try {
    await repo.pull(userId);
  } on Exception catch (e, st) {
    AppLogger.error('[MainShell] Profile sync failed', e, st);
  }
});
