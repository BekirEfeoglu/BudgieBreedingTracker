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
