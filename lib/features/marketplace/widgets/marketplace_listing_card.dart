import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/marketplace_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/marketplace_listing_model.dart';
import '../../../router/route_names.dart';

// Marketplace listing type badge colors (domain-specific, not theme-dependent)
abstract final class _ListingTypeColors {
  static const sale = Color(0xFF2196F3);
  static const adoption = Color(0xFFE91E63);
  static const trade = Color(0xFF9C27B0);
  static const wanted = Color(0xFFFF9800);
  static const unknown = Color(0xFF9E9E9E);
}

class MarketplaceListingCard extends StatelessWidget {
  final MarketplaceListing listing;

  const MarketplaceListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.marketplace}/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listing.primaryImageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: listing.primaryImageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 640,
                  errorWidget: (_, _, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      LucideIcons.image,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.isVerifiedBreeder)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            LucideIcons.badgeCheck,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      StatusBadge(
                        label: _listingTypeLabel(listing.listingType),
                        color: _listingTypeColor(listing.listingType),
                        icon: Icon(
                          _listingTypeIcon(listing.listingType),
                          size: 14,
                        ),
                      ),
                      const Spacer(),
                      if (listing.price != null)
                        Text(
                          listing.priceDisplay,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        listing.city,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${listing.species} · ${listing.gender.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _listingTypeLabel(MarketplaceListingType type) => switch (type) {
        MarketplaceListingType.sale => 'marketplace.type_sale'.tr(),
        MarketplaceListingType.adoption => 'marketplace.type_adoption'.tr(),
        MarketplaceListingType.trade => 'marketplace.type_trade'.tr(),
        MarketplaceListingType.wanted => 'marketplace.type_wanted'.tr(),
        MarketplaceListingType.unknown => '',
      };

  IconData _listingTypeIcon(MarketplaceListingType type) => switch (type) {
        MarketplaceListingType.sale => LucideIcons.tag,
        MarketplaceListingType.adoption => LucideIcons.heart,
        MarketplaceListingType.trade => LucideIcons.arrowLeftRight,
        MarketplaceListingType.wanted => LucideIcons.search,
        MarketplaceListingType.unknown => LucideIcons.helpCircle,
      };

  Color _listingTypeColor(MarketplaceListingType type) => switch (type) {
        MarketplaceListingType.sale => _ListingTypeColors.sale,
        MarketplaceListingType.adoption => _ListingTypeColors.adoption,
        MarketplaceListingType.trade => _ListingTypeColors.trade,
        MarketplaceListingType.wanted => _ListingTypeColors.wanted,
        MarketplaceListingType.unknown => _ListingTypeColors.unknown,
      };
}
