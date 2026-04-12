part of 'budgie_painter.dart';

/// Anatomical detail elements: throat spots, feet, cere, and eye.
///
/// Separated from [BudgieDetails] marking methods (wing bars, head stripes,
/// tail stripes, spangle scallops) for file-size compliance.
abstract final class BudgieDetailsAnatomy {
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
    final spotRadius = (w * 0.030).clamp(2.0, 4.5);

    for (var i = 0; i < visibleCount; i++) {
      final t = (i + 1) / (visibleCount + 1);

      // Arc along the lower mask boundary
      final cx = w * (0.58 + t * 0.14);
      final cy = h * (0.34 + t * 0.02);

      canvas.drawCircle(Offset(cx, cy), spotRadius, paint);
    }
  }

  /// Draw feet and a perch beneath the bird.
  ///
  /// Painted between tail and body so legs appear attached to the body
  /// with the tail behind.
  static void paintFeet(Canvas canvas, double w, double h) {
    const legColor = Color(0xFF8C7E72);
    final legWidth = (w * 0.022).clamp(1.0, 2.5);

    final legPaint = Paint()
      ..color = legColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = legWidth
      ..strokeCap = StrokeCap.round;

    // Left leg
    canvas.drawLine(
      Offset(w * 0.42, h * 0.80),
      Offset(w * 0.40, h * 0.88),
      legPaint,
    );

    // Right leg
    canvas.drawLine(
      Offset(w * 0.52, h * 0.78),
      Offset(w * 0.50, h * 0.88),
      legPaint,
    );

    // Perch
    canvas.drawLine(
      Offset(w * 0.28, h * 0.88),
      Offset(w * 0.62, h * 0.88),
      Paint()
        ..color = const Color(0xFF9E8E7E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.030).clamp(1.5, 3.5)
        ..strokeCap = StrokeCap.round,
    );

    // Toes
    final toePaint = Paint()
      ..color = legColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.016).clamp(0.8, 2.0)
      ..strokeCap = StrokeCap.round;

    // Left foot
    canvas.drawLine(
      Offset(w * 0.40, h * 0.88),
      Offset(w * 0.36, h * 0.89),
      toePaint,
    );
    canvas.drawLine(
      Offset(w * 0.40, h * 0.88),
      Offset(w * 0.44, h * 0.89),
      toePaint,
    );

    // Right foot
    canvas.drawLine(
      Offset(w * 0.50, h * 0.88),
      Offset(w * 0.46, h * 0.89),
      toePaint,
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 0.88),
      Offset(w * 0.54, h * 0.89),
      toePaint,
    );
  }

  /// Draw the cere (fleshy nose area) above the beak.
  ///
  /// Color depends on sex: blue for male, brown/tan for female,
  /// neutral blue-grey when sex is unknown.
  static void paintCere(
    Canvas canvas, double w, double h, {
    bool? isFemale,
    bool isIno = false,
  }) {
    final Color color;
    if (isIno) {
      color = isFemale == true
          ? const Color(0xFFE8D5C8) // Pale pink — ino female
          : const Color(0xFFD4A5B8); // Pink/purple — ino male
    } else if (isFemale == true) {
      color = const Color(0xFFC4956E); // Brown/tan — female
    } else if (isFemale == false) {
      color = const Color(0xFF5B8DC7); // Blue — male
    } else {
      color = const Color(0xFF7BA3C7); // Neutral blue-grey — unknown
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.81, h * 0.20),
        width: w * 0.07,
        height: h * 0.032,
      ),
      Paint()..color = color,
    );
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
