part of 'chick_providers.dart';

/// Filter options for the chick list.
enum ChickFilter {
  all,
  healthy,
  sick,
  deceased,
  unweaned,
  newborn,
  nestling,
  fledgling,
  juvenile;

  String get label => switch (this) {
    ChickFilter.all => 'common.all'.tr(),
    ChickFilter.healthy => 'chicks.status_healthy'.tr(),
    ChickFilter.sick => 'chicks.status_sick'.tr(),
    ChickFilter.deceased => 'chicks.status_deceased'.tr(),
    ChickFilter.unweaned => 'chicks.status_unweaned'.tr(),
    ChickFilter.newborn => 'chicks.stage_newborn'.tr(),
    ChickFilter.nestling => 'chicks.stage_nestling'.tr(),
    ChickFilter.fledgling => 'chicks.stage_fledgling'.tr(),
    ChickFilter.juvenile => 'chicks.stage_juvenile'.tr(),
  };
}

/// Sort options for the chick list.
enum ChickSort {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  ageYoungest,
  ageOldest;

  String get label => switch (this) {
    ChickSort.newest => 'chicks.sort_newest'.tr(),
    ChickSort.oldest => 'chicks.sort_oldest'.tr(),
    ChickSort.nameAsc => 'chicks.sort_name_asc'.tr(),
    ChickSort.nameDesc => 'chicks.sort_name_desc'.tr(),
    ChickSort.ageYoungest => 'chicks.sort_youngest'.tr(),
    ChickSort.ageOldest => 'chicks.sort_oldest_age'.tr(),
  };
}

/// Current filter selection for the chick list.
class ChickFilterNotifier extends Notifier<ChickFilter> {
  @override
  ChickFilter build() => ChickFilter.all;
}

final chickFilterProvider = NotifierProvider<ChickFilterNotifier, ChickFilter>(
  ChickFilterNotifier.new,
);

/// Current search query for the chick list.
class ChickSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final chickSearchQueryProvider =
    NotifierProvider<ChickSearchQueryNotifier, String>(
      ChickSearchQueryNotifier.new,
    );

/// Manages [ChickSort] state and persists it locally.
class ChickSortNotifier extends Notifier<ChickSort> {
  @override
  ChickSort build() {
    _loadFromPrefs();
    return ChickSort.newest;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppPreferences.keyChickSort);
    if (!ref.mounted) return;
    if (saved != null) {
      final match = ChickSort.values.where((s) => s.name == saved);
      if (match.isNotEmpty) {
        state = match.first;
      }
    }
  }

  Future<void> setSort(ChickSort sort) async {
    state = sort;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPreferences.keyChickSort, sort.name);
  }
}

/// Current sort selection for the chick list, persisted in SharedPreferences.
final chickSortProvider = NotifierProvider<ChickSortNotifier, ChickSort>(
  ChickSortNotifier.new,
);
