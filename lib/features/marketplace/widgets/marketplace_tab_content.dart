import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../providers/marketplace_form_providers.dart';
import '../providers/marketplace_providers.dart';
import 'marketplace_filter_bar.dart';
import 'marketplace_listing_card.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

/// Scaffold-free marketplace content for embedding in TabBarView.
class MarketplaceTabContent extends ConsumerStatefulWidget {
  const MarketplaceTabContent({super.key});

  @override
  ConsumerState<MarketplaceTabContent> createState() =>
      _MarketplaceTabContentState();
}

class _MarketplaceTabContentState extends ConsumerState<MarketplaceTabContent> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggers the next page when the user scrolls near the bottom (80%).
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final userId = ref.read(currentUserIdProvider);
    final feed = ref.read(marketplaceFeedProvider(userId)).asData?.value;
    if (feed == null || !feed.hasMore || feed.isLoadingMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      ref.read(marketplaceFeedProvider(userId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final feedAsync = ref.watch(marketplaceFeedProvider(userId));

    // Surface favorite-toggle failures — the heart is non-optimistic, so a
    // failed toggle otherwise looks like nothing happened.
    ref.listen<MarketplaceFormState>(marketplaceFormStateProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Column(
      children: [
        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Expanded(child: MarketplaceFilterBar()),
              AppIconButton(
                icon: const Icon(LucideIcons.listChecks, size: 20),
                tooltip: 'marketplace.my_listings'.tr(),
                semanticLabel: 'marketplace.my_listings'.tr(),
                onPressed: () =>
                    context.push('${AppRoutes.marketplace}/my-listings'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(marketplaceFeedProvider(userId));
            },
            child: feedAsync.when(
              loading: () => const LoadingState(),
              error: (error, _) => app.ErrorState(
                message: '${'common.data_load_error'.tr()}: $error',
                onRetry: () => ref.invalidate(marketplaceFeedProvider(userId)),
              ),
              data: (feed) {
                final listings = ref.watch(
                  filteredMarketplaceListingsProvider(feed.items),
                );

                if (feed.items.isEmpty) {
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

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl * 2,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        mainAxisExtent: 232,
                      ),
                  // +1 grid cell for the bottom loading indicator.
                  itemCount: listings.length + (feed.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= listings.length) {
                      return const Center(
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final listing = listings[index];
                    return MarketplaceListingCard(
                      key: ValueKey(listing.id),
                      listing: listing,
                      compact: true,
                      onFavoriteToggle: () => ref
                          .read(marketplaceFormStateProvider.notifier)
                          .toggleFavorite(
                            userId: userId,
                            listingId: listing.id,
                            isFavorited: !listing.isFavoritedByMe,
                          ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
