import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/bird_enums.dart';
import '../../../data/models/marketplace_listing_model.dart';
import '../../../data/repositories/repository_providers.dart';

export 'package:budgie_breeding_tracker/data/models/marketplace_listing_model.dart';
export 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';

/// Feature flag
final isMarketplaceEnabledProvider = Provider<bool>((ref) => true);

/// Filter enums
enum MarketplaceFilter {
  all,
  sale,
  adoption,
  trade,
  wanted;

  String get label => switch (this) {
        MarketplaceFilter.all => 'common.all'.tr(),
        MarketplaceFilter.sale => 'marketplace.type_sale'.tr(),
        MarketplaceFilter.adoption => 'marketplace.type_adoption'.tr(),
        MarketplaceFilter.trade => 'marketplace.type_trade'.tr(),
        MarketplaceFilter.wanted => 'marketplace.type_wanted'.tr(),
      };
}

enum MarketplaceSort {
  newest,
  priceAsc,
  priceDesc;

  String get label => switch (this) {
        MarketplaceSort.newest => 'marketplace.sort_newest'.tr(),
        MarketplaceSort.priceAsc => 'marketplace.sort_price_asc'.tr(),
        MarketplaceSort.priceDesc => 'marketplace.sort_price_desc'.tr(),
      };
}

/// Filter state
class MarketplaceFilterNotifier extends Notifier<MarketplaceFilter> {
  @override
  MarketplaceFilter build() => MarketplaceFilter.all;
}

final marketplaceFilterProvider =
    NotifierProvider<MarketplaceFilterNotifier, MarketplaceFilter>(
  MarketplaceFilterNotifier.new,
);

/// Sort state
class MarketplaceSortNotifier extends Notifier<MarketplaceSort> {
  @override
  MarketplaceSort build() => MarketplaceSort.newest;
}

final marketplaceSortProvider =
    NotifierProvider<MarketplaceSortNotifier, MarketplaceSort>(
  MarketplaceSortNotifier.new,
);

/// Search state
class MarketplaceSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final marketplaceSearchQueryProvider =
    NotifierProvider<MarketplaceSearchQueryNotifier, String>(
  MarketplaceSearchQueryNotifier.new,
);

/// City filter state
class MarketplaceCityFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final marketplaceCityFilterProvider =
    NotifierProvider<MarketplaceCityFilterNotifier, String?>(
  MarketplaceCityFilterNotifier.new,
);

/// Price range filter state
class MarketplacePriceRangeNotifier
    extends Notifier<({double? min, double? max})> {
  @override
  ({double? min, double? max}) build() => (min: null, max: null);
}

final marketplacePriceRangeProvider = NotifierProvider<
    MarketplacePriceRangeNotifier, ({double? min, double? max})>(
  MarketplacePriceRangeNotifier.new,
);

/// Gender filter state
class MarketplaceGenderFilterNotifier extends Notifier<BirdGender?> {
  @override
  BirdGender? build() => null;
}

final marketplaceGenderFilterProvider =
    NotifierProvider<MarketplaceGenderFilterNotifier, BirdGender?>(
  MarketplaceGenderFilterNotifier.new,
);

/// Count of active advanced filters for badge display
final activeFilterCountProvider = Provider<int>((ref) {
  int count = 0;
  if (ref.watch(marketplaceCityFilterProvider) != null) count++;
  final range = ref.watch(marketplacePriceRangeProvider);
  if (range.min != null || range.max != null) count++;
  if (ref.watch(marketplaceGenderFilterProvider) != null) count++;
  return count;
});

/// Listings feed provider
final marketplaceListingsProvider =
    FutureProvider.family<List<MarketplaceListing>, String>(
  (ref, userId) async {
    final repo = ref.watch(marketplaceRepositoryProvider);
    final filter = ref.watch(marketplaceFilterProvider);
    final city = ref.watch(marketplaceCityFilterProvider);

    String? listingType;
    if (filter != MarketplaceFilter.all) {
      listingType = filter.name;
    }

    return repo.getListings(
      currentUserId: userId,
      city: city,
      listingType: listingType,
    );
  },
);

/// Single listing detail
final marketplaceListingByIdProvider =
    FutureProvider.family<MarketplaceListing?, ({String id, String userId})>(
  (ref, params) async {
    final repo = ref.watch(marketplaceRepositoryProvider);
    return repo.getById(id: params.id, currentUserId: params.userId);
  },
);

/// My listings
final myMarketplaceListingsProvider =
    FutureProvider.family<List<MarketplaceListing>, String>(
  (ref, userId) async {
    final repo = ref.watch(marketplaceRepositoryProvider);
    return repo.getByUser(userId: userId, currentUserId: userId);
  },
);

/// Filtered and sorted listings (computed)
final filteredMarketplaceListingsProvider =
    Provider.family<List<MarketplaceListing>, List<MarketplaceListing>>(
  (ref, listings) {
    final sort = ref.watch(marketplaceSortProvider);
    final query = ref.watch(marketplaceSearchQueryProvider).toLowerCase().trim();

    var result = List<MarketplaceListing>.from(listings);

    if (query.isNotEmpty) {
      result = result.where((l) {
        return l.title.toLowerCase().contains(query) ||
            l.description.toLowerCase().contains(query) ||
            l.species.toLowerCase().contains(query) ||
            l.city.toLowerCase().contains(query) ||
            (l.mutation?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Price range filter
    final priceRange = ref.watch(marketplacePriceRangeProvider);
    if (priceRange.min != null) {
      result = result.where((l) => (l.price ?? 0) >= priceRange.min!).toList();
    }
    if (priceRange.max != null) {
      result = result.where((l) => (l.price ?? 0) <= priceRange.max!).toList();
    }

    // Gender filter
    final genderFilter = ref.watch(marketplaceGenderFilterProvider);
    if (genderFilter != null) {
      result = result.where((l) => l.gender == genderFilter).toList();
    }

    switch (sort) {
      case MarketplaceSort.newest:
        result.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      case MarketplaceSort.priceAsc:
        result.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      case MarketplaceSort.priceDesc:
        result.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    }

    return result;
  },
);
