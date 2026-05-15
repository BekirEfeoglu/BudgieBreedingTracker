import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_highlight_models.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/egg_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/health_record_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

export 'package:budgie_breeding_tracker/data/models/statistics_highlight_models.dart';

final clutchesStreamProvider = StreamProvider.family<List<Clutch>, String>((
  ref,
  userId,
) {
  return ref.watch(clutchRepositoryProvider).watchAll(userId);
});

final personalRecordsProvider =
    Provider.family<AsyncValue<PersonalRecords>, String>((ref, userId) {
      final birdsAsync = ref.watch(birdsStreamProvider(userId));
      final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
      final clutchesAsync = ref.watch(clutchesStreamProvider(userId));
      final chicksAsync = ref.watch(chicksStreamProvider(userId));

      for (final async in [
        birdsAsync,
        pairsAsync,
        clutchesAsync,
        chicksAsync,
      ]) {
        if (async.hasError) {
          return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
        }
      }
      if (birdsAsync.isLoading ||
          pairsAsync.isLoading ||
          clutchesAsync.isLoading ||
          chicksAsync.isLoading) {
        return const AsyncLoading();
      }

      return AsyncData(
        buildPersonalRecords(
          birds: birdsAsync.requireValue,
          pairs: pairsAsync.requireValue,
          clutches: clutchesAsync.requireValue,
          chicks: chicksAsync.requireValue,
        ),
      );
    });

final seasonComparisonProvider =
    Provider.family<AsyncValue<SeasonComparison?>, String>((ref, userId) {
      final eggsAsync = ref.watch(eggsStreamProvider(userId));
      final chicksAsync = ref.watch(chicksStreamProvider(userId));

      for (final async in [eggsAsync, chicksAsync]) {
        if (async.hasError) {
          return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
        }
      }
      if (eggsAsync.isLoading || chicksAsync.isLoading) {
        return const AsyncLoading();
      }

      return AsyncData(
        buildSeasonComparison(
          eggs: eggsAsync.requireValue,
          chicks: chicksAsync.requireValue,
        ),
      );
    });

final healthTrendSummaryProvider =
    Provider.family<AsyncValue<HealthTrendSummary>, String>((ref, userId) {
      final recordsAsync = ref.watch(healthRecordsStreamProvider(userId));
      final birdsAsync = ref.watch(birdsStreamProvider(userId));

      for (final async in [recordsAsync, birdsAsync]) {
        if (async.hasError) {
          return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
        }
      }
      if (recordsAsync.isLoading || birdsAsync.isLoading) {
        return const AsyncLoading();
      }

      return AsyncData(
        buildHealthTrend(
          records: recordsAsync.requireValue,
          birds: birdsAsync.requireValue,
        ),
      );
    });

PersonalRecords buildPersonalRecords({
  required List<Bird> birds,
  required List<BreedingPair> pairs,
  required List<Clutch> clutches,
  required List<Chick> chicks,
  DateTime? now,
}) {
  final chicksByYear = <int, int>{};
  for (final chick in chicks) {
    final hatchDate = chick.hatchDate;
    if (hatchDate == null) continue;
    chicksByYear[hatchDate.year] = (chicksByYear[hatchDate.year] ?? 0) + 1;
  }

  final mostProductiveSeason = _maxEntry(chicksByYear) == null
      ? null
      : SeasonRecord(
          year: _maxEntry(chicksByYear)!.key,
          chickCount: _maxEntry(chicksByYear)!.value,
        );

  final clutchToPair = {
    for (final clutch in clutches)
      if (clutch.breedingId != null) clutch.id: clutch.breedingId!,
  };
  final validPairIds = pairs.map((pair) => pair.id).toSet();
  final chicksByPair = <String, int>{};
  for (final chick in chicks) {
    final clutchId = chick.clutchId;
    if (clutchId == null) continue;
    final pairId = clutchToPair[chick.clutchId];
    if (pairId == null || !validPairIds.contains(pairId)) continue;
    chicksByPair[pairId] = (chicksByPair[pairId] ?? 0) + 1;
  }
  final topPairEntry = _maxEntry(chicksByPair);

  LongevityRecord? longestLivedBird;
  final reference = now ?? DateTime.now();
  for (final bird in birds) {
    final birthDate = bird.birthDate;
    if (birthDate == null) continue;
    final endDate = bird.deathDate ?? reference;
    final days = endDate.difference(birthDate).inDays;
    if (days < 0) continue;
    if (longestLivedBird == null || days > longestLivedBird.daysLived) {
      longestLivedBird = LongevityRecord(
        birdId: bird.id,
        birdName: bird.name,
        daysLived: days,
      );
    }
  }

  return PersonalRecords(
    mostProductiveSeason: mostProductiveSeason,
    topPair: topPairEntry == null
        ? null
        : TopPairRecord(
            pairId: topPairEntry.key,
            chickCount: topPairEntry.value,
          ),
    longestLivedBird: longestLivedBird,
  );
}

