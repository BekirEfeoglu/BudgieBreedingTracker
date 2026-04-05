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
  }) =>
      calculateDetailed(birdId: birdId, ancestors: ancestors).coefficient;

  /// Calculates the inbreeding coefficient with metadata about the traversal.
  ///
  /// Returns [InbreedingDetail] which includes whether the pedigree depth
  /// limit was reached during ancestor collection.
  InbreedingDetail calculateDetailed({
    required String birdId,
    required Map<String, Bird> ancestors,
  }) {
    final bird = ancestors[birdId];
    if (bird == null) return const InbreedingDetail(coefficient: 0.0);
    if (bird.fatherId == null || bird.motherId == null) {
      return const InbreedingDetail(coefficient: 0.0);
    }

    // Build ancestor path lists for father and mother lines
    // Each ancestor can be reached via multiple paths → store ALL depths
    final fatherAncestors = <String, List<int>>{};
    final motherAncestors = <String, List<int>>{};
    var depthLimited = false;

    void onDepthLimit() => depthLimited = true;

    _collectAncestors(
      bird.fatherId!, ancestors, fatherAncestors, 0,
      onDepthLimit: onDepthLimit,
    );
    _collectAncestors(
      bird.motherId!, ancestors, motherAncestors, 0,
      onDepthLimit: onDepthLimit,
    );

    // Find common ancestors
    final commonAncestors = fatherAncestors.keys
        .where(motherAncestors.containsKey)
        .toSet();

    if (commonAncestors.isEmpty) {
      return InbreedingDetail(coefficient: 0.0, depthLimited: depthLimited);
    }

    // Wright's path coefficient: F = sum over all common ancestors A,
    // for each pair of paths (n1, n2): (1/2)^(n1+n2+1) * (1 + F_A)
    // where F_A is the inbreeding coefficient of common ancestor A.
    double coefficient = 0.0;
    for (final ancestorId in commonAncestors) {
      final fatherPaths = fatherAncestors[ancestorId]!;
      final motherPaths = motherAncestors[ancestorId]!;

      // Calculate F_A: the inbreeding coefficient of this common ancestor.
      // This accounts for cases where the common ancestor is itself inbred.
      final ancestor = ancestors[ancestorId];
      double ancestorF = 0.0;
      if (ancestor != null &&
          ancestor.fatherId != null &&
          ancestor.motherId != null) {
        final ancFatherAnc = <String, List<int>>{};
        final ancMotherAnc = <String, List<int>>{};
        _collectAncestors(ancestor.fatherId!, ancestors, ancFatherAnc, 0);
        _collectAncestors(ancestor.motherId!, ancestors, ancMotherAnc, 0);
        final ancCommon = ancFatherAnc.keys
            .where(ancMotherAnc.containsKey)
            .toSet();
        for (final aId in ancCommon) {
          for (final an1 in ancFatherAnc[aId]!) {
            for (final an2 in ancMotherAnc[aId]!) {
              ancestorF += math.pow(0.5, an1 + an2 + 1);
            }
          }
        }
        ancestorF = ancestorF.clamp(0.0, 0.5);
      }

      for (final n1 in fatherPaths) {
        for (final n2 in motherPaths) {
          coefficient += math.pow(0.5, n1 + n2 + 1) * (1 + ancestorF);
        }
      }
    }

    return InbreedingDetail(
      coefficient: coefficient.clamp(0.0, 0.5),
      depthLimited: depthLimited,
    );
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

    return fatherAncestors.keys.where(motherAncestors.containsKey).toSet();
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
    int depth, {
    Set<String>? pathVisited,
    void Function()? onDepthLimit,
  }) {
    if (depth > GeneticsConstants.maxAncestorDepth) {
      onDepthLimit?.call();
      return;
    }

    final bird = allAncestors[id];
    if (bird == null) return;

    // Guard against cyclic pedigree data (bird listed as its own ancestor)
    final visited = pathVisited ?? <String>{};
    if (visited.contains(id)) return;
    final nextVisited = {...visited, id};

    // Store ALL paths to each ancestor (not just shortest)
    collected.putIfAbsent(id, () => []).add(depth);

    if (bird.fatherId != null) {
      _collectAncestors(
        bird.fatherId!,
        allAncestors,
        collected,
        depth + 1,
        pathVisited: nextVisited,
        onDepthLimit: onDepthLimit,
      );
    }
    if (bird.motherId != null) {
      _collectAncestors(
        bird.motherId!,
        allAncestors,
        collected,
        depth + 1,
        pathVisited: nextVisited,
        onDepthLimit: onDepthLimit,
      );
    }
  }
}

/// Result of a detailed inbreeding calculation.
class InbreedingDetail {
  final double coefficient;

  /// Whether the pedigree traversal was truncated at [GeneticsConstants.maxAncestorDepth].
  final bool depthLimited;

  const InbreedingDetail({
    required this.coefficient,
    this.depthLimited = false,
  });
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
