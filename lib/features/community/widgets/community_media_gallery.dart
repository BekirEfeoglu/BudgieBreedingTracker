import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';

/// Image carousel for community post media.
class CommunityMediaGallery extends StatefulWidget {
  final List<String> imageUrls;
  final VoidCallback onDoubleTap;
  final ValueChanged<String> onOpenImage;

  const CommunityMediaGallery({
    super.key,
    required this.imageUrls,
    required this.onDoubleTap,
    required this.onOpenImage,
  });

  @override
  State<CommunityMediaGallery> createState() => _CommunityMediaGalleryState();
}

class _CommunityMediaGalleryState extends State<CommunityMediaGallery> {
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 320,
          child: GestureDetector(
            onDoubleTap: widget.onDoubleTap,
            onTap: () => widget.onOpenImage(widget.imageUrls[_currentIndex]),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: widget.imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: 900,
                  memCacheHeight: 1200,
                  placeholder: (_, __) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: Center(child: Icon(LucideIcons.image, size: 32)),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(LucideIcons.imageOff, size: 32),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                  '${_currentIndex + 1}/${widget.imageUrls.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
