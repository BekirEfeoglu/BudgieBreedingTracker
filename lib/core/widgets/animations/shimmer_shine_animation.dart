import 'package:flutter/material.dart';

/// Sweeps a shimmering shine effect across its child.
/// Great for highlighting premium cards or recommended options.
class ShimmerShineAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color? shineColor;
  final Duration duration;

  const ShimmerShineAnimation({
    super.key,
    required this.child,
    this.isActive = true,
    this.shineColor,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<ShimmerShineAnimation> createState() => _ShimmerShineAnimationState();
}

class _ShimmerShineAnimationState extends State<ShimmerShineAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ShimmerShineAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    final theme = Theme.of(context);
    final effectiveColor = widget.shineColor ?? theme.colorScheme.onPrimary.withValues(alpha: 0.3);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Animates from -1 to 2 to ensure the shine passes completely across
            final val = _controller.value * 3 - 1;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.transparent,
                effectiveColor,
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
              transform: _SlideGradientTransform(val),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double percent;
  const _SlideGradientTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}
