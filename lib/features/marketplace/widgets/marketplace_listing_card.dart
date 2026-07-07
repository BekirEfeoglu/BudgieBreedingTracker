import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/enums/marketplace_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/marketplace_listing_model.dart';
import '../../../router/route_names.dart';

// Image overlay UI colors. Centralized AppColors lookup so the card's
// semantic tokens (favorite/free) are documented once. The overlay
// background + icon stay local because they're "sits-on-photo" pixel
// colors, not theme tokens.
abstract final class _ImageOverlayColors {
  static const overlayBackground = Color(0x8A000000); // black54 equivalent
  static const overlayIcon = Color(0xFFFFFFFF); // white
  static const favoriteActive = AppColors.listingFavoriteActive;
}

class MarketplaceListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final VoidCallback? onFavoriteToggle;

  /// When true the card renders a compact, fixed-height layout suited to a
  /// 2-column grid (image with an on-photo type badge + favorite heart, then
  /// price/title/location). Defaults to the original full-width list layout so
  /// existing list-based screens are unaffected.
  final bool compact;

  const MarketplaceListingCard({
    super.key,
    required this.listing,
    this.onFavoriteToggle,
    this.compact = false,
  });

  /// Fixed image height for the compact grid card.
  static const double _compactImageHeight = 120;

  String _relativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    // listing.createdAt is UTC; normalize before diff so DST/TZ
    // boundary doesn't yield negative inDays/inHours.
    final localDate = dateTime.toLocal();
    final diff = DateTime.now().difference(localDate);
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
    if (compact) return _buildCompact(context, theme);

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
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpacing.xs,
                          ),
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
                        icon: _listingTypeIcon(listing.listingType, size: 14),
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

  /// Compact 2-column grid layout: fixed-height image with an on-photo type
  /// badge (top-left) + favorite heart (top-right), then price, title and a
  /// location line. Same tap-to-detail and favorite wiring as the list card.
  Widget _buildCompact(BuildContext context, ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.marketplace}/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageArea(theme, compact: true),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    listing.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 13,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          listing.city,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  /// On-photo filled type badge used by the compact grid card (top-left).
  Widget _buildCompactTypeBadge() {
    final color = _listingTypeColor(listing.listingType);
    final label = _listingTypeLabel(listing.listingType);
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _listingTypeIcon(
            listing.listingType,
            size: 12,
            color: _ImageOverlayColors.overlayIcon,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: const TextStyle(
              color: _ImageOverlayColors.overlayIcon,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea(ThemeData theme, {bool compact = false}) {
    final imageStack = Stack(
      fit: StackFit.expand,
      children: [
          Hero(
            tag: 'marketplace_image_${listing.id}',
            child: listing.primaryImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: listing.primaryImageUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 640,
                    placeholder: (_, __) =>
                        ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                    errorWidget: (_, _, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        LucideIcons.image,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: AppIcon(
                      AppIcons.bird,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                  ),
          ),
          // Top-left overlay. Compact grid cards pin the listing type badge
          // here (to match the marketplace design); the list card keeps the
          // multi-photo count indicator.
          if (compact)
            Positioned(
              top: AppSpacing.xs,
              left: AppSpacing.xs,
              child: _buildCompactTypeBadge(),
            )
          else if (listing.imageUrls.length > 1)
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
          // Favorite heart icon (top-right). Hidden when no callback is
          // wired — previously the heart was always rendered but no
          // caller wired the callback, leaving it as a dead UI
          // affordance. Screens that don't want the heart (e.g. the
          // user's own listings) now simply omit onFavoriteToggle.
          if (onFavoriteToggle != null)
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Semantics(
                button: true,
                label: listing.isFavoritedByMe
                    ? 'marketplace.unfavorite'.tr()
                    : 'marketplace.favorite'.tr(),
                child: GestureDetector(
                  onTap: onFavoriteToggle,
                  // 48dp tap target — the previous 28dp footprint was
                  // below the WCAG minimum so the gesture was hard to
                  // hit reliably.
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: const BoxDecoration(
                        color: _ImageOverlayColors.overlayBackground,
                        shape: BoxShape.circle,
                      ),
                      child: AppIcon(
                        AppIcons.heart,
                        size: 20,
                        color: listing.isFavoritedByMe
                            ? _ImageOverlayColors.favoriteActive
                            : _ImageOverlayColors.overlayIcon,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Bottom-right overlay: Glassmorphic Price Badge
          Positioned(
            bottom: AppSpacing.xs,
            right: AppSpacing.xs,
            child: _buildPriceBadge(theme),
          ),
      ],
    );

    if (compact) {
      return SizedBox(height: _compactImageHeight, child: imageStack);
    }
    return AspectRatio(aspectRatio: 16 / 9, child: imageStack);
  }

  Widget _buildPriceBadge(ThemeData theme) {
    final isFree = listing.listingType == MarketplaceListingType.adoption && listing.price == null;
    final text = isFree ? 'marketplace.free_label'.tr() : (listing.price != null ? listing.priceDisplay : '');
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
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

  Widget _listingTypeIcon(
    MarketplaceListingType type, {
    double? size,
    Color? color,
  }) => switch (type) {
    MarketplaceListingType.sale => Icon(
      LucideIcons.tag,
      size: size,
      color: color,
    ),
    MarketplaceListingType.adoption => AppIcon(
      AppIcons.heart,
      size: size,
      color: color,
    ),
    MarketplaceListingType.trade => Icon(
      LucideIcons.arrowLeftRight,
      size: size,
      color: color,
    ),
    MarketplaceListingType.wanted => Icon(
      LucideIcons.search,
      size: size,
      color: color,
    ),
    MarketplaceListingType.unknown => Icon(
      LucideIcons.helpCircle,
      size: size,
      color: color,
    ),
  };

  Color _listingTypeColor(MarketplaceListingType type) => switch (type) {
    MarketplaceListingType.sale => AppColors.listingSale,
    MarketplaceListingType.adoption => AppColors.listingAdoption,
    MarketplaceListingType.trade => AppColors.listingTrade,
    MarketplaceListingType.wanted => AppColors.listingWanted,
    MarketplaceListingType.unknown => AppColors.neutral400,
  };
}
