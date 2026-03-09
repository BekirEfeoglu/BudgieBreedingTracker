import 'dart:math';

import 'package:flutter/material.dart';

import 'budgie_login_colors.dart';

/// 2D stilize muhabbet kusu karakteri.
///
/// Flutter Container widget'lari ile olusturulmus: vucut, karin, bas, goz,
/// gaga, yanak, kuyruk ve kanat. Animasyon degerleri disaridan alinir.
class BudgieCharacter extends StatelessWidget {
  final Color bodyColor;
  final Color cheekColor;

  /// Bas donme acisi (radyan). Pozitif = sola, negatif = saga.
  final double headRotation;

  /// Erkek kus sifre alaninda kanatla gozlerini kapatir.
  final bool isCoveringEyes;

  /// Hata durumunda uzgun ifade.
  final bool isSad;

  /// Goz kirpma animasyonu aktif mi.
  final bool isBlinking;

  /// true = sola bakar (sol kus), false = saga bakar (sag kus).
  final bool isLeft;

  /// Kanat cirpma animasyon degeri (0.0-1.0).
  final double wingFlapValue;

  /// Vucut sallanma animasyon degeri (0.0-1.0).
  final double bodyWobbleValue;

  const BudgieCharacter({
    super.key,
    required this.bodyColor,
    this.cheekColor = BudgieLoginPalette.maleCheck,
    this.headRotation = 0,
    this.isCoveringEyes = false,
    this.isSad = false,
    this.isBlinking = false,
    this.isLeft = true,
    this.wingFlapValue = 0,
    this.bodyWobbleValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bodyWobbleAngle = sin(bodyWobbleValue * 2 * pi) * 0.04;

    return Transform.rotate(
      angle: bodyWobbleAngle,
      child: SizedBox(
        width: 64,
        height: 85,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            _buildTail(),
            _buildBody(context),
            _buildBelly(context),
            _buildHead(context),
            _buildWing(),
          ],
        ),
      ),
    );
  }

  // -- Kuyruk --
  Widget _buildTail() {
    return Positioned(
      bottom: -4,
      left: isLeft ? 12 : null,
      right: !isLeft ? 12 : null,
      child: Transform.rotate(
        angle: isLeft ? -0.3 : 0.3,
        child: Container(
          width: 14,
          height: 28,
          decoration: BoxDecoration(
            color: bodyColor.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // -- Ana vucut --
  Widget _buildBody(BuildContext context) {
    return Container(
      width: 52,
      height: 62,
      decoration: BoxDecoration(
        color: bodyColor,
        borderRadius: BorderRadius.circular(26),
      ),
    );
  }

  // -- Karin beyaz oval --
  Widget _buildBelly(BuildContext context) {
    return Positioned(
      bottom: 6,
      child: Container(
        width: 36,
        height: 40,
        decoration: BoxDecoration(
          color: BudgieLoginPalette.bellyOverlay(context),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // -- Bas (animasyonlu) --
  Widget _buildHead(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      top: isSad ? 16 : 0,
      left: 9,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: headRotation),
        duration: const Duration(milliseconds: 300),
        builder: (context, val, child) {
          return Transform.rotate(angle: val, child: child);
        },
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            children: [
              // Bas dairesi
              Container(
                decoration: BoxDecoration(
                  color: bodyColor,
                  shape: BoxShape.circle,
                ),
              ),
              // Goz
              Positioned(
                top: 15,
                left: isLeft ? 25 : 12,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 8,
                  height: _eyeHeight,
                  decoration: BoxDecoration(
                    color: BudgieLoginPalette.eye,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Yanak lekesi
              Positioned(
                top: 23,
                left: isLeft ? 8 : 27,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cheekColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Gaga
              Positioned(
                top: 19,
                left: isLeft ? 32 : 3,
                child: Container(
                  width: 12,
                  height: 10,
                  decoration: BoxDecoration(
                    color: BudgieLoginPalette.beak,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Bas cizgileri (muhabbet kusu deseni)
              ..._buildHeadStripes(),
            ],
          ),
        ),
      ),
    );
  }

  double get _eyeHeight {
    if (isBlinking) return 2;
    if (isSad) return 4;
    return 8;
  }

  List<Widget> _buildHeadStripes() {
    return [
      Positioned(
        top: 6,
        left: isLeft ? 14 : 18,
        child: Container(
          width: 14,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
      Positioned(
        top: 10,
        left: isLeft ? 12 : 20,
        child: Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    ];
  }

  // -- Kanat --
  Widget _buildWing() {
    // Kanat cirpma: idle'da hafif yukari-asagi
    final flapOffset = sin(wingFlapValue * 2 * pi) * 3;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: isCoveringEyes ? 4 : (32 + flapOffset),
      left: isLeft ? 22 : 5,
      child: AnimatedRotation(
        turns: isCoveringEyes ? (isLeft ? -0.08 : 0.08) : 0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 24,
          height: 34,
          decoration: BoxDecoration(
            color: bodyColor.withValues(alpha: 0.88),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
