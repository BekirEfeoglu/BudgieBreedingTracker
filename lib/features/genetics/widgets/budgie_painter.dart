import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

part 'budgie_painter_paths.dart';
part 'budgie_painter_details.dart';

/// CustomPainter that renders a side-profile budgerigar silhouette.
///
/// Receives a [BudgieColorAppearance] and paints 14 anatomical zones
/// in back-to-front order so that overlapping layers look correct.
/// The budgie faces RIGHT with an approximate 3:4 aspect ratio (w:h).
class BudgiePainter extends CustomPainter {
  final BudgieColorAppearance appearance;

  const BudgiePainter({required this.appearance});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Tail feathers
    _paintZone(canvas, BudgiePaths.tail(w, h), appearance.tailColor);

    // 2. Body / belly
    _paintZone(canvas, BudgiePaths.belly(w, h), appearance.bodyColor);

    // 3. Back / mantle
    _paintZone(canvas, BudgiePaths.back(w, h), appearance.effectiveBackColor);

    // 14. Mantle highlight (subtle overlay on back)
    if (appearance.showMantleHighlight) {
      _paintZone(
        canvas,
        BudgiePaths.back(w, h),
        appearance.bodyColor.withValues(alpha: 0.25),
      );
    }

    // 4. Wing fill (only when not fully transparent)
    if (appearance.wingFillColor.a > 0) {
      _paintZone(canvas, BudgiePaths.wing(w, h), appearance.wingFillColor);
    }

    // 5. Wing bar markings
    if (!appearance.hideWingMarkings) {
      BudgieDetails.paintWingBars(
        canvas,
        w,
        h,
        appearance.wingMarkingColor,
        (w * 0.018).clamp(1.0, 3.0),
      );
    }

    // 6. Head
    _paintZone(canvas, BudgiePaths.head(w, h), appearance.bodyColor);

    // 7. Mask / face
    _paintZone(canvas, BudgiePaths.mask(w, h), appearance.maskColor);

    // 8. Beak
    _paintZone(canvas, BudgiePaths.beak(w, h), appearance.beakColor);

    // 9. Eye + ring
    BudgieDetails.paintEye(
      canvas,
      w,
      h,
      appearance.eyeColor,
      appearance.eyeRingColor,
      appearance.showEyeRing,
    );

    // 10. Cheek patch
    _paintZone(
      canvas,
      BudgiePaths.cheekPatch(w, h),
      appearance.cheekPatchColor,
    );

    // 11. Throat spots
    if (appearance.showThroatSpots && appearance.throatSpotCount > 0) {
      BudgieDetails.paintThroatSpots(
        canvas,
        w,
        h,
        appearance.throatSpotColor,
        appearance.throatSpotCount,
      );
    }

    // 12. Pied patches
    if (appearance.showPiedPatch) {
      _paintZone(
        canvas,
        BudgiePaths.piedPatch(w, h),
        appearance.piedPatchColor,
      );
    }

    // 13. Carrier accent dot
    if (appearance.showCarrierAccent) {
      _paintCarrierAccent(canvas, w, h);
    }
  }

  void _paintZone(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintCarrierAccent(Canvas canvas, double w, double h) {
    final cx = w * 0.30;
    final cy = h * 0.42;
    final radius = w * 0.045;
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()..color = appearance.carrierAccentColor,
    );
  }

  @override
  bool shouldRepaint(BudgiePainter oldDelegate) =>
      appearance != oldDelegate.appearance;
}
