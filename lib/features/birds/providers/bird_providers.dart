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

/// Notifier for bird list visual mode.
class BirdListViewModeNotifier extends Notifier<BirdListViewMode> {
  @override
  BirdListViewMode build() => BirdListViewMode.list;

  void setMode(BirdListViewMode mode) {
    state = mode;
  }
}

/// Current visual mode for the bird list.
final birdListViewModeProvider =
    NotifierProvider<BirdListViewModeNotifier, BirdListViewMode>(
      BirdListViewModeNotifier.new,
    );

/// Filtered birds based on the current filter selection.
///
/// autoDispose: family is keyed on a `List<Bird>` (identity-equality), so
/// every emission from `birdsStreamProvider` produces a new family entry.
/// Without autoDispose the old entries linger indefinitely, leaking memory
/// proportional to mutation frequency. autoDispose evicts the stale entries
/// as soon as the screen rebuilds with the new list.
final filteredBirdsProvider = Provider.autoDispose.family<List<Bird>, List<Bird>>((
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
    BirdFilter.gifted =>
      birds.where((b) => b.status == BirdStatus.gifted).toList(),
  };
});

/// Searched and filtered birds (applies search on top of filter).
/// autoDispose: see [filteredBirdsProvider] — same identity-keyed leak.
final searchedAndFilteredBirdsProvider =
    Provider.autoDispose.family<List<Bird>, List<Bird>>((ref, birds) {
      final filtered = ref.watch(filteredBirdsProvider(birds));
      final query = ref.watch(
        birdSearchQueryProvider.select((value) => value.toLowerCase().trim()),
      );

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
/// autoDispose: see [filteredBirdsProvider] — same identity-keyed leak.
final sortedAndFilteredBirdsProvider = Provider.autoDispose.family<List<Bird>, List<Bird>>((
  ref,
  birds,
) {
  final searched = ref.watch(searchedAndFilteredBirdsProvider(birds));
  final sort = ref.watch(birdSortProvider);

  final sorted = List<Bird>.of(searched);
  switch (sort) {
    case BirdSort.nameAsc:
      sorted.sort((a, b) => _naturalCompare(a.name, b.name));
    case BirdSort.nameDesc:
      sorted.sort((a, b) => _naturalCompare(b.name, a.name));
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
    case BirdSort.ringAsc:
      sorted.sort(
        (a, b) => _compareOptionalNatural(
          a.ringNumber,
          b.ringNumber,
          descending: false,
        ),
      );
    case BirdSort.ringDesc:
      sorted.sort(
        (a, b) => _compareOptionalNatural(
          a.ringNumber,
          b.ringNumber,
          descending: true,
        ),
      );
  }
  return sorted;
});

/// Read-only cage occupancy summary assembled from current bird records.
class CageSummary {
  final String? cageNumber;
  final List<Bird> birds;

  const CageSummary({required this.cageNumber, required this.birds});

  bool get isUnassigned => cageNumber == null || cageNumber!.trim().isEmpty;
  int get aliveCount => birds.where((bird) => bird.isAlive).length;
}

/// Groups alive birds by cage number for the cage ledger view.
final cageSummariesProvider = Provider.family<List<CageSummary>, List<Bird>>(
  (ref, birds) => buildCageSummaries(birds),
);

List<CageSummary> buildCageSummaries(List<Bird> birds) {
  final grouped = <String?, List<Bird>>{};

  for (final bird in birds) {
    if (!bird.isAlive) continue;
    final cage = bird.cageNumber?.trim();
    final key = cage == null || cage.isEmpty ? null : cage;
    grouped.putIfAbsent(key, () => <Bird>[]).add(bird);
  }

  final summaries = grouped.entries.map((entry) {
    final cageBirds = List<Bird>.of(entry.value)
      ..sort((a, b) => _naturalCompare(a.name, b.name));
    return CageSummary(cageNumber: entry.key, birds: cageBirds);
  }).toList();

  summaries.sort((a, b) {
    if (a.isUnassigned && b.isUnassigned) return 0;
    if (a.isUnassigned) return 1;
    if (b.isUnassigned) return -1;
    return _naturalCompare(a.cageNumber!, b.cageNumber!);
  });

  return summaries;
}

/// Filter options for the bird list.
enum BirdFilter {
  all,
  male,
  female,
  alive,
  dead,
  sold,
  gifted;

  String get label => switch (this) {
    BirdFilter.all => 'common.all'.tr(),
    BirdFilter.male => 'birds.male'.tr(),
    BirdFilter.female => 'birds.female'.tr(),
    BirdFilter.alive => 'birds.status_alive'.tr(),
    BirdFilter.dead => 'birds.status_dead'.tr(),
    BirdFilter.sold => 'birds.status_sold'.tr(),
    BirdFilter.gifted => 'birds.status_gifted'.tr(),
  };
}

/// Sort options for the bird list.
enum BirdSort {
  nameAsc,
  nameDesc,
  ageNewest,
  ageOldest,
  dateNewest,
  dateOldest,
  ringAsc,
  ringDesc;

  String get label => switch (this) {
    BirdSort.nameAsc => 'birds.sort_name_asc'.tr(),
    BirdSort.nameDesc => 'birds.sort_name_desc'.tr(),
    BirdSort.ageNewest => 'birds.sort_age_newest'.tr(),
    BirdSort.ageOldest => 'birds.sort_age_oldest'.tr(),
    BirdSort.dateNewest => 'birds.sort_date_newest'.tr(),
    BirdSort.dateOldest => 'birds.sort_date_oldest'.tr(),
    BirdSort.ringAsc => 'birds.sort_ring_asc'.tr(),
    BirdSort.ringDesc => 'birds.sort_ring_desc'.tr(),
  };
}

/// Visual mode options for the bird list.
enum BirdListViewMode { list, grid }

final _naturalChunkPattern = RegExp(r'(\d+)|(\D+)');

/// Natural sort comparison: splits strings into text and numeric chunks
/// so that "Kuş-2" comes before "Kuş-10".
int _naturalCompare(String a, String b) {
  final aChunks = _naturalChunkPattern.allMatches(a.toLowerCase()).toList();
  final bChunks = _naturalChunkPattern.allMatches(b.toLowerCase()).toList();

  for (var i = 0; i < aChunks.length && i < bChunks.length; i++) {
    final aText = aChunks[i].group(0)!;
    final bText = bChunks[i].group(0)!;

    final aNum = int.tryParse(aText);
    final bNum = int.tryParse(bText);

    int cmp;
    if (aNum != null && bNum != null) {
      cmp = aNum.compareTo(bNum);
    } else {
      cmp = aText.compareTo(bText);
    }
    if (cmp != 0) return cmp;
  }
  return aChunks.length.compareTo(bChunks.length);
}

int _compareOptionalNatural(String? a, String? b, {required bool descending}) {
  final normalizedA = a?.trim();
  final normalizedB = b?.trim();
  final aMissing = normalizedA == null || normalizedA.isEmpty;
  final bMissing = normalizedB == null || normalizedB.isEmpty;

  if (aMissing && bMissing) return 0;
  if (aMissing) return 1;
  if (bMissing) return -1;

  final result = _naturalCompare(normalizedA, normalizedB);
  return descending ? -result : result;
}
