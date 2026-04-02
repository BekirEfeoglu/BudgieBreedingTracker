import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

part 'budgie_painter_paths.dart';
part 'budgie_painter_paths_extra.dart';
part 'budgie_painter_details.dart';
part 'budgie_painter_details_anatomy.dart';
part 'budgie_painter_effects.dart';

/// CustomPainter that renders a side-profile budgerigar silhouette.
///
/// Receives a [BudgieColorAppearance] and paints 14 anatomical zones
/// in back-to-front order so that overlapping layers look correct.
/// The budgie faces RIGHT with an approximate 3:4 aspect ratio (w:h).
class BudgiePainter extends CustomPainter {
  final BudgieColorAppearance appearance;
  final bool? isFemale;

  const BudgiePainter({required this.appearance, this.isFemale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final barWidth = (w * 0.018).clamp(1.0, 3.0);

    // 0. Drop shadow beneath bird
    _paintShadow(canvas, w, h);

    // 1. Tail feathers (gradient shading)
    _paintZoneShaded(
      canvas, BudgiePaths.tail(w, h), appearance.tailColor,
      Offset(w * 0.28, h * 0.76), w * 0.20,
    );

    // 1a. Tail stripes (only at larger sizes)
    if (h >= 56) {
      BudgieDetails.paintTailStripes(canvas, w, h, appearance.tailColor);
    }

    // 1b. Feet and perch (between tail and body)
    BudgieDetailsAnatomy.paintFeet(canvas, w, h);

    // 2. Body / belly (gradient shading for 3D roundness)
    _paintZoneShaded(
      canvas, BudgiePaths.belly(w, h), appearance.bodyColor,
      Offset(w * 0.50, h * 0.52), w * 0.32,
    );

    // 3. Back / mantle
    _paintZone(canvas, BudgiePaths.back(w, h), appearance.effectiveBackColor);

    // 3b. Mantle highlight (opaline V-zone body bleed)
    if (appearance.showMantleHighlight) {
      _paintZone(
        canvas,
        BudgiePaths.back(w, h),
        appearance.bodyColor.withValues(alpha: 0.55),
      );
    }

    // 4. Wing fill (only when not fully transparent)
    if (appearance.wingFillColor.a > 0) {
      _paintZone(canvas, BudgiePaths.wing(w, h), appearance.wingFillColor);
    }

    // 5. Wing bar markings
    if (!appearance.hideWingMarkings) {
      if (appearance.isSpangle) {
        BudgieDetails.paintSpangleScallops(
          canvas, w, h, appearance.wingMarkingColor, barWidth,
        );
      } else {
        BudgieDetails.paintWingBars(
          canvas, w, h, appearance.wingMarkingColor, barWidth,
        );
      }
    }

    // 5a. Wing feather texture (subtle layering between bars)
    if (h >= 56) {
      canvas.save();
      canvas.clipPath(BudgiePaths.wing(w, h));
      BudgieDetails.paintWingFeatherTexture(
        canvas, w, h, appearance.bodyColor,
      );
      canvas.restore();
    }

    // 5b. Wing edge highlight for definition
    _paintWingEdge(canvas, w, h);

    // 6. Head (gradient shading)
    _paintZoneShaded(
      canvas, BudgiePaths.head(w, h), appearance.bodyColor,
      Offset(w * 0.64, h * 0.15), w * 0.18,
    );

    // 6a. Head highlight for roundness
    _paintHeadHighlight(canvas, w, h);

    // 6b. Head/nape stripes (before mask so mask covers front stripes)
    if (!appearance.hideWingMarkings) {
      final isOpaline = appearance.showMantleHighlight;
      final stripeCount = h < 56 ? 2 : (isOpaline ? 2 : 4);
      final stripeOpacity = isOpaline ? 0.30 : 0.55;
      BudgieDetails.paintHeadStripes(
        canvas, w, h, appearance.wingMarkingColor, barWidth,
        stripeCount: stripeCount, opacity: stripeOpacity,
      );
    }

    // 7. Mask / face (gradient shading)
    _paintZoneShaded(
      canvas, BudgiePaths.mask(w, h), appearance.maskColor,
      Offset(w * 0.68, h * 0.18), w * 0.14,
    );

    // 7b. Cere (fleshy nose area above beak)
    final isInoLike = appearance.eyeColor.r > 0.6 && appearance.eyeColor.g < 0.3;
    BudgieDetailsAnatomy.paintCere(
      canvas, w, h,
      isFemale: isFemale,
      isIno: isInoLike,
    );

    // 8. Beak
    _paintZone(canvas, BudgiePaths.beak(w, h), appearance.beakColor);

    // 9. Eye + ring
    BudgieDetailsAnatomy.paintEye(
      canvas, w, h,
      appearance.eyeColor, appearance.eyeRingColor, appearance.showEyeRing,
    );

    // 10. Cheek patch
    _paintZone(
      canvas, BudgiePathsExtra.cheekPatch(w, h), appearance.cheekPatchColor,
    );

    // 11. Throat spots
    if (appearance.showThroatSpots && appearance.throatSpotCount > 0) {
      BudgieDetailsAnatomy.paintThroatSpots(
        canvas, w, h, appearance.throatSpotColor, appearance.throatSpotCount,
      );
    }

    // 11b. Body feather texture (subtle breast feathering)
    if (h >= 56) {
      canvas.save();
      canvas.clipPath(BudgiePaths.belly(w, h));
      BudgieDetails.paintBodyFeatherTexture(
        canvas, w, h, appearance.bodyColor,
      );
      canvas.restore();
    }

    // 12. Pied patches (gradient shaded for visibility)
    if (appearance.showPiedPatch) {
      _paintZoneShaded(
        canvas, BudgiePathsExtra.piedPatch(w, h), appearance.piedPatchColor,
        Offset(w * 0.36, h * 0.66), w * 0.12,
      );
      // Dutch Pied: additional wing patch (characteristic large patches)
      if (appearance.isDutchPied) {
        _paintZoneShaded(
          canvas, BudgiePathsExtra.dutchPiedWingPatch(w, h),
          appearance.piedPatchColor,
          Offset(w * 0.56, h * 0.56), w * 0.10,
        );
      }
      // Dominant Pied: scattered smaller patches on body and wing
      if (appearance.isDominantPied && !appearance.isDutchPied) {
        _paintDominantPiedPatches(canvas, w, h);
      }
    }

    // 12b. Belly highlight for 3D roundness
    _paintBellyHighlight(canvas, w, h);

    // 12c. Wing under-shadow for depth separation from body
    _paintWingUnderShadow(canvas, w, h);

    // 13. Carrier accent dot
    if (appearance.showCarrierAccent) {
      _paintCarrierAccent(canvas, w, h);
    }

    // 14. Silhouette outline for visual definition
    _paintOutline(canvas, w, h);
  }

  void _paintZone(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path, Paint()..color = color);
  }

  /// Paints a zone with adaptive 4-stop radial gradient for 3D depth.
  ///
  /// Darker colors receive more highlight to remain visible;
  /// lighter colors receive less to avoid washing out.
  /// The 4-stop gradient adds a specular highlight and smoother shadow
  /// falloff for a more realistic rounded appearance.
  void _paintZoneShaded(
    Canvas canvas, Path path, Color color,
    Offset lightCenter, double radius,
  ) {
    final lightness = HSLColor.fromColor(color).lightness;
    final highlightAmt = 0.18 + (1.0 - lightness) * 0.14;
    final specularAmt = 0.06 + (1.0 - lightness) * 0.06;
    final shadowAmt = 0.10 + lightness * 0.14;

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        lightCenter,
        radius,
        [
          Color.lerp(color, Colors.white, highlightAmt)!,
          Color.lerp(color, Colors.white, specularAmt)!,
          color,
          Color.lerp(color, Colors.black, shadowAmt)!,
        ],
        [0.0, 0.25, 0.55, 1.0],
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BudgiePainter oldDelegate) =>
      appearance != oldDelegate.appearance ||
      isFemale != oldDelegate.isFemale;
}
