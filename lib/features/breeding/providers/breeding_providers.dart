import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';

// Re-export currentUserIdProvider from auth so existing imports keep working.
export 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart'
    show currentUserIdProvider;

/// All breeding pairs for the current user (live stream).
final breedingPairsStreamProvider =
    StreamProvider.family<List<BreedingPair>, String>((ref, userId) {
      final repo = ref.watch(breedingPairRepositoryProvider);
      return repo.watchAll(userId);
    });

/// Active breeding pairs only (live stream).
final activeBreedingPairsProvider =
    StreamProvider.family<List<BreedingPair>, String>((ref, userId) {
      final repo = ref.watch(breedingPairRepositoryProvider);
      return repo.watchActive(userId);
    });

/// Notifier for breeding list filter.
class BreedingFilterNotifier extends Notifier<BreedingFilter> {
  @override
  BreedingFilter build() => BreedingFilter.all;
}

/// Filter state for the breeding list.
final breedingFilterProvider =
    NotifierProvider<BreedingFilterNotifier, BreedingFilter>(
      BreedingFilterNotifier.new,
    );

/// Filtered breeding pairs based on the current filter selection.
final filteredBreedingPairsProvider =
    Provider.family<List<BreedingPair>, List<BreedingPair>>((ref, pairs) {
      final filter = ref.watch(breedingFilterProvider);
      return switch (filter) {
        BreedingFilter.all => pairs,
        BreedingFilter.active =>
          pairs.where((p) => p.status == BreedingStatus.active).toList(),
        BreedingFilter.ongoing =>
          pairs.where((p) => p.status == BreedingStatus.ongoing).toList(),
        BreedingFilter.completed =>
          pairs.where((p) => p.status == BreedingStatus.completed).toList(),
        BreedingFilter.cancelled =>
          pairs.where((p) => p.status == BreedingStatus.cancelled).toList(),
      };
    });

/// Notifier for breeding list search query.
class BreedingSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

/// Search query state for breeding list.
final breedingSearchQueryProvider =
    NotifierProvider<BreedingSearchQueryNotifier, String>(
      BreedingSearchQueryNotifier.new,
    );

/// Searched and filtered breeding pairs (filter first, then search by cage number + bird names).
final searchedAndFilteredBreedingPairsProvider =
    Provider.family<List<BreedingPair>, List<BreedingPair>>((ref, pairs) {
      final filtered = ref.watch(filteredBreedingPairsProvider(pairs));
      final query = ref.watch(breedingSearchQueryProvider).toLowerCase().trim();
      if (query.isEmpty) return filtered;
      if (filtered.isEmpty) return const <BreedingPair>[];

      final hasBirdReferences = filtered.any(
        (pair) => pair.maleId != null || pair.femaleId != null,
      );
      if (!hasBirdReferences) {
        return filtered.where((pair) {
          return pair.cageNumber?.toLowerCase().contains(query) ?? false;
        }).toList();
      }

      // Build bird ID → name lookup from current user's birds
      final userId = ref.watch(currentUserIdProvider);
      final birds = ref.watch(birdsStreamProvider(userId)).value ?? <Bird>[];
      final birdNameMap = <String, String>{
        for (final bird in birds) bird.id: bird.name.toLowerCase(),
      };

      return filtered.where((pair) {
        // Match cage number
        if (pair.cageNumber?.toLowerCase().contains(query) ?? false) {
          return true;
        }
        // Match male bird name
        if (pair.maleId != null &&
            (birdNameMap[pair.maleId!]?.contains(query) ?? false)) {
          return true;
        }
        // Match female bird name
        if (pair.femaleId != null &&
            (birdNameMap[pair.femaleId!]?.contains(query) ?? false)) {
          return true;
        }
        return false;
      }).toList();
    });

/// All incubations for the current user, indexed by breedingPairId (live stream).
/// Used by breeding list to avoid per-card FutureProvider lookups.
final allIncubationsStreamProvider =
    StreamProvider.family<List<Incubation>, String>((ref, userId) {
      final repo = ref.watch(incubationRepositoryProvider);
      return repo.watchAll(userId);
    });

