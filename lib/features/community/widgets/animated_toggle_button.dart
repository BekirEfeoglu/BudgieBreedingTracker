import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable animated toggle button with scale bounce animation.
///
/// Plays a 1.0 → 1.3 → 1.0 scale animation whenever [isActive] changes.
/// Optionally renders a [label] with an AnimatedSwitcher slide-fade transition.
class AnimatedToggleButton extends StatefulWidget {
  const AnimatedToggleButton({
    super.key,
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onToggle,
    this.label,
    this.labelStyle,
    this.semanticLabel,
  });

  final bool isActive;
  final Widget activeIcon;
  final Widget inactiveIcon;
  final VoidCallback onToggle;
  final String? label;
  final TextStyle? labelStyle;
  final String? semanticLabel;

  @override
  State<AnimatedToggleButton> createState() => _AnimatedToggleButtonState();
}

class _AnimatedToggleButtonState extends State<AnimatedToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onToggle();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: widget.isActive ? widget.activeIcon : widget.inactiveIcon,
            ),
            if (widget.label != null) ...[
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  widget.label!,
                  key: ValueKey(widget.label),
                  style: widget.labelStyle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
