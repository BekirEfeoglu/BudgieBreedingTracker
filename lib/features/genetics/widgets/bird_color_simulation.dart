import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

/// Predicts budgie colors based on mutations and renders a stylized premium simulation.
class BirdColorSimulation extends StatelessWidget {
  final List<String> visualMutations;
  final List<String> carriedMutations;
  final String phenotype;
  final double size;

  const BirdColorSimulation({
    super.key,
    required this.visualMutations,
    this.carriedMutations = const [],
    required this.phenotype,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    final appearance = BudgieColorResolver.resolve(
      visualMutations: visualMutations,
      carriedMutations: carriedMutations,
      phenotype: phenotype,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Drop shadow for a premium feel
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // Gradient base (Body Color)
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [appearance.bodyColor, _lighten(appearance.bodyColor, 0.15)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (appearance.showCarrierAccent)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: appearance.carrierAccentColor.withValues(
                      alpha: 0.95,
                    ),
                    width: size * 0.055,
                  ),
                ),
              ),
            ),

          // Mask/Face color (Top area)
          Positioned(
            top: -size * 0.1,
            left: -size * 0.1,
            right: -size * 0.1,
            height: size * 0.6,
            child: Container(
              decoration: BoxDecoration(
                color: appearance.maskColor.withValues(alpha: 0.88),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(size),
                  bottomRight: Radius.circular(size),
                ),
              ),
            ),
          ),

          if (appearance.showMantleHighlight)
            Positioned(
              top: size * 0.18,
              left: size * 0.12,
              right: size * 0.26,
              height: size * 0.26,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _lighten(
                    appearance.bodyColor,
                    0.08,
                  ).withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),

          if (appearance.showPiedPatch)
            Positioned(
              bottom: size * 0.16,
              left: size * 0.08,
              width: size * 0.28,
              height: size * 0.24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: appearance.piedPatchColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),

          if (appearance.wingFillColor.alpha > 0)
            Positioned(
              bottom: size * 0.1,
              right: -size * 0.15,
              width: size * 0.58,
              height: size * 0.68,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: appearance.wingFillColor,
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),

          // Wing markings (Right side arc)
          if (!appearance.hideWingMarkings)
            Positioned(
              bottom: size * 0.1,
              right: -size * 0.2,
              width: size * 0.6,
              height: size * 0.7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: appearance.wingMarkingColor.withValues(alpha: 0.72),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),

          if (appearance.showCheekPatch)
            Positioned(
              top: size * 0.34,
              right: size * 0.08,
              width: size * 0.18,
              height: size * 0.18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: appearance.cheekPatchColor.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
              ),
            ),

          if (appearance.showCarrierAccent)
            Positioned(
              top: size * 0.08,
              left: size * 0.10,
              width: size * 0.16,
              height: size * 0.16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: appearance.carrierAccentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: appearance.carrierAccentColor.withValues(
                        alpha: 0.30,
                      ),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

          // Inner highlight for premium glassmorphism touch
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _lighten(Color c, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(c);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return hslLight.toColor();
}