/// Map of breedingPairId → first Incubation (derived from allIncubationsStreamProvider).
final incubationByPairMapProvider =
    Provider.family<Map<String, Incubation>, String>((ref, userId) {
      final incubations =
          ref.watch(allIncubationsStreamProvider(userId)).value ??
          <Incubation>[];
      final map = <String, Incubation>{};
      for (final inc in incubations) {
        if (inc.breedingPairId != null &&
            !map.containsKey(inc.breedingPairId)) {
          map[inc.breedingPairId!] = inc;
        }
      }
      return map;
    });

/// Map of incubationId → List<Egg> (derived from eggsStreamProvider).
final eggsByIncubationMapProvider =
    Provider.family<Map<String, List<Egg>>, String>((ref, userId) {
      final eggs = ref.watch(eggsStreamProvider(userId)).value ?? <Egg>[];
      final map = <String, List<Egg>>{};
      for (final egg in eggs) {
        if (egg.incubationId != null) {
          map.putIfAbsent(egg.incubationId!, () => []).add(egg);
        }
      }
      return map;
    });

/// Notifier for breeding list sort selection.
class BreedingSortNotifier extends Notifier<BreedingSort> {
  @override
  BreedingSort build() => BreedingSort.newest;
}

/// Current sort selection for the breeding list.
final breedingSortProvider = NotifierProvider<BreedingSortNotifier, BreedingSort>(
  BreedingSortNotifier.new,
);

/// Sorted, searched and filtered breeding pairs (final display list).
final sortedAndFilteredBreedingPairsProvider =
    Provider.family<List<BreedingPair>, List<BreedingPair>>((ref, pairs) {
      final searched = ref.watch(searchedAndFilteredBreedingPairsProvider(pairs));
      final sort = ref.watch(breedingSortProvider);

      final sorted = List<BreedingPair>.of(searched);
      switch (sort) {
        case BreedingSort.newest:
          sorted.sort(
            (a, b) => (b.createdAt ?? DateTime(1900)).compareTo(
              a.createdAt ?? DateTime(1900),
            ),
          );
        case BreedingSort.oldest:
          sorted.sort(
            (a, b) => (a.createdAt ?? DateTime(1900)).compareTo(
              b.createdAt ?? DateTime(1900),
            ),
          );
        case BreedingSort.statusAsc:
          sorted.sort((a, b) => a.status.name.compareTo(b.status.name));
        case BreedingSort.statusDesc:
          sorted.sort((a, b) => b.status.name.compareTo(a.status.name));
        case BreedingSort.cageAsc:
          sorted.sort(
            (a, b) => (a.cageNumber ?? '').compareTo(b.cageNumber ?? ''),
          );
        case BreedingSort.cageDesc:
          sorted.sort(
            (a, b) => (b.cageNumber ?? '').compareTo(a.cageNumber ?? ''),
          );
      }
      return sorted;
    });

/// Filter options for the breeding list.
enum BreedingFilter {
  all,
  active,
  ongoing,
  completed,
  cancelled;

  String get label => switch (this) {
    BreedingFilter.all => 'common.all'.tr(),
    BreedingFilter.active => 'breeding.status_active'.tr(),
    BreedingFilter.ongoing => 'breeding.status_ongoing'.tr(),
    BreedingFilter.completed => 'breeding.status_completed'.tr(),
    BreedingFilter.cancelled => 'breeding.status_cancelled'.tr(),
  };
}

/// Sort options for the breeding list.
enum BreedingSort {
  newest,
  oldest,
  statusAsc,
  statusDesc,
  cageAsc,
  cageDesc;

  String get label => switch (this) {
    BreedingSort.newest => 'breeding.sort_newest'.tr(),
    BreedingSort.oldest => 'breeding.sort_oldest'.tr(),
    BreedingSort.statusAsc => 'breeding.sort_status_asc'.tr(),
    BreedingSort.statusDesc => 'breeding.sort_status_desc'.tr(),
    BreedingSort.cageAsc => 'breeding.sort_cage_asc'.tr(),
    BreedingSort.cageDesc => 'breeding.sort_cage_desc'.tr(),
  };
}
