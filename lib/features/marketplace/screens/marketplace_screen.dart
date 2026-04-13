import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/fab_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import '../../../router/route_names.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/marketplace_filter_bar.dart';
import '../widgets/marketplace_listing_card.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final listingsAsync = ref.watch(marketplaceListingsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('marketplace.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.listChecks),
            tooltip: 'marketplace.my_listings'.tr(),
            onPressed: () =>
                context.push('${AppRoutes.marketplace}/my-listings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const MarketplaceFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(marketplaceListingsProvider(userId));
              },
              child: listingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => app.ErrorState(
                  message: '${'common.data_load_error'.tr()}: $error',
                  onRetry: () =>
                      ref.invalidate(marketplaceListingsProvider(userId)),
                ),
                data: (allListings) {
                  final listings = ref.watch(
                    filteredMarketplaceListingsProvider(allListings),
                  );

                  if (allListings.isEmpty) {
                    return EmptyState(
                      icon: const Icon(LucideIcons.store),
                      title: 'marketplace.no_listings'.tr(),
                      subtitle: 'marketplace.no_listings_hint'.tr(),
                      actionLabel: 'marketplace.add_listing'.tr(),
                      onAction: () =>
                          context.push('${AppRoutes.marketplace}/form'),
                    );
                  }

                  if (listings.isEmpty) {
                    return EmptyState(
                      icon: const Icon(LucideIcons.searchX),
                      title: 'common.no_results'.tr(),
                      subtitle: 'marketplace.no_results'.tr(),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xxxl * 2,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) =>
                        MarketplaceListingCard(
                          key: ValueKey(listings[index].id),
                          listing: listings[index],
                        ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FabButton(
        icon: const Icon(LucideIcons.plus),
        tooltip: 'marketplace.add_listing'.tr(),
        onPressed: () => context.push('${AppRoutes.marketplace}/form'),
      ),
    );
  }
}
