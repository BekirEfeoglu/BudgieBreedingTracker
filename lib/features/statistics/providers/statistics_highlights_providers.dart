import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart'
    as date_utils;
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_highlight_models.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

export 'package:budgie_breeding_tracker/data/models/statistics_highlight_models.dart';

final clutchesStreamProvider = StreamProvider.family<List<Clutch>, String>((
  ref,
  userId,
) {
  return ref.watch(clutchRepositoryProvider).watchAll(userId);
});

/// Raw SQL-aggregated most-productive hatch year (statistics.md SQL
/// aggregation requirement) — `ChicksDao.watchMostProductiveSeason`.
final _mostProductiveSeasonStreamProvider =
    StreamProvider.family<({int year, int count})?, String>((ref, userId) {
      return ref.watch(chicksDaoProvider).watchMostProductiveSeason(userId);
    });

/// Raw SQL-aggregated top breeding pair by chick count —
/// `ChicksDao.watchTopPairByChickCount`.
final _topPairStreamProvider =
    StreamProvider.family<({String pairId, int count})?, String>((
      ref,
      userId,
    ) {
      return ref.watch(chicksDaoProvider).watchTopPairByChickCount(userId);
    });

/// Personal records: most productive season and top pair are SQL-aggregated
/// (see above); longest-lived bird stays Dart-side over the birds list —
/// birds are naturally bounded per user (unlike eggs/chicks/health records,
/// which grow unbounded over years), and the "now"-relative day-diff math
/// is delicate enough (datetime-format.md DST/UTC boundary rules) that a
/// raw-SQL `julianday()` conversion isn't worth the risk for a small list.
final personalRecordsProvider =
    Provider.family<AsyncValue<PersonalRecords>, String>((ref, userId) {
      final birdsAsync = ref.watch(birdsStreamProvider(userId));
      final seasonAsync = ref.watch(
        _mostProductiveSeasonStreamProvider(userId),
      );
      final topPairAsync = ref.watch(_topPairStreamProvider(userId));

      for (final async in [birdsAsync, seasonAsync, topPairAsync]) {
        if (async.hasError) {
          return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
        }
      }
      if (birdsAsync.isLoading ||
          seasonAsync.isLoading ||
          topPairAsync.isLoading) {
        return const AsyncLoading();
      }

      final season = seasonAsync.requireValue;
      final topPair = topPairAsync.requireValue;

      return AsyncData(
        PersonalRecords(
          mostProductiveSeason: season == null
              ? null
              : SeasonRecord(year: season.year, chickCount: season.count),
          topPair: topPair == null
              ? null
              : TopPairRecord(
                  pairId: topPair.pairId,
                  chickCount: topPair.count,
                ),
          longestLivedBird: findLongestLivedBird(birdsAsync.requireValue),
        ),
      );
    });

/// Raw SQL-aggregated distinct years present in eggs.lay_date /
/// chicks.hatch_date (statistics.md SQL aggregation requirement) — the
/// union of both determines which 2 seasons get compared.
final _eggYearsStreamProvider = StreamProvider.family<Set<int>, String>((
  ref,
  userId,
) {
  return ref.watch(eggsDaoProvider).watchDistinctLayYears(userId);
});

final _chickYearsStreamProvider = StreamProvider.family<Set<int>, String>((
  ref,
  userId,
) {
  return ref.watch(chicksDaoProvider).watchDistinctHatchYears(userId);
});

/// Sorted, deduplicated years across eggs + chicks. `null` means fewer than
/// 2 seasons exist yet (matches the previous `years.length < 2` guard).
final _seasonYearsProvider = Provider.family<AsyncValue<List<int>?>, String>((
  ref,
  userId,
) {
  final eggYearsAsync = ref.watch(_eggYearsStreamProvider(userId));
  final chickYearsAsync = ref.watch(_chickYearsStreamProvider(userId));

  for (final async in [eggYearsAsync, chickYearsAsync]) {
    if (async.hasError) {
      return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
    }
  }
  if (eggYearsAsync.isLoading || chickYearsAsync.isLoading) {
    return const AsyncLoading();
  }

  final years = {...eggYearsAsync.requireValue, ...chickYearsAsync.requireValue};
  if (years.length < 2) return const AsyncData(null);
  return AsyncData(years.toList()..sort());
});

/// Per-year season stats (eggs + chicks), for the season-comparison card.
final _seasonStatsProvider =
    Provider.family<AsyncValue<SeasonStats>, ({String userId, int year})>((
      ref,
      args,
    ) {
      final eggStatsAsync = ref.watch(
        _seasonEggStatsStreamProvider(args),
      );
      final chickStatsAsync = ref.watch(
        _seasonChickStatsStreamProvider(args),
      );

      for (final async in [eggStatsAsync, chickStatsAsync]) {
        if (async.hasError) {
          return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
        }
      }
      if (eggStatsAsync.isLoading || chickStatsAsync.isLoading) {
        return const AsyncLoading();
      }

      final eggStats = eggStatsAsync.requireValue;
      final chickStats = chickStatsAsync.requireValue;

      return AsyncData(
        SeasonStats(
          year: args.year,
          totalEggs: eggStats.total,
          fertileEggs: eggStats.fertile,
          hatchedChicks: chickStats.total,
          liveChicks: chickStats.live,
        ),
      );
    });

final _seasonEggStatsStreamProvider =
    StreamProvider.family<({int total, int fertile}), ({String userId, int year})>((
      ref,
      args,
    ) {
      return ref
          .watch(eggsDaoProvider)
          .watchSeasonEggStats(args.userId, args.year);
    });

