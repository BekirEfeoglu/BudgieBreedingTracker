import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animations/double_tap_like_animation.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/skeleton_loader.dart';

/// Collage grid for community post media.
///
/// Layout adapts to image count:
/// - 1 image: single full-width cell (~300 tall).
/// - 2 images: two equal side-by-side cells (~220 tall).
/// - 3+ images: big left cell (2fr) with a "1 / N" counter chip, plus a right
///   column (1fr) split into two stacked cells; when there are more than 3
///   images the bottom-right cell shows a "+{N-3}" overlay (~220 tall).
class CommunityMediaGallery extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback onDoubleTap;

  /// Called with the tapped cell's image index. The full-screen viewer opened
  /// from it is swipeable, so every image (even those past the 3-cell collage)
  /// stays reachable.
  final ValueChanged<int> onOpenImage;

  const CommunityMediaGallery({
    super.key,
    required this.imageUrls,
    required this.onDoubleTap,
    required this.onOpenImage,
  });

  static const double _gap = 4;
  static const double _singleHeight = 300;
  static const double _gridHeight = 220;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return RepaintBoundary(
      child: DoubleTapLikeAnimation(
        onLike: onDoubleTap,
        // Soft drop shadow behind the white heart for legibility over bright
        // photos. AppIcon (SVG) has no `shadows` param like Material's Icon,
        // so the shadow is a blurred, offset dark copy stacked behind it.
        likeIcon: Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AppIcon(
                AppIcons.heart,
                size: 80,
                color: theme.shadowColor.withValues(alpha: 0.38),
              ),
            ),
            AppIcon(
              AppIcons.heart,
              size: 80,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ],
        ),
        child: _buildCollage(context),
      ),
    );
  }

  Widget _buildCollage(BuildContext context) {
    final count = imageUrls.length;

    if (count == 1) {
      return SizedBox(
        height: _singleHeight,
        width: double.infinity,
        child: _cell(context, imageUrls[0], 0),
      );
    }

    if (count == 2) {
      return SizedBox(
        height: _gridHeight,
        child: Row(
          children: [
            Expanded(child: _cell(context, imageUrls[0], 0)),
            const SizedBox(width: _gap),
            Expanded(child: _cell(context, imageUrls[1], 1)),
          ],
        ),
      );
    }

    // 3+ images: big left cell + stacked right column.
    final remaining = count - 3;
    return SizedBox(
      height: _gridHeight,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _cell(
              context,
              imageUrls[0],
              0,
              counter: _counterChip(context, count),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _cell(context, imageUrls[1], 1)),
                const SizedBox(height: _gap),
                Expanded(
                  child: _cell(
                    context,
                    imageUrls[2],
                    2,
                    overlayMore: remaining > 0 ? remaining : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A single tappable image cell.
  ///
  /// [counter] pins a "1 / N" chip to the bottom-left. [overlayMore] paints a
  /// dark scrim with a centered "+X" for the "more images" affordance.
  Widget _cell(
    BuildContext context,
    String url,
    int index, {
    Widget? counter,
    int? overlayMore,
  }) {
    final theme = Theme.of(context);
    final imageCount = imageUrls.length;
    final semanticLabel = 'community.image_indicator'.tr(
      args: ['${index + 1}', '$imageCount'],
    );

    return Semantics(
      button: true,
      image: true,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => onOpenImage(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                memCacheWidth: 600,
                memCacheHeight: 800,
                maxWidthDiskCache: 600,
                maxHeightDiskCache: 800,
                placeholder: (_, __) => const SkeletonLoader(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 0,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(LucideIcons.imageOff, size: 32),
                ),
              ),
              if (overlayMore != null)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: Text(
                      '+$overlayMore',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (counter != null)
                PositionedDirectional(
                  start: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: counter,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The "1 / N" indicator chip shown on the primary cell.
  Widget _counterChip(BuildContext context, int count) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'community.image_indicator'.tr(args: ['1', '$count']),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            '1 / $count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
