import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/budgie_painter.dart';

/// Renders a budgerigar color simulation based on genetic mutations.
///
/// Uses [BudgiePainter] to draw a side-profile silhouette with
/// anatomically correct color zones.
class BirdColorSimulation extends StatelessWidget {
  final List<String> visualMutations;
  final List<String> carriedMutations;
  final String phenotype;

  /// Height of the simulation. Width is derived as `height * 0.75`.
  final double height;

  /// Optional explicit width. If null, defaults to `height * 0.75`.
  final double? width;

  /// @deprecated Use [height] instead.
  final double? size;

  const BirdColorSimulation({
    super.key,
    required this.visualMutations,
    this.carriedMutations = const [],
    required this.phenotype,
    this.height = 72,
    this.width,
    @Deprecated('Use height instead') this.size,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = (size ?? height).clamp(48.0, double.infinity);
    final effectiveWidth = width ?? effectiveHeight * 0.75;

    final appearance = BudgieColorResolver.resolve(
      visualMutations: visualMutations,
      carriedMutations: carriedMutations,
      phenotype: phenotype,
    );

    return Semantics(
      label: phenotype,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(effectiveWidth, effectiveHeight),
          painter: BudgiePainter(appearance: appearance),
        ),
      ),
    );
  }
}
