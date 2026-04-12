import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

const _connectorPaddingH = 6.0;
const _connectorPaddingV = 2.0;

/// Small label widget for generation/line identification.
class GenerationLabel extends StatelessWidget {
  final String label;

  const GenerationLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: _connectorPaddingH, vertical: _connectorPaddingV),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Paints connecting lines from offspring (left) to root (right).
class OffspringConnectorPainter extends CustomPainter {
  final int childCount;
  final Color lineColor;

  const OffspringConnectorPainter({
    required this.childCount,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rightMidY = size.height / 2;

    if (childCount == 1) {
      canvas.drawLine(
        Offset(0, rightMidY),
        Offset(size.width, rightMidY),
        paint,
      );
    } else {
      final spacing = size.height / childCount;

      canvas.drawLine(
        Offset(size.width / 2, rightMidY),
        Offset(size.width, rightMidY),
        paint,
      );

      final firstY = spacing / 2;
      final lastY = size.height - spacing / 2;
      canvas.drawLine(
        Offset(size.width / 2, firstY),
        Offset(size.width / 2, lastY),
        paint,
      );

      for (int i = 0; i < childCount; i++) {
        final y = firstY + i * spacing;
        canvas.drawLine(Offset(0, y), Offset(size.width / 2, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant OffspringConnectorPainter oldDelegate) =>
      oldDelegate.childCount != childCount ||
      oldDelegate.lineColor != lineColor;
}

/// Paints curved connecting lines from parent (left) to ancestors (right).
/// Uses gender-based coloring: blue for father (top), pink for mother (bottom).
class AncestorConnectorPainter extends CustomPainter {
  final int depth;
  final Color baseColor;

  const AncestorConnectorPainter({this.depth = 0, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final midY = size.height / 2;

    // Father line (top) - blue tint
    final fatherPaint = Paint()
      ..color = AppColors.genderMale.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Mother line (bottom) - pink tint
    final motherPaint = Paint()
      ..color = AppColors.genderFemale.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Horizontal line from left to center
    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, midY), Offset(midX, midY), basePaint);

    // Curved path to father (top)
    final fatherPath = Path()
      ..moveTo(midX, midY)
      ..quadraticBezierTo(midX, 0, size.width, 0);
    canvas.drawPath(fatherPath, fatherPaint);

    // Curved path to mother (bottom)
    final motherPath = Path()
      ..moveTo(midX, midY)
      ..quadraticBezierTo(midX, size.height, size.width, size.height);
    canvas.drawPath(motherPath, motherPaint);
  }

  @override
  bool shouldRepaint(covariant AncestorConnectorPainter oldDelegate) =>
      oldDelegate.depth != depth || oldDelegate.baseColor != baseColor;
}
