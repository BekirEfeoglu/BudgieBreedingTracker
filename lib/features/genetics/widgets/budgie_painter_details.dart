part of 'budgie_painter.dart';

/// Fine detail elements painted on top of the budgie silhouette zones.
abstract final class BudgieDetails {
  /// Draw parallel wing bar stripes (5-7 curved lines across the wing zone).
  ///
  /// Bars follow the wing curvature from upper-left to lower-right.
  static void paintWingBars(
    Canvas canvas,
    double w,
    double h,
    Color color,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const barCount = 6;

    for (var i = 0; i < barCount; i++) {
      final t = (i + 1) / (barCount + 1);

      // Interpolate bar start/end positions across the wing area
      final startX = w * (0.38 + t * 0.22);
      final startY = h * (0.42 + t * 0.06);
      final endX = w * (0.42 + t * 0.20);
      final endY = h * (0.56 + t * 0.18);
      final ctrlX = w * (0.50 + t * 0.12);
      final ctrlY = h * (0.44 + t * 0.14);

      final barPath = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(ctrlX, ctrlY, endX, endY);

      canvas.drawPath(barPath, paint);
    }
  }

  /// Draw spangle scallop pattern (reversed: light center, thin dark edge).
  ///
  /// Instead of dark bar stripes, draws thin arc outlines suggesting
  /// feather edges — characteristic of SF Spangle wing markings.
  static void paintSpangleScallops(
    Canvas canvas,
    double w,
    double h,
    Color color,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (strokeWidth * 0.7).clamp(0.6, 2.0)
      ..strokeCap = StrokeCap.round;

    const scallops = 5;
    for (var i = 0; i < scallops; i++) {
      final t = (i + 1) / (scallops + 1);

      // Small arcs (U-shapes) representing feather edges
      final cx = w * (0.42 + t * 0.20);
      final cy = h * (0.48 + t * 0.14);
      final rx = w * 0.04;
      final ry = h * 0.025;

      final arc = Path()
        ..moveTo(cx - rx, cy - ry * 0.5)
        ..quadraticBezierTo(cx, cy + ry, cx + rx, cy - ry * 0.5);

      canvas.drawPath(arc, paint);
    }
  }

  /// Draw head/nape stripes (characteristic budgie markings).
  ///
  /// Stripes follow the contour of the back of the head from crown
  /// to nape. Clipped to the head shape and painted BEFORE the mask
  /// so the mask naturally covers front-facing stripes.
  static void paintHeadStripes(
    Canvas canvas,
    double w,
    double h,
    Color color,
    double strokeWidth, {
    int stripeCount = 4,
    double opacity = 0.55,
  }) {
    canvas.save();
    canvas.clipPath(BudgiePaths.head(w, h));

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < stripeCount; i++) {
      final t = (i + 1) / (stripeCount + 1);

      // Crown-to-nape arc following the back contour of the head
      final startX = w * (0.52 + t * 0.06);
      final startY = h * (0.08 + t * 0.01);
      final endX = w * (0.48 + t * 0.04);
      final endY = h * (0.24 + t * 0.04);
      final ctrlX = w * (0.42 + t * 0.02);
      final ctrlY = h * (0.14 + t * 0.04);

      final stripePath = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(ctrlX, ctrlY, endX, endY);

      canvas.drawPath(stripePath, paint);
    }

    canvas.restore();
  }

  /// Draw subtle feather texture lines on the body/belly zone.
  ///
  /// Very light curved lines suggesting layered breast feathers.
  /// Only rendered at h >= 56px to avoid clutter at small sizes.
  static void paintBodyFeatherTexture(
    Canvas canvas,
    double w,
    double h,
    Color bodyColor,
  ) {
    final lightness = HSLColor.fromColor(bodyColor).lightness;
    // Lighter feather lines on dark bodies, darker on light bodies
    final lineColor = lightness < 0.5
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.010).clamp(0.5, 1.2)
      ..strokeCap = StrokeCap.round;

    const lineCount = 5;
    for (var i = 0; i < lineCount; i++) {
      final t = (i + 1) / (lineCount + 1);

      // Horizontal curves following belly contour
      final startX = w * (0.24 + t * 0.08);
      final startY = h * (0.50 + t * 0.10);
      final endX = w * (0.58 + t * 0.04);
      final endY = h * (0.48 + t * 0.12);
      final ctrlX = w * (0.40 + t * 0.06);
      final ctrlY = h * (0.46 + t * 0.14);

      final featherPath = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(ctrlX, ctrlY, endX, endY);

      canvas.drawPath(featherPath, paint);
    }
  }

  /// Draw subtle feather layering on the wing zone.
  ///
  /// Adds depth between wing bars, suggesting individual feather rows.
  static void paintWingFeatherTexture(
    Canvas canvas,
    double w,
    double h,
    Color wingColor,
  ) {
    final lightness = HSLColor.fromColor(wingColor).lightness;
    final lineColor = lightness < 0.5
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.008).clamp(0.4, 1.0)
      ..strokeCap = StrokeCap.round;

    const lineCount = 4;
    for (var i = 0; i < lineCount; i++) {
      final t = (i + 1) / (lineCount + 1);

      final startX = w * (0.36 + t * 0.14);
      final startY = h * (0.48 + t * 0.06);
      final endX = w * (0.52 + t * 0.12);
      final endY = h * (0.64 + t * 0.08);
      final ctrlX = w * (0.44 + t * 0.14);
      final ctrlY = h * (0.54 + t * 0.10);

      final featherPath = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(ctrlX, ctrlY, endX, endY);

      canvas.drawPath(featherPath, paint);
    }
  }

  /// Draw longitudinal stripes along the tail feathers.
  ///
  /// Clipped to the tail shape. Three curved lines following the
  /// diagonal direction of the tail from body toward tip.
  static void paintTailStripes(
    Canvas canvas,
    double w,
    double h,
    Color tailColor,
  ) {
    canvas.save();
    canvas.clipPath(BudgiePaths.tail(w, h));

    final paint = Paint()
      ..color = tailColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.012).clamp(0.6, 1.5)
      ..strokeCap = StrokeCap.round;

    const lineCount = 3;
    for (var i = 0; i < lineCount; i++) {
      final t = (i + 1) / (lineCount + 1);

      final startX = w * (0.28 + t * 0.06);
      final startY = h * (0.72 + t * 0.02);
      final endX = w * (0.06 + t * 0.06);
      final endY = h * (0.94 + t * 0.01);
      final ctrlX = w * (0.16 + t * 0.04);
      final ctrlY = h * (0.82 + t * 0.02);

      final stripePath = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(ctrlX, ctrlY, endX, endY);

      canvas.drawPath(stripePath, paint);
    }

    canvas.restore();
  }

}
