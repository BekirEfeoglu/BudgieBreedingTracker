import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'animations/shimmer_shine_animation.dart';

/// An animated linear progress bar with optional label and percentage.
/// Designed with a premium look, featuring a smooth width animation
/// and a continuous subtle shine effect over the filled portion.
class AppProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? backgroundColor;
  final String? label;
  final bool showPercentage;
  final double height;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.label,
    this.showPercentage = false,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final clampedValue = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '${(clampedValue * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: effectiveColor,
                    ),
                  ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            // Sıfır veya tanımsız durumlarda hatayı önlemek için fallback:
            final safeMaxWidth = maxWidth.isFinite ? maxWidth : 200.0;

            return Container(
              height: height,
              width: safeMaxWidth,
              decoration: BoxDecoration(
                color:
                    backgroundColor ?? effectiveColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Stack(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: clampedValue),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.fastOutSlowIn,
                    builder: (context, animatedValue, child) {
                      return Container(
                        width: safeMaxWidth * animatedValue,
                        height: height,
                        decoration: BoxDecoration(
                          color: effectiveColor,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: effectiveColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        // Dolu kısmın üzerinde sürekli akan hafif parıltı (Premium hissi)
                        child: clampedValue > 0.05
                            ? ShimmerShineAnimation(
                                duration: const Duration(milliseconds: 3000),
                                shineColor: Colors.white.withValues(
                                  alpha: 0.25,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm,
                                    ),
                                    color: Colors.transparent,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
