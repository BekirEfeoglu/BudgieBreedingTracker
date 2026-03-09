import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';

/// Lightweight count streams for dashboard (SQL COUNT instead of full list).
final birdCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(birdsDaoProvider).watchCount(userId);
});

final eggCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(eggsDaoProvider).watchCount(userId);
});

final chickCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(chicksDaoProvider).watchCount(userId);
});

final activeBreedingCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(breedingPairsDaoProvider).watchActiveCount(userId);
});

final incubatingEggCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(eggsDaoProvider).watchIncubatingCount(userId);
});

/// Active incubation count for free tier limit display.
final activeIncubationCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(incubationsDaoProvider).watchActiveCount(userId);
});

/// Dashboard statistics computed from lightweight count streams.
/// Uses SQL COUNT queries instead of loading full entity lists.
final dashboardStatsProvider =
    Provider.family<AsyncValue<DashboardStats>, String>((ref, userId) {
  final birdsCount = ref.watch(birdCountProvider(userId));
  final eggsCount = ref.watch(eggCountProvider(userId));
  final chicksCount = ref.watch(chickCountProvider(userId));
  final abCount = ref.watch(activeBreedingCountProvider(userId));
  final ieCount = ref.watch(incubatingEggCountProvider(userId));

  // Return loading if any count is still loading
  if (birdsCount.isLoading || eggsCount.isLoading ||
      chicksCount.isLoading || abCount.isLoading ||
      ieCount.isLoading) {
    return const AsyncLoading();
  }

  // Return first error encountered
  final all = [birdsCount, eggsCount, chicksCount, abCount, ieCount];
  for (final c in all) {
    if (c.hasError) return AsyncError(c.error!, c.stackTrace!);
  }

  return AsyncData(DashboardStats(
    totalBirds: birdsCount.requireValue,
    totalEggs: eggsCount.requireValue,
    totalChicks: chicksCount.requireValue,
    activeBreedings: abCount.requireValue,
    incubatingEggs: ieCount.requireValue,
  ));
});

/// Recent chicks sorted by hatch date (max 5) — DAO-level SQL LIMIT.
final recentChicksProvider =
    StreamProvider.family<List<Chick>, String>((ref, userId) {
  return ref.watch(chicksDaoProvider).watchRecent(userId, limit: 5);
});

/// Active breeding pairs (active + ongoing) — DAO-level SQL LIMIT.
final activeBreedingsForDashboardProvider =
    StreamProvider.family<List<BreedingPair>, String>((ref, userId) {
  return ref.watch(breedingPairsDaoProvider).watchActiveLimited(userId, limit: 3);
});

/// Count of chicks ready to move to birds (60+ days old and not yet moved) — SQL COUNT.
final unweanedChicksCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(chicksDaoProvider).watchUnweanedCount(userId);
});

/// Summary of incubating eggs with remaining days until expected hatch.
class IncubatingEggSummary {
  final Egg egg;
  final int daysRemaining;

  const IncubatingEggSummary({required this.egg, required this.daysRemaining});
}

final incubatingEggsSummaryProvider =
    Provider.family<AsyncValue<List<IncubatingEggSummary>>, String>(
        (ref, userId) {
  final eggsAsync = ref.watch(incubatingEggsLimitedProvider(userId));

  return eggsAsync.whenData((eggs) {
    final now = DateTime.now();
    return eggs.map((e) {
      final expectedHatch = e.layDate.add(
        const Duration(days: IncubationConstants.incubationPeriodDays),
      );
      final remaining = expectedHatch.difference(now).inDays;
      return IncubatingEggSummary(egg: e, daysRemaining: remaining);
    }).toList()
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  });
});

/// Incubating eggs with SQL LIMIT (for dashboard).
final incubatingEggsLimitedProvider =
    StreamProvider.family<List<Egg>, String>((ref, userId) {
  return ref.watch(eggsDaoProvider).watchIncubatingLimited(userId, limit: 3);
});
