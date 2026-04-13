import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';

// Re-export shared stream providers so existing intra-feature imports
// and cross-feature imports continue to work without changes.
export 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart'
    show currentUserIdProvider;
export 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
export 'package:budgie_breeding_tracker/data/providers/breeding_detail_stream_providers.dart'
    show selectPrimaryIncubation;

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

      final userId = ref.watch(currentUserIdProvider);
      final birdNames = ref.watch(birdNameMapProvider(userId));

      return filtered.where((pair) {
        // Match cage number
        if (pair.cageNumber?.toLowerCase().contains(query) ?? false) {
          return true;
        }
        // Match male bird name
        if (pair.maleId != null &&
            (birdNames[pair.maleId!]?.contains(query) ?? false)) {
          return true;
        }
        // Match female bird name
        if (pair.femaleId != null &&
            (birdNames[pair.femaleId!]?.contains(query) ?? false)) {
          return true;
        }
        return false;
      }).toList();
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
        case BreedingSort.cageAsc:
          sorted.sort((a, b) => _compareCageNumbers(a.cageNumber, b.cageNumber));
        case BreedingSort.cageDesc:
          sorted.sort((a, b) => _compareCageNumbers(b.cageNumber, a.cageNumber));
      }
      return sorted;
    });

/// Compares cage numbers numerically (e.g. "2" < "10").
/// Falls back to lexicographic comparison for non-numeric values.
int _compareCageNumbers(String? a, String? b) {
  final aVal = a ?? '';
  final bVal = b ?? '';
  final aNum = int.tryParse(aVal);
  final bNum = int.tryParse(bVal);
  if (aNum != null && bNum != null) return aNum.compareTo(bNum);
  if (aNum != null) return -1;
  if (bNum != null) return 1;
  return aVal.compareTo(bVal);
}

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
  cageAsc,
  cageDesc;

  String get label => switch (this) {
    BreedingSort.newest => 'breeding.sort_newest'.tr(),
    BreedingSort.oldest => 'breeding.sort_oldest'.tr(),
    BreedingSort.cageAsc => 'breeding.sort_cage_asc'.tr(),
    BreedingSort.cageDesc => 'breeding.sort_cage_desc'.tr(),
  };
}
