import 'dart:math';

import 'package:flutter/material.dart';

import 'budgie_login_colors.dart';

/// Login ekraninin yumusak pastel arka plan dekorlari.
///
/// Her blob farkli hizda sinüs dalgasi hareketi yapar — hafif nefes alan
/// bir arka plan efekti olusturur.
class BudgieLoginBackground extends StatefulWidget {
  const BudgieLoginBackground({super.key});

  @override
  State<BudgieLoginBackground> createState() => _BudgieLoginBackgroundState();
}

class _BudgieLoginBackgroundState extends State<BudgieLoginBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion == _reduceMotion &&
        (_motionController.isAnimating || reduceMotion)) {
      return;
    }
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _motionController
        ..stop()
        ..value = 0;
    } else {
      _motionController.repeat();
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PositionedDirectional(
          top: -60,
          start: -50,
          child: _animatedBlob(
            offsetForValue: (value) => Offset(0, sin(value * 2 * pi) * 15),
            size: 200,
            color: BudgieLoginPalette.blobGreen.withValues(alpha: 0.45),
          ),
        ),
        PositionedDirectional(
          top: -30,
          end: -40,
          child: _animatedBlob(
            offsetForValue: (value) =>
                Offset(sin((value + 0.2) * 2 * pi) * 12, 0),
            size: 160,
            color: BudgieLoginPalette.blobBlue.withValues(alpha: 0.35),
          ),
        ),
        PositionedDirectional(
          bottom: -40,
          start: 60,
          child: _animatedBlob(
            offsetForValue: (value) =>
                Offset(0, sin((value + 0.4) * 2 * pi) * 10),
            size: 120,
            color: BudgieLoginPalette.blobGreen.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _animatedBlob({
    required Offset Function(double value) offsetForValue,
    required double size,
    required Color color,
  }) {
    final blob = RepaintBoundary(child: _blob(size, color));
    if (_reduceMotion) return blob;
    return AnimatedBuilder(
      animation: _motionController,
      child: blob,
      builder: (context, child) => Transform.translate(
        offset: offsetForValue(_motionController.value),
        child: child,
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
