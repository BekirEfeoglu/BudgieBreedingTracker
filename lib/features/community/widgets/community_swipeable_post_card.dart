import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/community_post_model.dart';
import '../providers/community_post_providers.dart';
import 'community_post_card.dart';

/// Wraps a [CommunityPostCard] with [AutomaticKeepAliveClientMixin] and
/// swipe-to-like (right) / swipe-to-bookmark (left) gesture support.
class SwipeablePostCard extends ConsumerStatefulWidget {
  final CommunityPost post;

  const SwipeablePostCard({super.key, required this.post});

  @override
  ConsumerState<SwipeablePostCard> createState() => _SwipeablePostCardState();
}

class _SwipeablePostCardState extends ConsumerState<SwipeablePostCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  static const _swipeThreshold = 80.0;

  late final AnimationController _slideController;
  double _dragExtent = 0;
  bool _actionTriggered = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      // Clamp to prevent over-dragging
      _dragExtent = _dragExtent.clamp(-120.0, 120.0);
    });

    if (!_actionTriggered && _dragExtent.abs() >= _swipeThreshold) {
      _actionTriggered = true;
      AppHaptics.mediumImpact();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() >= _swipeThreshold) {
      if (_dragExtent > 0) {
        // Swipe right → like
        ref.read(likeToggleProvider.notifier).toggleLike(widget.post.id);
      } else {
        // Swipe left → bookmark
        ref
            .read(bookmarkToggleProvider.notifier)
            .toggleBookmark(widget.post.id);
      }
    }
    setState(() {
      _dragExtent = 0;
      _actionTriggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isRight = _dragExtent > 0;
    final progress = (_dragExtent.abs() / _swipeThreshold).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: Stack(
        children: [
          // Background hint
          if (_dragExtent != 0)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: (isRight
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.tertiaryContainer)
                      .withValues(alpha: progress * 0.8),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                alignment:
                    isRight ? Alignment.centerLeft : Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Opacity(
                  opacity: progress,
                  child: AnimatedScale(
                    scale: _actionTriggered ? 1.3 : progress,
                    duration: Duration(
                      milliseconds: _actionTriggered ? 200 : 0,
                    ),
                    curve: Curves.elasticOut,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRight ? LucideIcons.heart : LucideIcons.bookmark,
                          color: isRight
                              ? theme.colorScheme.primary
                              : theme.colorScheme.tertiary,
                          size: 28,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isRight
                              ? 'community.like'.tr()
                              : 'community.bookmark'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isRight
                                ? theme.colorScheme.primary
                                : theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Card with drag offset
          GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: AnimatedContainer(
              duration: _dragExtent == 0
                  ? const Duration(milliseconds: 250)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_dragExtent, 0, 0),
              child: CommunityPostCard(post: widget.post),
            ),
          ),
        ],
      ),
    );
  }
}
