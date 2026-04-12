import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';

/// Shimmer animation duration shared across all skeleton variants.
const _shimmerDuration = Duration(milliseconds: 1500);

/// Skeleton loading placeholder for chart content.
///
/// Set [isPieChart] or [isLineChart] to show the appropriate skeleton shape.
class ChartLoading extends StatelessWidget {
  const ChartLoading({
    super.key,
    this.isPieChart = false,
    this.isLineChart = false,
  });

  final bool isPieChart;
  final bool isLineChart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: isPieChart
          ? const _PieChartSkeleton()
          : isLineChart
              ? const _LineChartSkeleton()
              : const _BarChartSkeleton(),
    );
  }
}

class _BarChartSkeleton extends StatelessWidget {
  const _BarChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: AppSpacing.xxl),
              for (var i = 0; i < 5; i++) ...[
                const SizedBox(width: AppSpacing.md),
                SkeletonLoader(
                  width: 28,
                  height: [80.0, 120.0, 60.0, 140.0, 90.0][i],
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonLoader(height: 12),
        ],
      ),
    );
  }
}

class _PieChartSkeleton extends StatelessWidget {
  const _PieChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Center(
          child: SkeletonLoader(
            width: 140,
            height: 140,
            borderRadius: AppSpacing.radiusFull,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.lg),
              const SkeletonLoader(width: 60, height: 12),
            ],
          ],
        ),
      ],
    );
  }
}

class _LineChartSkeleton extends StatelessWidget {
  const _LineChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: AppColors.skeletonBase(context),
              highlightColor: AppColors.skeletonHighlight(context),
              period: _shimmerDuration,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _LineSkeletonPainter(
                    color: AppColors.skeletonSurface(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonLoader(height: 12),
        ],
      ),
    );
  }
}

class _LineSkeletonPainter extends CustomPainter {
  _LineSkeletonPainter({required this.color});

  final Color color;

  static const _strokeWidth = 3.0;
  static const _dotRadius = 4.0;
  static const _dotPositions = [0.0, 0.25, 0.5, 0.75, 1.0];

  // Normalized bezier control points (x, y fractions of size).
  // Produces a gentle upward-trending wave pattern.
  static const _segments = [
    // startY, cp1x, cp1y, cp2x, cp2y, endX, endY
    [0.70, 0.15, 0.50, 0.25, 0.30, 0.35, 0.40],
    [0.40, 0.45, 0.50, 0.55, 0.20, 0.65, 0.25],
    [0.25, 0.75, 0.30, 0.85, 0.15, 1.00, 0.35],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final path = Path()..moveTo(0, h * _segments[0][0]);
    for (final seg in _segments) {
      path.cubicTo(
        w * seg[1], h * seg[2],
        w * seg[3], h * seg[4],
        w * seg[5], h * seg[6],
      );
    }

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final metrics = path.computeMetrics().first;
    for (final t in _dotPositions) {
      final pos = metrics.getTangentForOffset(metrics.length * t)?.position;
      if (pos != null) {
        canvas.drawCircle(pos, _dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineSkeletonPainter oldDelegate) =>
      color != oldDelegate.color;
}
