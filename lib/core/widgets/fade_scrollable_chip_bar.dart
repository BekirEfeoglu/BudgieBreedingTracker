import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Horizontal scrollable chip list with a right-side gradient fade indicator.
///
/// Wraps [children] in a horizontally scrollable [ListView] and overlays a
/// transparent-to-background gradient on the right edge to signal that more
/// chips are available off-screen.
class FadeScrollableChipBar extends StatelessWidget {
  final List<Widget> children;

  /// Bar height. Defaults to [AppSpacing.touchTargetMd].
  final double? height;

  const FadeScrollableChipBar({
    super.key,
    required this.children,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final barHeight = height ?? AppSpacing.touchTargetMd;

    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.xxxl,
            ),
            children: children,
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      bgColor.withValues(alpha: 0),
                      bgColor,
                    ],
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
