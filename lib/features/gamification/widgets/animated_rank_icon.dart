import 'package:flutter/material.dart';
import '../../../core/widgets/app_icon.dart';

class AnimatedRankIcon extends StatefulWidget {
  final String iconAsset;
  final double size;
  final bool isAnimated;

  const AnimatedRankIcon({
    super.key,
    required this.iconAsset,
    this.size = 24,
    this.isAnimated = true,
  });

  @override
  State<AnimatedRankIcon> createState() => _AnimatedRankIconState();
}

class _AnimatedRankIconState extends State<AnimatedRankIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isAnimated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedRankIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.0;
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
    if (!widget.isAnimated) {
      return AppIcon(widget.iconAsset, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AppIcon(widget.iconAsset, size: widget.size),
        );
      },
    );
  }
}
