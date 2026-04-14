import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/marketplace_listing_card.dart';

class MarketplaceFavoritesScreen extends ConsumerWidget {
  const MarketplaceFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final listingsAsync = ref.watch(marketplaceFavoritesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('marketplace.favorites'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(marketplaceFavoritesProvider(userId));
        },
        child: listingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => app.ErrorState(
            message: '${'common.data_load_error'.tr()}: $error',
            onRetry: () =>
                ref.invalidate(marketplaceFavoritesProvider(userId)),
          ),
          data: (listings) {
            if (listings.isEmpty) {
              return EmptyState(
                icon: const Icon(LucideIcons.heart),
                title: 'marketplace.no_favorites'.tr(),
                subtitle: 'marketplace.no_favorites_hint'.tr(),
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
