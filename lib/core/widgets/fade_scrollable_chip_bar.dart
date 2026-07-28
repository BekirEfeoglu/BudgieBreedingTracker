import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_spacing.dart';

/// Horizontal scrollable chip list with a directional overflow indicator.
///
/// Wraps [children] in a horizontally scrollable [ListView] and overlays a
/// gradient and chevron on the trailing edge only while more chips are
/// available off-screen.
class FadeScrollableChipBar extends StatefulWidget {
  final List<Widget> children;

  /// Bar height. Defaults to [AppSpacing.touchTargetMd].
  final double? height;

  const FadeScrollableChipBar({super.key, required this.children, this.height});

  @override
  State<FadeScrollableChipBar> createState() => _FadeScrollableChipBarState();
}

class _FadeScrollableChipBarState extends State<FadeScrollableChipBar> {
  final _scrollController = ScrollController();
  bool _showEndCue = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateEndCue);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateEndCue());
  }

  @override
  void didUpdateWidget(covariant FadeScrollableChipBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateEndCue());
  }

  void _updateEndCue() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final shouldShow =
        position.maxScrollExtent > 0 &&
        position.pixels < position.maxScrollExtent - 1;
    if (shouldShow != _showEndCue) {
      setState(() => _showEndCue = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateEndCue)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final barHeight = widget.height ?? AppSpacing.touchTargetMd;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          ListView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              end: AppSpacing.xxxl,
            ),
            children: widget.children,
          ),
          if (_showEndCue)
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 52,
                  alignment: AlignmentDirectional.centerEnd,
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [bgColor.withValues(alpha: 0), bgColor],
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: Transform.flip(
                      flipX: isRtl,
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
