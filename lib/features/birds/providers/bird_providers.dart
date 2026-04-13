import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

// Re-export shared stream providers so existing intra-feature imports
// continue to work without changes.
export 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';

/// Notifier for bird list filter selection.
class BirdFilterNotifier extends Notifier<BirdFilter> {
  @override
  BirdFilter build() => BirdFilter.all;
}

/// Current filter selection for the bird list.
final birdFilterProvider = NotifierProvider<BirdFilterNotifier, BirdFilter>(
  BirdFilterNotifier.new,
);

/// Notifier for bird list search query.
class BirdSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

/// Current search query for the bird list.
final birdSearchQueryProvider =
    NotifierProvider<BirdSearchQueryNotifier, String>(
      BirdSearchQueryNotifier.new,
    );

/// Notifier for bird list sort selection.
class BirdSortNotifier extends Notifier<BirdSort> {
  @override
  BirdSort build() => BirdSort.nameAsc;
}

/// Current sort selection for the bird list.
final birdSortProvider = NotifierProvider<BirdSortNotifier, BirdSort>(
  BirdSortNotifier.new,
);

/// Filtered birds based on the current filter selection.
final filteredBirdsProvider = Provider.family<List<Bird>, List<Bird>>((
  ref,
  birds,
) {
  final filter = ref.watch(birdFilterProvider);
  return switch (filter) {
    BirdFilter.all => birds,
    BirdFilter.male => birds.where((b) => b.gender == BirdGender.male).toList(),
    BirdFilter.female =>
      birds.where((b) => b.gender == BirdGender.female).toList(),
    BirdFilter.alive =>
      birds.where((b) => b.status == BirdStatus.alive).toList(),
    BirdFilter.dead => birds.where((b) => b.status == BirdStatus.dead).toList(),
    BirdFilter.sold => birds.where((b) => b.status == BirdStatus.sold).toList(),
  };
});

/// Searched and filtered birds (applies search on top of filter).
final searchedAndFilteredBirdsProvider =
    Provider.family<List<Bird>, List<Bird>>((ref, birds) {
      final filtered = ref.watch(filteredBirdsProvider(birds));
      final query = ref.watch(birdSearchQueryProvider).toLowerCase().trim();

      if (query.isEmpty) return filtered;

      return filtered.where((bird) {
        final nameMatch = bird.name.toLowerCase().contains(query);
        final ringMatch =
            bird.ringNumber?.toLowerCase().contains(query) ?? false;
        final cageMatch =
            bird.cageNumber?.toLowerCase().contains(query) ?? false;
        return nameMatch || ringMatch || cageMatch;
      }).toList();
    });

/// Sorted, searched and filtered birds (final display list).
final sortedAndFilteredBirdsProvider = Provider.family<List<Bird>, List<Bird>>((
  ref,
  birds,
) {
  final searched = ref.watch(searchedAndFilteredBirdsProvider(birds));
  final sort = ref.watch(birdSortProvider);

  final sorted = List<Bird>.of(searched);
  switch (sort) {
    case BirdSort.nameAsc:
      sorted.sort((a, b) => a.name.compareTo(b.name));
    case BirdSort.nameDesc:
      sorted.sort((a, b) => b.name.compareTo(a.name));
    case BirdSort.ageNewest:
      sorted.sort(
        (a, b) => (b.birthDate ?? DateTime(1900)).compareTo(
          a.birthDate ?? DateTime(1900),
        ),
      );
    case BirdSort.ageOldest:
      sorted.sort(
        (a, b) => (a.birthDate ?? DateTime(1900)).compareTo(
          b.birthDate ?? DateTime(1900),
        ),
      );
    case BirdSort.dateNewest:
      sorted.sort(
        (a, b) => (b.createdAt ?? DateTime(1900)).compareTo(
          a.createdAt ?? DateTime(1900),
        ),
      );
    case BirdSort.dateOldest:
      sorted.sort(
        (a, b) => (a.createdAt ?? DateTime(1900)).compareTo(
          b.createdAt ?? DateTime(1900),
        ),
      );
  }
  return sorted;
});

/// Filter options for the bird list.
enum BirdFilter {
  all,
  male,
  female,
  alive,
  dead,
  sold;

  String get label => switch (this) {
    BirdFilter.all => 'common.all'.tr(),
    BirdFilter.male => 'birds.male'.tr(),
    BirdFilter.female => 'birds.female'.tr(),
    BirdFilter.alive => 'birds.status_alive'.tr(),
    BirdFilter.dead => 'birds.status_dead'.tr(),
    BirdFilter.sold => 'birds.status_sold'.tr(),
  };
}

/// Sort options for the bird list.
enum BirdSort {
  nameAsc,
  nameDesc,
  ageNewest,
  ageOldest,
  dateNewest,
  dateOldest;

  String get label => switch (this) {
    BirdSort.nameAsc => 'birds.sort_name_asc'.tr(),
    BirdSort.nameDesc => 'birds.sort_name_desc'.tr(),
    BirdSort.ageNewest => 'birds.sort_age_newest'.tr(),
    BirdSort.ageOldest => 'birds.sort_age_oldest'.tr(),
    BirdSort.dateNewest => 'birds.sort_date_newest'.tr(),
    BirdSort.dateOldest => 'birds.sort_date_oldest'.tr(),
  };
}
