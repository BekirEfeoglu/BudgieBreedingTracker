import 'package:flutter/material.dart';

/// An animation that simulates an AI or barcode scanner line moving up and down
/// over the child widget. Great for indicating "Analyzing..." states on images.
class ScannerLineAnimation extends StatefulWidget {
  final Widget child;
  final bool isScanning;
  final Color? scannerColor;
  final Duration duration;

  const ScannerLineAnimation({
    super.key,
    required this.child,
    this.isScanning = true,
    this.scannerColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ScannerLineAnimation> createState() => _ScannerLineAnimationState();
}

class _ScannerLineAnimationState extends State<ScannerLineAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ScannerLineAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _controller.repeat(reverse: true);
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
    if (!widget.isScanning) return widget.child;
    
    final theme = Theme.of(context);
    final effectiveColor = widget.scannerColor ?? theme.colorScheme.primary;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Animating from top (0.0) to bottom (1.0)
              final alignment = Alignment(0, (_controller.value * 2) - 1);
              
              return Align(
                alignment: alignment,
                child: Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    boxShadow: [
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