SeasonComparison? buildSeasonComparison({
  required List<Egg> eggs,
  required List<Chick> chicks,
}) {
  final years = <int>{};
  for (final egg in eggs) {
    years.add(egg.layDate.year);
  }
  for (final chick in chicks) {
    final hatchDate = chick.hatchDate;
    if (hatchDate != null) years.add(hatchDate.year);
  }
  if (years.length < 2) return null;

  final sortedYears = years.toList()..sort();
  final previousYear = sortedYears[sortedYears.length - 2];
  final currentYear = sortedYears.last;

  return SeasonComparison(
    previous: _buildSeasonStats(previousYear, eggs, chicks),
    current: _buildSeasonStats(currentYear, eggs, chicks),
  );
}

HealthTrendSummary buildHealthTrend({
  required List<HealthRecord> records,
  required List<Bird> birds,
}) {
  if (records.isEmpty) return const HealthTrendSummary();

  final byMonth = <String, int>{};
  final byBird = <String, int>{};
  final treatmentDurations = <int>[];
  for (final record in records) {
    final monthKey =
        '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
    byMonth[monthKey] = (byMonth[monthKey] ?? 0) + 1;

    final birdId = record.birdId;
    if (birdId != null) byBird[birdId] = (byBird[birdId] ?? 0) + 1;

    final followUpDate = record.followUpDate;
    if (followUpDate != null && !followUpDate.isBefore(record.date)) {
      treatmentDurations.add(followUpDate.difference(record.date).inDays);
    }
  }

  final busiestMonth = _maxEntry(byMonth);
  final busiestBird = _maxEntry(byBird);
  final birdsById = {for (final bird in birds) bird.id: bird};
  final averageTreatmentDays = treatmentDurations.isEmpty
      ? null
      : treatmentDurations.reduce((a, b) => a + b) / treatmentDurations.length;

  return HealthTrendSummary(
    busiestMonthKey: busiestMonth?.key,
    busiestMonthRecordCount: busiestMonth?.value ?? 0,
    mostVisitedBirdId: busiestBird?.key,
    mostVisitedBirdName: busiestBird == null
        ? null
        : birdsById[busiestBird.key]?.name ?? busiestBird.key,
    mostVisitedBirdRecordCount: busiestBird?.value ?? 0,
    averageTreatmentDays: averageTreatmentDays,
  );
}

SeasonStats _buildSeasonStats(int year, List<Egg> eggs, List<Chick> chicks) {
  final seasonEggs = eggs.where((egg) => egg.layDate.year == year).toList();
  final fertileEggs = seasonEggs
      .where(
        (egg) =>
            egg.status == EggStatus.fertile || egg.status == EggStatus.hatched,
      )
      .length;
  final seasonChicks = chicks
      .where((chick) => chick.hatchDate?.year == year)
      .toList();

  return SeasonStats(
    year: year,
    totalEggs: seasonEggs.length,
    fertileEggs: fertileEggs,
    hatchedChicks: seasonChicks.length,
    liveChicks: seasonChicks
        .where((chick) => chick.healthStatus != ChickHealthStatus.deceased)
        .length,
  );
}

MapEntry<K, int>? _maxEntry<K>(Map<K, int> values) {
  if (values.isEmpty) return null;
  final entries = values.entries.toList()
    ..sort((a, b) {
      final valueCompare = b.value.compareTo(a.value);
      if (valueCompare != 0) return valueCompare;
      return a.key.toString().compareTo(b.key.toString());
    });
  return entries.first;
}