final _seasonChickStatsStreamProvider =
    StreamProvider.family<({int total, int live}), ({String userId, int year})>((
      ref,
      args,
    ) {
      return ref
          .watch(chicksDaoProvider)
          .watchSeasonChickStats(args.userId, args.year);
    });

/// Compares the two most recent breeding seasons (by year). Returns `null`
/// when fewer than 2 seasons of data exist yet.
final seasonComparisonProvider =
    Provider.family<AsyncValue<SeasonComparison?>, String>((ref, userId) {
      final yearsAsync = ref.watch(_seasonYearsProvider(userId));

      if (yearsAsync.hasError) {
        return AsyncError(
          yearsAsync.error!,
          yearsAsync.stackTrace ?? StackTrace.empty,
        );
      }
      if (yearsAsync.isLoading) {
        return const AsyncLoading();
      }

      final years = yearsAsync.requireValue;
      if (years == null) return const AsyncData(null);

      final previousYear = years[years.length - 2];
      final currentYear = years.last;
      final previousAsync = ref.watch(
        _seasonStatsProvider((userId: userId, year: previousYear)),
      );
      final currentAsync = ref.watch(
        _seasonStatsProvider((userId: userId, year: currentYear)),
      );

      for (final async in [previousAsync, currentAsync]) {
        if (async.hasError) {
          return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
        }
      }
      if (previousAsync.isLoading || currentAsync.isLoading) {
        return const AsyncLoading();
      }

      return AsyncData(
        SeasonComparison(
          previous: previousAsync.requireValue,
          current: currentAsync.requireValue,
        ),
      );
    });

/// Raw SQL-aggregated busiest month/bird/avg-treatment-days (statistics.md
/// SQL aggregation requirement) — see `HealthRecordsDao.watchBusiestMonth` /
/// `watchBusiestBird` / `watchAverageTreatmentDays`.
final _busiestMonthStreamProvider =
    StreamProvider.family<({String month, int count})?, String>((
      ref,
      userId,
    ) {
      return ref.watch(healthRecordsDaoProvider).watchBusiestMonth(userId);
    });

final _busiestBirdStreamProvider =
    StreamProvider.family<({String birdId, int count})?, String>((
      ref,
      userId,
    ) {
      return ref.watch(healthRecordsDaoProvider).watchBusiestBird(userId);
    });

final _averageTreatmentDaysStreamProvider = StreamProvider.family<double?, String>(
  (ref, userId) {
    return ref
        .watch(healthRecordsDaoProvider)
        .watchAverageTreatmentDays(userId);
  },
);

/// Health trend summary. `mostVisitedBirdName` still needs the bird's name,
/// so `birdsStreamProvider` stays watched for that lookup only — birds
/// lists are naturally small per user (unlike health records, which grow
/// unbounded over years and are now fully SQL-aggregated above).
final healthTrendSummaryProvider =
    Provider.family<AsyncValue<HealthTrendSummary>, String>((ref, userId) {
      final busiestMonthAsync = ref.watch(_busiestMonthStreamProvider(userId));
      final busiestBirdAsync = ref.watch(_busiestBirdStreamProvider(userId));
      final avgTreatmentAsync = ref.watch(
        _averageTreatmentDaysStreamProvider(userId),
      );
      final birdsAsync = ref.watch(birdsStreamProvider(userId));

      for (final async in [
        busiestMonthAsync,
        busiestBirdAsync,
        avgTreatmentAsync,
        birdsAsync,
      ]) {
        if (async.hasError) {
          return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
        }
      }
      if (busiestMonthAsync.isLoading ||
          busiestBirdAsync.isLoading ||
          avgTreatmentAsync.isLoading ||
          birdsAsync.isLoading) {
        return const AsyncLoading();
      }

      final busiestMonth = busiestMonthAsync.requireValue;
      final busiestBird = busiestBirdAsync.requireValue;
      final birdsById = {
        for (final bird in birdsAsync.requireValue) bird.id: bird,
      };

      return AsyncData(
        HealthTrendSummary(
          busiestMonthKey: busiestMonth?.month,
          busiestMonthRecordCount: busiestMonth?.count ?? 0,
          mostVisitedBirdId: busiestBird?.birdId,
          mostVisitedBirdName: busiestBird == null
              ? null
              : birdsById[busiestBird.birdId]?.name ?? busiestBird.birdId,
          mostVisitedBirdRecordCount: busiestBird?.count ?? 0,
          averageTreatmentDays: avgTreatmentAsync.requireValue,
        ),
      );
    });

/// Finds the bird with the longest lifespan (birthDate to deathDate, or to
/// [now] if still alive). Ties are not explicitly broken (first max found
/// wins, matching the original iteration-order behavior).
LongevityRecord? findLongestLivedBird(List<Bird> birds, {DateTime? now}) {
  LongevityRecord? longestLivedBird;
  final reference = now ?? DateTime.now();
  for (final bird in birds) {
    final birthDate = bird.birthDate;
    if (birthDate == null) continue;
    final endDate = bird.deathDate ?? reference;
    final days = date_utils.DateUtils.dayDiff(birthDate, endDate);
    if (days < 0) continue;
    if (longestLivedBird == null || days > longestLivedBird.daysLived) {
      longestLivedBird = LongevityRecord(
        birdId: bird.id,
        birdName: bird.name,
        daysLived: days,
      );
    }
  }
  return longestLivedBird;
}

