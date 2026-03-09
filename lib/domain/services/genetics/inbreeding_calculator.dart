import 'dart:math' as math;

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

/// Calculates the inbreeding coefficient from pedigree data
/// using Wright's path coefficient method.
///
/// Returns a double from 0.0 (no inbreeding) to 0.5 (maximum).
class InbreedingCalculator {
  const InbreedingCalculator();

  /// Calculates the inbreeding coefficient for a bird given its ancestors.
  ///
  /// [birdId] is the subject bird.
  /// [ancestors] is a flat map of all ancestor birds keyed by ID.
  double calculate({
    required String birdId,
    required Map<String, Bird> ancestors,
  }) {
    final bird = ancestors[birdId];
    if (bird == null) return 0.0;
    if (bird.fatherId == null || bird.motherId == null) return 0.0;

    // Build ancestor path lists for father and mother lines
    // Each ancestor can be reached via multiple paths → store ALL depths
    final fatherAncestors = <String, List<int>>{};
    final motherAncestors = <String, List<int>>{};

    _collectAncestors(bird.fatherId!, ancestors, fatherAncestors, 0);
    _collectAncestors(bird.motherId!, ancestors, motherAncestors, 0);

    // Find common ancestors
    final commonAncestors = fatherAncestors.keys
        .where(motherAncestors.containsKey)
        .toSet();

    if (commonAncestors.isEmpty) return 0.0;

    // Wright's path coefficient: F = sum over all common ancestors A,
    // for each pair of paths (n1, n2): (1/2)^(n1+n2+1)
    double coefficient = 0.0;
    for (final ancestorId in commonAncestors) {
      final fatherPaths = fatherAncestors[ancestorId]!;
      final motherPaths = motherAncestors[ancestorId]!;

      for (final n1 in fatherPaths) {
        for (final n2 in motherPaths) {
          coefficient += math.pow(0.5, n1 + n2 + 1);
        }
      }
    }

    return coefficient.clamp(0.0, 0.5);
  }

  /// Returns the set of common ancestor IDs between father and mother lines.
  Set<String> findCommonAncestors({
    required String birdId,
    required Map<String, Bird> ancestors,
  }) {
    final bird = ancestors[birdId];
    if (bird == null || bird.fatherId == null || bird.motherId == null) {
      return const {};
    }

    final fatherAncestors = <String, List<int>>{};
    final motherAncestors = <String, List<int>>{};

    _collectAncestors(bird.fatherId!, ancestors, fatherAncestors, 0);
    _collectAncestors(bird.motherId!, ancestors, motherAncestors, 0);

    return fatherAncestors.keys
        .where(motherAncestors.containsKey)
        .toSet();
  }

  /// Returns a human-readable risk level for the given coefficient.
  InbreedingRisk assessRisk(double coefficient) {
    if (coefficient >= GeneticsConstants.inbreedingCritical) {
      return InbreedingRisk.critical;
    }
    if (coefficient >= GeneticsConstants.inbreedingHigh) {
      return InbreedingRisk.high;
    }
    if (coefficient >= GeneticsConstants.inbreedingModerate) {
      return InbreedingRisk.moderate;
    }
    if (coefficient >= GeneticsConstants.inbreedingLow) {
      return InbreedingRisk.low;
    }
    if (coefficient >= GeneticsConstants.inbreedingMinimal) {
      return InbreedingRisk.minimal;
    }
    return InbreedingRisk.none;
  }

  void _collectAncestors(
    String id,
    Map<String, Bird> allAncestors,
    Map<String, List<int>> collected,
    int depth,
  ) {
    if (depth > 10) return; // Safety limit

    final bird = allAncestors[id];
    if (bird == null) return;

    // Store ALL paths to each ancestor (not just shortest)
    collected.putIfAbsent(id, () => []).add(depth);

    if (bird.fatherId != null) {
      _collectAncestors(
        bird.fatherId!,
        allAncestors,
        collected,
        depth + 1,
      );
    }
    if (bird.motherId != null) {
      _collectAncestors(
        bird.motherId!,
        allAncestors,
        collected,
        depth + 1,
      );
    }
  }
}

/// Risk levels for inbreeding coefficient values.
enum InbreedingRisk {
  none,
  minimal,
  low,
  moderate,
  high,
  critical;

  /// Localization key for the risk label.
  String get labelKey => switch (this) {
        InbreedingRisk.none => 'genetics.risk_none',
        InbreedingRisk.minimal => 'genetics.risk_minimal',
        InbreedingRisk.low => 'genetics.risk_low',
        InbreedingRisk.moderate => 'genetics.risk_moderate',
        InbreedingRisk.high => 'genetics.risk_high',
        InbreedingRisk.critical => 'genetics.risk_critical',
      };
}
