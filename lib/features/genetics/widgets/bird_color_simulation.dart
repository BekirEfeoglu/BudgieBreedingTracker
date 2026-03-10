import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';

/// Predicts budgie colors based on mutations and renders a stylized premium simulation.
class BirdColorSimulation extends StatelessWidget {
  final List<String> visualMutations;
  final String phenotype;
  final double size;

  const BirdColorSimulation({
    super.key,
    required this.visualMutations,
    required this.phenotype,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors
    final colors = _resolveColors();

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
          colors: [colors.bodyColor, _lighten(colors.bodyColor, 0.15)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Mask/Face color (Top area)
          Positioned(
            top: -size * 0.1,
            left: -size * 0.1,
            right: -size * 0.1,
            height: size * 0.6,
            child: Container(
              decoration: BoxDecoration(
                color: colors.maskColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(size),
                  bottomRight: Radius.circular(size),
                ),
              ),
            ),
          ),

          // Wing markings (Right side arc)
          Positioned(
            bottom: size * 0.1,
            right: -size * 0.2,
            width: size * 0.6,
            height: size * 0.7,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.wingColor.withValues(alpha: 0.6),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(size),
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

  Color _lighten(Color c, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(c);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  _BirdColors _resolveColors() {
    final lowerPheno = phenotype.toLowerCase();

    // Default: Green series
    Color body = AppColors.budgieGreen;
    Color mask = AppColors.birdYellow;
    Color wing = AppColors.neutral900;

    final isBlueSeries =
        visualMutations.contains('blue') ||
        visualMutations.contains('aqua') ||
        visualMutations.contains('turquoise') ||
        visualMutations.contains('bluefactor_1') ||
        visualMutations.contains('bluefactor_2') ||
        lowerPheno.contains('blue');

    // 1. Base Series
    if (isBlueSeries) {
      body = AppColors.budgieBlue;
      mask = AppColors.birdWhite;
    }

    // 2. Yellowface on Blue series
    if (isBlueSeries) {
      if (visualMutations.contains('goldenface') ||
          lowerPheno.contains('goldenface')) {
        mask = AppColors
            .birdYellow; // Deeper yellow usually, but standard yellow is fine
        body = _mixColor(body, AppColors.birdYellow, 0.4); // Bleeds into body
      } else if (visualMutations.contains('yellowface_type2') ||
          lowerPheno.contains('yellowface type ii')) {
        mask = AppColors.birdYellow;
        body = _mixColor(body, AppColors.birdYellow, 0.2); // Mild bleed
      } else if (visualMutations.contains('yellowface_type1') ||
          lowerPheno.contains('yellowface type i')) {
        mask = AppColors
            .birdYellow; // DF might be whiteface, but simple simulation
      }
      if (lowerPheno.contains('whitefaced')) {
        mask = AppColors.birdWhite;
      }
    }

    // 3. Dark Factors & Violet & Grey
    if (visualMutations.contains('dark_factor') ||
        lowerPheno.contains('dark') ||
        lowerPheno.contains('cobalt')) {
      body = _mixColor(body, Colors.black, 0.25);
    }
    if (lowerPheno.contains('olive') || lowerPheno.contains('mauve')) {
      body = _mixColor(body, Colors.black, 0.45);
    }
    if (visualMutations.contains('violet') || lowerPheno.contains('violet')) {
      body = AppColors.birdViolet;
    }
    if (visualMutations.contains('grey') || lowerPheno.contains('grey')) {
      body = AppColors.birdGrey;
    }
    if (visualMutations.contains('slate') || lowerPheno.contains('slate')) {
      body = AppColors.phenotypeSlate;
    }

    // 4. Ino (Albino/Lutino/Creamino)
    if (visualMutations.contains('ino') ||
        lowerPheno.contains('albino') ||
        lowerPheno.contains('lutino') ||
        lowerPheno.contains('creamino')) {
      wing = Colors.transparent;
      if (lowerPheno.contains('albino')) {
        body = AppColors.birdWhite;
        mask = AppColors.birdWhite;
      } else if (lowerPheno.contains('lutino')) {
        body = AppColors.birdYellow;
        mask = AppColors.birdYellow;
      } else if (lowerPheno.contains('creamino')) {
        body = AppColors.birdYellow;
        mask = AppColors.birdYellow;
      }
    }

    // 5. Lacewing / Pallid
    if (lowerPheno.contains('lacewing') || lowerPheno.contains('pallid')) {
      wing = AppColors.birdCinnamon; // Light brown wings
      if (lowerPheno.contains('lacewing')) {
        if (isBlueSeries && !lowerPheno.contains('yellowface')) {
          body = AppColors.birdWhite;
          mask = AppColors.birdWhite;
        } else {
          body = AppColors.birdYellow;
          mask = AppColors.birdYellow;
        }
      }
    }

    // 6. Cinnamon
    if (visualMutations.contains('cinnamon') ||
        lowerPheno.contains('cinnamon')) {
      wing = AppColors.birdCinnamon; // Brown wings instead of black
    }

    // 7. Spangle
    if (visualMutations.contains('spangle') || lowerPheno.contains('spangle')) {
      wing = body; // Wing edges body color
      if (lowerPheno.contains('double factor spangle') ||
          lowerPheno.contains('df spangle')) {
        // DF Spangle is pure yellow or pure white depending on base
        body = isBlueSeries ? AppColors.birdWhite : AppColors.birdYellow;
        mask = body;
        wing = Colors.transparent;
      }
    }

    // 8. Dilutions (Greywing, Clearwing, Dilute)
    if (visualMutations.contains('greywing') ||
        lowerPheno.contains('greywing')) {
      body = _lighten(body, 0.2);
      wing = AppColors.birdGrey;
    }
    if (visualMutations.contains('clearwing') ||
        lowerPheno.contains('clearwing')) {
      body = _lighten(body, 0.1);
      wing = AppColors.birdWhite;
    }
    if (visualMutations.contains('dilute') || lowerPheno.contains('dilute')) {
      body = _lighten(body, 0.4);
      wing = AppColors.birdGrey.withValues(alpha: 0.3);
    }

    // 9. Blackface
    if (visualMutations.contains('blackface') ||
        lowerPheno.contains('blackface')) {
      mask = AppColors.neutral900;
    }

    // 10. Pied
    if (lowerPheno.contains('pied') || lowerPheno.contains('clearflight')) {
      body = _mixColor(
        body,
        mask,
        0.3,
      ); // Mix body with base mask color for pied splotches
    }
    if (lowerPheno.contains('dark-eyed clear')) {
      body = isBlueSeries ? AppColors.birdWhite : AppColors.birdYellow;
      mask = body;
      wing = Colors.transparent;
    }

    return _BirdColors(bodyColor: body, maskColor: mask, wingColor: wing);
  }

  Color _mixColor(Color c1, Color c2, double amount) {
    return Color.lerp(c1, c2, amount) ?? c1;
  }
}

class _BirdColors {
  final Color bodyColor;
  final Color maskColor;
  final Color wingColor;

  _BirdColors({
    required this.bodyColor,
    required this.maskColor,
    required this.wingColor,
  });
}
