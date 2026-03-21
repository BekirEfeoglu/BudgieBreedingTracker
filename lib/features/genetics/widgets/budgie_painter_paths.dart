part of 'budgie_painter.dart';

/// Normalized path definitions for budgie silhouette zones.
///
/// Budgie faces RIGHT in side profile. Aspect ratio ~3:4 (w:h).
/// All coordinates are expressed as fractions of [w] and [h] so the
/// silhouette scales to any container size.
abstract final class BudgiePaths {
  /// Long tapered tail feathers extending down-left from the body.
  static Path tail(double w, double h) {
    return Path()
      ..moveTo(w * 0.32, h * 0.72)
      ..cubicTo(
        w * 0.26, h * 0.78,
        w * 0.15, h * 0.86,
        w * 0.06, h * 0.96,
      )
      ..cubicTo(
        w * 0.04, h * 0.98,
        w * 0.02, h * 0.99,
        w * 0.03, h * 0.97,
      )
      ..cubicTo(
        w * 0.05, h * 0.94,
        w * 0.08, h * 0.90,
        w * 0.10, h * 0.88,
      )
      ..cubicTo(
        w * 0.08, h * 0.92,
        w * 0.06, h * 0.95,
        w * 0.05, h * 0.98,
      )
      ..cubicTo(
        w * 0.07, h * 0.96,
        w * 0.14, h * 0.88,
        w * 0.18, h * 0.84,
      )
      ..cubicTo(
        w * 0.22, h * 0.80,
        w * 0.28, h * 0.76,
        w * 0.36, h * 0.72,
      )
      ..cubicTo(
        w * 0.34, h * 0.72,
        w * 0.33, h * 0.72,
        w * 0.32, h * 0.72,
      )
      ..close();
  }

  /// Large rounded belly / body region (central mass).
  static Path belly(double w, double h) {
    return Path()
      ..moveTo(w * 0.38, h * 0.35)
      ..cubicTo(
        w * 0.22, h * 0.38,
        w * 0.14, h * 0.50,
        w * 0.16, h * 0.62,
      )
      ..cubicTo(
        w * 0.18, h * 0.72,
        w * 0.26, h * 0.80,
        w * 0.38, h * 0.82,
      )
      ..cubicTo(
        w * 0.50, h * 0.84,
        w * 0.62, h * 0.80,
        w * 0.68, h * 0.72,
      )
      ..cubicTo(
        w * 0.74, h * 0.64,
        w * 0.74, h * 0.52,
        w * 0.68, h * 0.42,
      )
      ..cubicTo(
        w * 0.62, h * 0.36,
        w * 0.50, h * 0.34,
        w * 0.38, h * 0.35,
      )
      ..close();
  }

  /// Dorsal mantle/back region overlapping upper body.
  static Path back(double w, double h) {
    return Path()
      ..moveTo(w * 0.42, h * 0.32)
      ..cubicTo(
        w * 0.34, h * 0.34,
        w * 0.28, h * 0.40,
        w * 0.26, h * 0.48,
      )
      ..cubicTo(
        w * 0.24, h * 0.56,
        w * 0.26, h * 0.64,
        w * 0.32, h * 0.70,
      )
      ..cubicTo(
        w * 0.36, h * 0.66,
        w * 0.40, h * 0.58,
        w * 0.42, h * 0.50,
      )
      ..cubicTo(
        w * 0.44, h * 0.42,
        w * 0.44, h * 0.36,
        w * 0.42, h * 0.32,
      )
      ..close();
  }

  /// Folded wing against the body side.
  static Path wing(double w, double h) {
    return Path()
      ..moveTo(w * 0.38, h * 0.40)
      ..cubicTo(
        w * 0.34, h * 0.46,
        w * 0.32, h * 0.56,
        w * 0.34, h * 0.66,
      )
      ..cubicTo(
        w * 0.36, h * 0.74,
        w * 0.42, h * 0.80,
        w * 0.52, h * 0.82,
      )
      ..cubicTo(
        w * 0.62, h * 0.80,
        w * 0.72, h * 0.72,
        w * 0.76, h * 0.62,
      )
      ..cubicTo(
        w * 0.78, h * 0.54,
        w * 0.74, h * 0.46,
        w * 0.66, h * 0.42,
      )
      ..cubicTo(
        w * 0.58, h * 0.38,
        w * 0.48, h * 0.38,
        w * 0.38, h * 0.40,
      )
      ..close();
  }

