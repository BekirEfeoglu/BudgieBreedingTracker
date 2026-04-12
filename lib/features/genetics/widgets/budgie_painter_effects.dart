part of 'budgie_painter.dart';

extension _BudgiePainterEffects on BudgiePainter {
  void _paintShadow(Canvas canvas, double w, double h) {
    final shadowCenter = Offset(w * 0.42, h * 0.96);
    // Outer soft shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: w * 0.40,
        height: h * 0.045,
      ),
      Paint()
        ..color = const Color(0x10000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Inner dense shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: w * 0.28,
        height: h * 0.025,
      ),
      Paint()..color = const Color(0x22000000),
    );
  }

  void _paintBellyHighlight(Canvas canvas, double w, double h) {
    canvas.save();
    canvas.clipPath(BudgiePaths.belly(w, h));
    // Primary belly highlight (chest area)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.54, h * 0.52),
        width: w * 0.24,
        height: h * 0.18,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    // Secondary smaller specular highlight (breast center)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.56, h * 0.48),
        width: w * 0.10,
        height: h * 0.08,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.restore();
  }

  void _paintWingUnderShadow(Canvas canvas, double w, double h) {
    // Subtle shadow along the top edge of the wing to separate from body
    final shadowPath = Path()
      ..moveTo(w * 0.38, h * 0.40)
      ..quadraticBezierTo(w * 0.54, h * 0.36, w * 0.66, h * 0.42)
      ..lineTo(w * 0.66, h * 0.44)
      ..quadraticBezierTo(w * 0.54, h * 0.38, w * 0.38, h * 0.42)
      ..close();

    canvas.save();
    canvas.clipPath(BudgiePaths.belly(w, h));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.restore();
  }

  void _paintHeadHighlight(Canvas canvas, double w, double h) {
    canvas.save();
    canvas.clipPath(BudgiePaths.head(w, h));
    // Primary head highlight (crown area)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.13),
        width: w * 0.14,
        height: h * 0.09,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    // Small specular spot (top of head)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.63, h * 0.10),
        width: w * 0.06,
        height: h * 0.04,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    canvas.restore();
  }

  void _paintWingEdge(Canvas canvas, double w, double h) {
    // Soft outer glow for wing separation
    canvas.drawPath(
      BudgiePaths.wing(w, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
    // Crisp inner edge highlight
    canvas.drawPath(
      BudgiePaths.wing(w, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
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

  void _paintDominantPiedPatches(Canvas canvas, double w, double h) {
    final color = appearance.piedPatchColor;
    final paint = Paint()..color = color;

    // Small chest patch
    canvas.save();
    canvas.clipPath(BudgiePaths.belly(w, h));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.58, h * 0.46),
        width: w * 0.10,
        height: h * 0.06,
      ),
      paint,
    );
    // Small lower belly patch
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.44, h * 0.70),
        width: w * 0.08,
        height: h * 0.05,
      ),
      paint,
    );
    canvas.restore();

    // Small wing patch
    canvas.save();
    canvas.clipPath(BudgiePaths.wing(w, h));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.54, h * 0.58),
        width: w * 0.09,
        height: h * 0.05,
      ),
      paint,
    );
    canvas.restore();
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
}
