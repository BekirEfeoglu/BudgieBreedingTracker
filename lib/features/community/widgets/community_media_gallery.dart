import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
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

class _CommunityMediaGalleryState extends State<CommunityMediaGallery>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentIndex = 0;

  late final AnimationController _heartController;
  late final Animation<double> _heartScale;
  late final Animation<double> _heartOpacity;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartController);
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartController);
    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showHeart = false);
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    widget.onDoubleTap();
    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 320,
            child: GestureDetector(
              onDoubleTap: _handleDoubleTap,
              onTap: () =>
                  widget.onOpenImage(widget.imageUrls[_currentIndex]),
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
                        child:
                            Center(child: Icon(LucideIcons.image, size: 32)),
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
          // Page indicator
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: AppSpacing.md,
              child: Semantics(
                label: 'community.image_indicator'.tr(
                  args: [
                    '${_currentIndex + 1}',
                    '${widget.imageUrls.length}',
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
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
            ),
          // Heart animation overlay
          if (_showHeart)
            AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) => Opacity(
                opacity: _heartOpacity.value,
                child: Transform.scale(
                  scale: _heartScale.value,
                  child: child,
                ),
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.9),
                shadows: [
                  Shadow(
                    blurRadius: 24,
                    color: theme.shadowColor.withValues(alpha: 0.38),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
