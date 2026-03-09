import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Circular progress ring around the avatar showing profile completion.
///
/// The arc color transitions from red (<33%) to amber (<66%) to green (>=66%).
class ProfileCompletionIndicator extends StatelessWidget {
  const ProfileCompletionIndicator({
    super.key,
    required this.completionFraction,
    required this.child,
    this.size = 120,
    this.strokeWidth = 4,
  });

  /// 0.0 to 1.0
  final double completionFraction;

  /// Widget to display in the center (typically AvatarWidget).
  final Widget child;

  /// Outer diameter of the ring.
  final double size;

  /// Width of the progress arc stroke.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '${(completionFraction * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: completionFraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutExpo,
            builder: (context, value, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Background track
                  CustomPaint(
                    size: Size(size, size),
                    painter: _ArcPainter(
                      progress: 1.0,
                      color: theme.colorScheme.surfaceContainerHighest,
                      strokeWidth: strokeWidth,
                    ),
                  ),
                  // Animated progress arc
                  CustomPaint(
                    size: Size(size, size),
                    painter: _ArcPainter(
                      progress: value,
                      color: _progressColor(value),
                      strokeWidth: strokeWidth,
                    ),
                  ),
                  // Centered child (avatar)
                  Padding(
                    padding: EdgeInsets.all(strokeWidth + AppSpacing.xs),
                    child: child,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Smoothly interpolates arc color as progress animates through thresholds.
  ///
  /// 0.00–0.33: error → warning blend
  /// 0.33–0.66: warning → success blend
  /// 0.66–1.00: success
  Color _progressColor(double value) {
    if (value < 0.33) {
      return Color.lerp(AppColors.error, AppColors.warning, value / 0.33)!;
    }
    if (value < 0.66) {
      return Color.lerp(
          AppColors.warning, AppColors.success, (value - 0.33) / 0.33)!;
    }
    return AppColors.success;
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
