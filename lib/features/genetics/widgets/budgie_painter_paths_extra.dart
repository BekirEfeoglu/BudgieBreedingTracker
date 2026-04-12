part of 'budgie_painter.dart';

abstract final class BudgiePathsExtra {
  static Path cheekPatch(double w, double h) {
    final cx = w * 0.66;
    final cy = h * 0.32;
    final rx = w * 0.08;
    final ry = h * 0.055;
    return Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));
  }

  static Path dutchPiedWingPatch(double w, double h) {
    return Path()
      ..moveTo(w * 0.48, h * 0.48)
      ..cubicTo(
        w * 0.44, h * 0.52,
        w * 0.44, h * 0.60,
        w * 0.48, h * 0.64,
      )
      ..cubicTo(
        w * 0.52, h * 0.68,
        w * 0.60, h * 0.68,
        w * 0.64, h * 0.62,
      )
      ..cubicTo(
        w * 0.68, h * 0.56,
        w * 0.64, h * 0.48,
        w * 0.58, h * 0.46,
      )
      ..cubicTo(
        w * 0.54, h * 0.44,
        w * 0.50, h * 0.46,
        w * 0.48, h * 0.48,
      )
      ..close();
  }

  static Path piedPatch(double w, double h) {
    return Path()
      ..moveTo(w * 0.34, h * 0.55)
      ..cubicTo(
        w * 0.26, h * 0.58,
        w * 0.22, h * 0.65,
        w * 0.25, h * 0.73,
      )
      ..cubicTo(
        w * 0.28, h * 0.78,
        w * 0.36, h * 0.80,
        w * 0.44, h * 0.77,
      )
      ..cubicTo(
        w * 0.49, h * 0.74,
        w * 0.47, h * 0.64,
        w * 0.44, h * 0.59,
      )
      ..cubicTo(
        w * 0.41, h * 0.55,
        w * 0.38, h * 0.54,
        w * 0.34, h * 0.55,
      )
      ..close();
  }
}
