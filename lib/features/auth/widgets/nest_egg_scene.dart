import 'dart:math';

import 'package:flutter/material.dart';

import '../screens/budgie_login_screen.dart' show LoginState;
import 'budgie_login_colors.dart';

/// Yuva, yumurta ve yavru kus sahnesi.
///
/// Idle durumda yumurta hafifce sallanir, periyodik olarak yavru peek yapar.
/// Basarili giriste yumurta kirilir ve yavru tamamen cikar.
class NestEggScene extends StatelessWidget {
  final LoginState state;
  final bool isPeeking;
  final Animation<double> eggWobble;

  const NestEggScene({
    super.key,
    required this.state,
    required this.isPeeking,
    required this.eggWobble,
  });

  bool get _isSuccess => state == LoginState.success;
  bool get _showBaby => isPeeking || _isSuccess;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 90,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          _buildBabyBird(),
          _buildBrokenEggTop(),
          _buildEgg(),
          _buildNest(),
        ],
      ),
    );
  }

  // -- Yavru kus (peek / hatch) --
  Widget _buildBabyBird() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      bottom: _showBaby ? 42 : 12,
      left: 50,
      child: AnimatedOpacity(
        opacity: _showBaby ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            children: [
              // Bas
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: BudgieLoginPalette.babyBudgie,
                  shape: BoxShape.circle,
                ),
              ),
              // Sol goz
              Positioned(
                top: 9,
                left: 6,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: BudgieLoginPalette.eye,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Sag goz
              Positioned(
                top: 9,
                right: 6,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: BudgieLoginPalette.eye,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Gaga
              Positioned(
                top: 15,
                left: 11,
                child: Container(
                  width: 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: BudgieLoginPalette.beak,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Basindaki tuy
              Positioned(
                top: -4,
                left: 13,
                child: Container(
                  width: 4,
                  height: 8,
                  decoration: BoxDecoration(
                    color: BudgieLoginPalette.babyBudgie.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Kirilan yumurta ustu (success) --
  Widget _buildBrokenEggTop() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      bottom: _isSuccess ? 68 : 25,
      left: 46,
      child: AnimatedOpacity(
        opacity: _isSuccess ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        child: Transform.rotate(
          angle: 0.4,
          child: CustomPaint(
            size: const Size(32, 18),
            painter: _BrokenEggTopPainter(),
          ),
        ),
      ),
    );
  }

  // -- Yumurta --
  Widget _buildEgg() {
    return Positioned(
      bottom: 20,
      left: 45,
      child: AnimatedBuilder(
        animation: eggWobble,
        builder: (context, child) {
          double angle = 0;
          if (state == LoginState.idle || state == LoginState.loading) {
            angle = sin(eggWobble.value * pi * 4) * 0.08;
            if (state == LoginState.loading) {
              angle *= 2.5;
            }
          }
          return Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 40,
          height: _isSuccess ? 22 : 48,
          decoration: BoxDecoration(
            color: BudgieLoginPalette.eggShell,
            borderRadius: _isSuccess
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  )
                : BorderRadius.circular(20),
            boxShadow: _isSuccess
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(1, 2),
                    ),
                  ],
          ),
          child: !_isSuccess ? _buildEggSpots() : null,
        ),
      ),
    );
  }

  Widget _buildEggSpots() {
    return Stack(
      children: [
        Positioned(top: 10, left: 10, child: _eggSpot(5)),
        Positioned(top: 22, left: 20, child: _eggSpot(6)),
        Positioned(top: 14, left: 26, child: _eggSpot(4)),
      ],
    );
  }

  Widget _eggSpot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: BudgieLoginPalette.eggSpot,
        shape: BoxShape.circle,
      ),
    );
  }

  // -- Yuva (en on katman) --
  Widget _buildNest() {
    return Container(
      width: 110,
      height: 42,
      decoration: const BoxDecoration(
        color: BudgieLoginPalette.nestStraw,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(55),
          bottomRight: Radius.circular(55),
        ),
      ),
      child: CustomPaint(painter: _NestTexturePainter()),
    );
  }
}

/// Kirilan yumurta kabugunun ust kismi (zigzag kenar).
class _BrokenEggTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = BudgieLoginPalette.eggShell;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.4)
      ..lineTo(size.width * 0.15, size.height * 0.1)
      ..lineTo(size.width * 0.3, size.height * 0.35)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width * 0.85, size.height * 0.05)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Yuva doku cizgileri (saman etkisi).
class _NestTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BudgieLoginPalette.nestLine
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final random = Random(42);
    for (int i = 0; i < 18; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + (random.nextDouble() * 18 - 9);
      final endY = startY + (random.nextDouble() * 8 - 4);

      if (endX > 0 && endX < size.width && endY > 0 && endY < size.height) {
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
