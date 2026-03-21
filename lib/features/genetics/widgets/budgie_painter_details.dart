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

  /// Draw throat spots below the mask area.
  ///
  /// In side profile only half the spots are visible, so the rendered
  /// count is `(totalCount / 2).ceil()`. Spots are arranged in a loose
  /// arc on the lower mask boundary.
  static void paintThroatSpots(
    Canvas canvas,
    double w,
    double h,
    Color color,
    int totalCount,
  ) {
    final visibleCount = (totalCount / 2).ceil();
    if (visibleCount <= 0) return;

    final paint = Paint()..color = color;
    final spotRadius = (w * 0.022).clamp(1.5, 4.0);

    for (var i = 0; i < visibleCount; i++) {
      final t = (i + 1) / (visibleCount + 1);

      // Arc along the lower mask boundary
      final cx = w * (0.58 + t * 0.14);
      final cy = h * (0.34 + t * 0.02);

      canvas.drawCircle(Offset(cx, cy), spotRadius, paint);
    }
  }

  /// Draw the eye with optional eye-ring and a small highlight dot.
  ///
  /// The eye sits in the upper-right quadrant of the head, roughly at
  /// (0.66w, 0.20h) in the overall canvas coordinate space.
  static void paintEye(
    Canvas canvas,
    double w,
    double h,
    Color eyeColor,
    Color eyeRingColor,
    bool showRing,
  ) {
    final cx = w * 0.66;
    final cy = h * 0.20;
    final eyeRadius = (w * 0.04).clamp(2.0, 6.0);

    // Optional iris ring
    if (showRing) {
      canvas.drawCircle(
        Offset(cx, cy),
        eyeRadius * 1.45,
        Paint()..color = eyeRingColor,
      );
    }

    // Iris
    canvas.drawCircle(
      Offset(cx, cy),
      eyeRadius,
      Paint()..color = eyeColor,
    );

    // Highlight dot (top-right of iris)
    final highlightRadius = (eyeRadius * 0.30).clamp(0.8, 2.0);
    canvas.drawCircle(
      Offset(cx + eyeRadius * 0.28, cy - eyeRadius * 0.28),
      highlightRadius,
      Paint()..color = const Color(0xCCFFFFFF),
    );
  }
}
