import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/egg_species_resolver.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';

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
      // Keep alive across short navigation transitions so species resolution
      // and hatch-date computation don't re-run when the user returns to Home.
      ref.keepAlive();

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

@immutable
class TodaysEggTurningSummary {
  final List<IncubatingEggSummary> eggs;
  final DateTime? nextTurningAt;

  const TodaysEggTurningSummary({
    required this.eggs,
    required this.nextTurningAt,
  });

  int get count => eggs.length;

  bool get hasEggs => eggs.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodaysEggTurningSummary &&
          runtimeType == other.runtimeType &&
          eggs == other.eggs &&
          nextTurningAt == other.nextTurningAt;

  @override
  int get hashCode => Object.hash(eggs, nextTurningAt);
}

@immutable
class HomeWidgetDashboardSnapshot {
  final int eggTurningCount;
  final int activeBreedingsCount;
  final String nextTurningLabel;
  final String lastUpdatedLabel;

  const HomeWidgetDashboardSnapshot({
    required this.eggTurningCount,
    required this.activeBreedingsCount,
    required this.nextTurningLabel,
    required this.lastUpdatedLabel,
  });

  bool get hasWorkToday => eggTurningCount > 0 || activeBreedingsCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeWidgetDashboardSnapshot &&
          runtimeType == other.runtimeType &&
          eggTurningCount == other.eggTurningCount &&
          activeBreedingsCount == other.activeBreedingsCount &&
          nextTurningLabel == other.nextTurningLabel &&
          lastUpdatedLabel == other.lastUpdatedLabel;

  @override
  int get hashCode => Object.hash(
    eggTurningCount,
    activeBreedingsCount,
    nextTurningLabel,
    lastUpdatedLabel,
  );
}

HomeWidgetDashboardSnapshot buildHomeWidgetDashboardSnapshot({
  required TodaysEggTurningSummary turningSummary,
  required int activeBreedingsCount,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final nextTurningAt = turningSummary.nextTurningAt;
  final nextTurningLabel = nextTurningAt == null
      ? ''
      : '${nextTurningAt.hour.toString().padLeft(2, '0')}:'
            '${nextTurningAt.minute.toString().padLeft(2, '0')}';
  final lastUpdatedLabel =
      '${current.hour.toString().padLeft(2, '0')}:'
      '${current.minute.toString().padLeft(2, '0')}';

  return HomeWidgetDashboardSnapshot(
    eggTurningCount: turningSummary.count,
    activeBreedingsCount: activeBreedingsCount,
    nextTurningLabel: nextTurningLabel,
    lastUpdatedLabel: lastUpdatedLabel,
  );
}

TodaysEggTurningSummary buildTodaysEggTurningSummary(
  List<IncubatingEggSummary> eggs, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  DateTime? nextTurningAt;

  for (final summary in eggs) {
    for (final hourText in eggTurningHoursForSpecies(summary.species)) {
      final parts = hourText.split(':');
      final candidate = DateTime(
        current.year,
        current.month,
        current.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (!candidate.isAfter(current)) continue;
      if (nextTurningAt == null || candidate.isBefore(nextTurningAt)) {
        nextTurningAt = candidate;
      }
    }
  }

  return TodaysEggTurningSummary(eggs: eggs, nextTurningAt: nextTurningAt);
}

final todaysEggTurningSummaryProvider =
    FutureProvider.family<TodaysEggTurningSummary, String>((ref, userId) async {
      final eggs = await ref.watch(
        incubatingEggsSummaryProvider(userId).future,
      );
      return buildTodaysEggTurningSummary(eggs);
    });

final homeWidgetDashboardSnapshotProvider =
    Provider.family<AsyncValue<HomeWidgetDashboardSnapshot>, String>((
      ref,
      userId,
    ) {
      final turningSummaryAsync = ref.watch(
        todaysEggTurningSummaryProvider(userId),
      );
      final activeBreedingsAsync = ref.watch(
        activeBreedingsForDashboardProvider(userId),
      );

      return turningSummaryAsync.when(
        loading: () => const AsyncLoading(),
        error: AsyncError.new,
        data: (turningSummary) => activeBreedingsAsync.when(
          loading: () => const AsyncLoading(),
          error: AsyncError.new,
          data: (activeBreedings) => AsyncData(
            buildHomeWidgetDashboardSnapshot(
              turningSummary: turningSummary,
              activeBreedingsCount: activeBreedings.length,
            ),
          ),
        ),
      );
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
