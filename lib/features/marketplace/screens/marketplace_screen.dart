import 'dart:async';

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
import '../../../router/route_names.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/marketplace_filter_bar.dart';
import '../widgets/marketplace_listing_card.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(marketplaceSearchQueryProvider.notifier).state = value.trim();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'marketplace.search_hint'.tr(),
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(marketplaceSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
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
