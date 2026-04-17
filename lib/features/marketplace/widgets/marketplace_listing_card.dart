import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/marketplace_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/marketplace_listing_model.dart';
import '../../../router/route_names.dart';

// Image overlay UI colors (image overlay context, not theme-dependent)
abstract final class _ImageOverlayColors {
  static const overlayBackground = Color(0x8A000000); // black54 equivalent
  static const overlayIcon = Color(0xFFFFFFFF); // white
  static const favoriteActive = Color(0xFFE53935); // red for active favorite
  static const freeLabel = Color(0xFF4CAF50); // green for free/adoption
}

class MarketplaceListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final VoidCallback? onFavoriteToggle;

  const MarketplaceListingCard({
    super.key,
    required this.listing,
    this.onFavoriteToggle,
  });

  String _relativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return 'marketplace.time_ago_minutes'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'marketplace.time_ago_hours'.tr(args: ['${diff.inHours}']);
    }
    return 'marketplace.time_ago_days'.tr(args: ['${diff.inDays}']);
  }

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
            _buildImageArea(theme),
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
                      _buildPriceArea(theme),
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
                      if (listing.viewCount > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          LucideIcons.eye,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${listing.viewCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _relativeTime(listing.createdAt),
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

  Widget _buildImageArea(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (listing.primaryImageUrl != null)
            CachedNetworkImage(
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
            )
          else
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                LucideIcons.bird,
                size: 48,
                color: theme.colorScheme.outline,
              ),
            ),
          // Photo count badge (top-left)
          if (listing.imageUrls.length > 1)
            Positioned(
              top: AppSpacing.xs,
              left: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _ImageOverlayColors.overlayBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.camera,
                      size: 12,
                      color: _ImageOverlayColors.overlayIcon,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${listing.imageUrls.length}',
                      style: const TextStyle(
                        color: _ImageOverlayColors.overlayIcon,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Favorite heart icon (top-right)
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: GestureDetector(
              onTap: onFavoriteToggle,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: const BoxDecoration(
                  color: _ImageOverlayColors.overlayBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.heart,
                  size: 20,
                  color: listing.isFavoritedByMe
                      ? _ImageOverlayColors.favoriteActive
                      : _ImageOverlayColors.overlayIcon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceArea(ThemeData theme) {
    if (listing.listingType == MarketplaceListingType.adoption &&
        listing.price == null) {
      return Text(
        'marketplace.free_label'.tr(),
        style: theme.textTheme.titleMedium?.copyWith(
          color: _ImageOverlayColors.freeLabel,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    if (listing.price != null) {
      return Text(
        listing.priceDisplay,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return const SizedBox.shrink();
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
        MarketplaceListingType.sale => AppColors.listingSale,
        MarketplaceListingType.adoption => AppColors.listingAdoption,
        MarketplaceListingType.trade => AppColors.listingTrade,
        MarketplaceListingType.wanted => AppColors.listingWanted,
        MarketplaceListingType.unknown => AppColors.neutral400,
      };
}
