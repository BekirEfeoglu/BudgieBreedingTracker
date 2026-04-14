import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../widgets/marketplace_listing_card.dart';

final _sellerListingsProvider = FutureProvider.autoDispose
    .family<dynamic, ({String sellerId, String currentUserId})>(
  (ref, params) async {
    final repo = ref.watch(marketplaceRepositoryProvider);
    return repo.getByUser(
      userId: params.sellerId,
      currentUserId: params.currentUserId,
    );
  },
);

class MarketplaceSellerListingsScreen extends ConsumerWidget {
  final String sellerId;

  const MarketplaceSellerListingsScreen({
    super.key,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final params = (sellerId: sellerId, currentUserId: currentUserId);
    final listingsAsync = ref.watch(_sellerListingsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text('marketplace.seller_listings'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_sellerListingsProvider(params));
        },
        child: listingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => app.ErrorState(
            message: '${'common.data_load_error'.tr()}: $error',
            onRetry: () => ref.invalidate(_sellerListingsProvider(params)),
          ),
          data: (listings) {
            if (listings.isEmpty) {
              return EmptyState(
                icon: const Icon(LucideIcons.store),
                title: 'marketplace.no_listings'.tr(),
                subtitle: 'marketplace.no_listings_hint'.tr(),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xxxl * 2,
              ),
              itemCount: listings.length,
              itemBuilder: (context, index) => MarketplaceListingCard(
                key: ValueKey(listings[index].id),
                listing: listings[index],
              ),
            );
          },
        ),
      ),
    );
  }
}
