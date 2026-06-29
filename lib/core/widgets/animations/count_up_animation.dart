import 'package:flutter/material.dart';

class CountUpAnimation extends StatefulWidget {
  final double begin;
  final double end;
  final Duration duration;
  final int precision;
  final String? suffix;
  final TextStyle? style;

  const CountUpAnimation({
    super.key,
    this.begin = 0,
    required this.end,
    this.duration = const Duration(milliseconds: 1500),
    this.precision = 0,
    this.suffix,
    this.style,
  });

  @override
  State<CountUpAnimation> createState() => _CountUpAnimationState();
}

class _CountUpAnimationState extends State<CountUpAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _started = false;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: widget.begin, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Honour "reduce motion": jump straight to the final value with no running
    // controller. Tests enable this globally so golden captures are stable and
    // pumpAndSettle never depends on count-up timing.
    if (_reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant CountUpAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      _animation = Tween<double>(begin: _animation.value, end: widget.end).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      if (_reduceMotion) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0);
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value.toStringAsFixed(widget.precision);
        return Text(
          '$value${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}