  /// Rounded head with the characteristic budgie flat-top.
  static Path head(double w, double h) {
    return Path()
      ..moveTo(w * 0.50, h * 0.28)
      ..cubicTo(
        w * 0.44, h * 0.16,
        w * 0.50, h * 0.06,
        w * 0.60, h * 0.06,
      )
      ..cubicTo(
        w * 0.70, h * 0.06,
        w * 0.78, h * 0.12,
        w * 0.80, h * 0.20,
      )
      ..cubicTo(
        w * 0.82, h * 0.28,
        w * 0.78, h * 0.36,
        w * 0.70, h * 0.38,
      )
      ..cubicTo(
        w * 0.64, h * 0.40,
        w * 0.56, h * 0.36,
        w * 0.50, h * 0.28,
      )
      ..close();
  }

  /// Facial mask covering forehead and chin around the beak.
  static Path mask(double w, double h) {
    return Path()
      ..moveTo(w * 0.56, h * 0.14)
      ..cubicTo(
        w * 0.54, h * 0.10,
        w * 0.58, h * 0.08,
        w * 0.64, h * 0.08,
      )
      ..cubicTo(
        w * 0.72, h * 0.08,
        w * 0.78, h * 0.14,
        w * 0.80, h * 0.20,
      )
      ..cubicTo(
        w * 0.82, h * 0.26,
        w * 0.80, h * 0.32,
        w * 0.74, h * 0.36,
      )
      ..cubicTo(
        w * 0.70, h * 0.38,
        w * 0.64, h * 0.38,
        w * 0.60, h * 0.36,
      )
      ..cubicTo(
        w * 0.56, h * 0.32,
        w * 0.54, h * 0.26,
        w * 0.54, h * 0.22,
      )
      ..cubicTo(
        w * 0.54, h * 0.18,
        w * 0.55, h * 0.16,
        w * 0.56, h * 0.14,
      )
      ..close();
  }

  /// Small hooked beak on the right side of the head.
  static Path beak(double w, double h) {
    return Path()
      ..moveTo(w * 0.78, h * 0.22)
      ..cubicTo(
        w * 0.80, h * 0.20,
        w * 0.84, h * 0.20,
        w * 0.86, h * 0.22,
      )
      ..cubicTo(
        w * 0.88, h * 0.24,
        w * 0.87, h * 0.27,
        w * 0.84, h * 0.28,
      )
      ..cubicTo(
        w * 0.82, h * 0.29,
        w * 0.80, h * 0.28,
        w * 0.78, h * 0.26,
      )
      ..cubicTo(
        w * 0.77, h * 0.25,
        w * 0.77, h * 0.23,
        w * 0.78, h * 0.22,
      )
      ..close();
  }

  /// Oval cheek patch below and behind the eye.
  static Path cheekPatch(double w, double h) {
    final cx = w * 0.66;
    final cy = h * 0.32;
    final rx = w * 0.06;
    final ry = h * 0.04;
    return Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));
  }

  /// Irregular pied patch on the belly region.
  static Path piedPatch(double w, double h) {
    return Path()
      ..moveTo(w * 0.36, h * 0.58)
      ..cubicTo(
        w * 0.30, h * 0.60,
        w * 0.26, h * 0.66,
        w * 0.28, h * 0.72,
      )
      ..cubicTo(
        w * 0.30, h * 0.76,
        w * 0.36, h * 0.78,
        w * 0.42, h * 0.76,
      )
      ..cubicTo(
        w * 0.46, h * 0.74,
        w * 0.44, h * 0.66,
        w * 0.42, h * 0.62,
      )
      ..cubicTo(
        w * 0.40, h * 0.58,
        w * 0.38, h * 0.57,
        w * 0.36, h * 0.58,
      )
      ..close();
  }
}
