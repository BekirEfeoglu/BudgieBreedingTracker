import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

part 'budgie_painter_paths.dart';
part 'budgie_painter_details.dart';
part 'budgie_painter_details_anatomy.dart';

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
      canvas, BudgiePaths.cheekPatch(w, h), appearance.cheekPatchColor,
    );

    // 11. Throat spots
    if (appearance.showThroatSpots && appearance.throatSpotCount > 0) {
      BudgieDetailsAnatomy.paintThroatSpots(
        canvas, w, h, appearance.throatSpotColor, appearance.throatSpotCount,
      );
    }

    // 12. Pied patches
    if (appearance.showPiedPatch) {
      _paintZone(
        canvas, BudgiePaths.piedPatch(w, h), appearance.piedPatchColor,
      );
    }

    // 12b. Belly highlight for 3D roundness
    _paintBellyHighlight(canvas, w, h);

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

  /// Paints a zone with adaptive radial gradient for 3D depth.
  ///
  /// Darker colors receive more highlight to remain visible;
  /// lighter colors receive less to avoid washing out.
  void _paintZoneShaded(
    Canvas canvas, Path path, Color color,
    Offset lightCenter, double radius,
  ) {
    final lightness = HSLColor.fromColor(color).lightness;
    final highlightAmt = 0.15 + (1.0 - lightness) * 0.12;
    final shadowAmt = 0.08 + lightness * 0.12;

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        lightCenter,
        radius,
        [
          Color.lerp(color, Colors.white, highlightAmt)!,
          color,
          Color.lerp(color, Colors.black, shadowAmt)!,
        ],
        [0.0, 0.50, 1.0],
      );
    canvas.drawPath(path, paint);
  }

  void _paintShadow(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.42, h * 0.96),
        width: w * 0.32,
        height: h * 0.030,
      ),
      Paint()..color = const Color(0x20000000),
    );
  }

  void _paintBellyHighlight(Canvas canvas, double w, double h) {
    canvas.save();
    canvas.clipPath(BudgiePaths.belly(w, h));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.54),
        width: w * 0.22,
        height: h * 0.16,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.restore();
  }

  void _paintHeadHighlight(Canvas canvas, double w, double h) {
    canvas.save();
    canvas.clipPath(BudgiePaths.head(w, h));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.14),
        width: w * 0.12,
        height: h * 0.08,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.restore();
  }

  void _paintWingEdge(Canvas canvas, double w, double h) {
    canvas.drawPath(
      BudgiePaths.wing(w, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintOutline(Canvas canvas, double w, double h) {
    var silhouette = Path.combine(
      PathOperation.union,
      BudgiePaths.belly(w, h),
      BudgiePaths.head(w, h),
    );
    silhouette = Path.combine(
      PathOperation.union,
      silhouette,
      BudgiePaths.tail(w, h),
    );
    silhouette = Path.combine(
      PathOperation.union,
      silhouette,
      BudgiePaths.beak(w, h),
    );

    canvas.drawPath(
      silhouette,
      Paint()
        ..color = const Color(0x45000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeJoin = StrokeJoin.round,
    );
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
      appearance != oldDelegate.appearance ||
      isFemale != oldDelegate.isFemale;
}
