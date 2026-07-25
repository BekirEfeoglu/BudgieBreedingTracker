import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

class DoubleTapLikeAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLike;
  final Widget likeIcon;

  const DoubleTapLikeAnimation({
    super.key,
    required this.child,
    this.onLike,
    // "Like" is a domain concept, so the default must be the SVG AppIcon, not
    // LucideIcons (anti-pattern #24). Every other like/heart render in the app
    // already uses AppIcons.like; this default is what a new call site
    // inherits when it does not pass likeIcon.
    this.likeIcon = const AppIcon(
      AppIcons.like,
      color: Colors.white,
      size: 100,
    ),
  });

  @override
  State<DoubleTapLikeAnimation> createState() => _DoubleTapLikeAnimationState();
}

class _DoubleTapLikeAnimationState extends State<DoubleTapLikeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isAnimating = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _controller.stop();
      _isAnimating = false;
    }
  }

  void _handleDoubleTap() {
    HapticFeedback.lightImpact();
    widget.onLike?.call();

    if (_reduceMotion) {
      if (_isAnimating) {
        setState(() => _isAnimating = false);
      }
      return;
    }

    setState(() {
      _isAnimating = true;
    });

    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_isAnimating)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: widget.likeIcon,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
