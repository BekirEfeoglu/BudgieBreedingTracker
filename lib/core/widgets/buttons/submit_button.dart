import 'package:flutter/material.dart';

/// Submit button that honors loading state and explicit enabled/disabled.
///
/// Passing `onPressed: null` disables the button. Use this instead of
/// unconditionally-enabled buttons — users should see "can't submit yet"
/// reflected in the button state, not discover it when they tap.
class SubmitButton extends StatefulWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading && mounted) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading && mounted) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading && mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(widget.label);

    Widget button;
    if (widget.icon != null && !widget.isLoading) {
      button = FilledButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        icon: widget.icon!,
        label: child,
      );
    } else {
      button = FilledButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        child: child,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.deferToChild,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: button,
      ),
    );
  }
}
