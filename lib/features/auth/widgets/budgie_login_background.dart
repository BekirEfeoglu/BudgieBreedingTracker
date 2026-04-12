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
    with TickerProviderStateMixin {
  late final AnimationController _blob1Ctrl;
  late final AnimationController _blob2Ctrl;
  late final AnimationController _blob3Ctrl;

  @override
  void initState() {
    super.initState();
    _blob1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _blob2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _blob3Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blob1Ctrl.dispose();
    _blob2Ctrl.dispose();
    _blob3Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_blob1Ctrl, _blob2Ctrl, _blob3Ctrl]),
      builder: (context, _) {
        final b1y = sin(_blob1Ctrl.value * pi) * 15.0;
        final b2x = sin(_blob2Ctrl.value * pi) * 12.0;
        final b3y = sin(_blob3Ctrl.value * pi) * 10.0;

        return Stack(
          children: [
            // Sol ust yesil blob
            Positioned(
              top: -60 + b1y,
              left: -50,
              child: _blob(
                200,
                BudgieLoginPalette.blobGreen.withValues(alpha: 0.45),
              ),
            ),
            // Sag ust mavi blob
            Positioned(
              top: -30,
              right: -40 + b2x,
              child: _blob(
                160,
                BudgieLoginPalette.blobBlue.withValues(alpha: 0.35),
              ),
            ),
            // Alt ortada kucuk yesil blob
            Positioned(
              bottom: -40 + b3y,
              left: 60,
              child: _blob(
                120,
                BudgieLoginPalette.blobGreen.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
