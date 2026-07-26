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
  }) => calculateDetailed(birdId: birdId, ancestors: ancestors).coefficient;

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

    // Collect every path from the father line and mother line, storing each
    // path as the SET of individuals it passes through (line root → ancestor,
    // inclusive). Storing full paths — not just depths — is what lets us apply
    // Wright's disjoint-path rule below.
    final fatherPaths = <String, List<Set<String>>>{};
    final motherPaths = <String, List<Set<String>>>{};
    var depthLimited = false;
    void onDepthLimit() => depthLimited = true;

    _collectPaths(
      bird.fatherId!,
      ancestors,
      fatherPaths,
      const {},
      0,
      onDepthLimit: onDepthLimit,
    );
    _collectPaths(
      bird.motherId!,
      ancestors,
      motherPaths,
      const {},
      0,
      onDepthLimit: onDepthLimit,
    );

    final commonAncestors = fatherPaths.keys
        .where(motherPaths.containsKey)
        .toSet();
    if (commonAncestors.isEmpty) {
      return InbreedingDetail(coefficient: 0.0, depthLimited: depthLimited);
    }

    // Wright's path coefficient:
    //   F = Σ over each valid loop  (1/2)^(n1 + n2 + 1) · (1 + F_A)
    // A "loop" is a father-line path and a mother-line path that meet at a
    // common ancestor A and share NO other individual. Omitting the
    // share-no-other-individual check is the classic double-counting bug: an
    // ancestor reachable from both sides ONLY through a nearer common ancestor
    // does not form an independent loop — its relatedness is already captured
    // by the (1 + F_A) term of that nearer ancestor.
    final memo = <String, double>{};
    double coefficient = 0.0;
    for (final ancestorId in commonAncestors) {
      final fA = _inbreedingOf(
        ancestorId,
        ancestors,
        memo,
        <String>{},
        onDepthLimit: onDepthLimit,
      );
      for (final pf in fatherPaths[ancestorId]!) {
        for (final pm in motherPaths[ancestorId]!) {
          if (_sharesOnly(pf, pm, ancestorId)) {
            coefficient +=
                math.pow(0.5, (pf.length - 1) + (pm.length - 1) + 1) * (1 + fA);
          }
        }
      }
    }

    return InbreedingDetail(
      coefficient: coefficient.clamp(0.0, 0.5),
      depthLimited: depthLimited,
    );
  }

  /// Returns the set of common ancestor IDs between father and mother lines.
  ///
  /// This is the raw genealogical intersection (every individual appearing in
  /// both lines), used by the UI to highlight shared ancestors. Not every
  /// common ancestor forms an independent inbreeding loop — see
  /// [calculateDetailed] for the loop-counting rule.
  Set<String> findCommonAncestors({
    required String birdId,
    required Map<String, Bird> ancestors,
  }) {
    final bird = ancestors[birdId];
    if (bird == null || bird.fatherId == null || bird.motherId == null) {
      return const {};
    }

    final fatherPaths = <String, List<Set<String>>>{};
    final motherPaths = <String, List<Set<String>>>{};
    _collectPaths(bird.fatherId!, ancestors, fatherPaths, const {}, 0);
    _collectPaths(bird.motherId!, ancestors, motherPaths, const {}, 0);

    return fatherPaths.keys.where(motherPaths.containsKey).toSet();
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

  /// True when [a] and [b] share exactly one individual, [apex]. Both sets are
  /// guaranteed to contain [apex] (it is each path's endpoint), so the loop is
  /// valid iff they share no OTHER individual.
  bool _sharesOnly(Set<String> a, Set<String> b, String apex) {
    for (final id in a) {
      if (id != apex && b.contains(id)) return false;
    }
    return true;
  }

  /// Recursively computes Wright's inbreeding coefficient for [id] using the
  /// same disjoint-path rule as [calculateDetailed]. [memo] caches results per
  /// bird; [computing] breaks reference cycles in corrupt pedigrees.
  double _inbreedingOf(
    String id,
    Map<String, Bird> ancestors,
    Map<String, double> memo,
    Set<String> computing, {
    void Function()? onDepthLimit,
  }) {
    final cached = memo[id];
    if (cached != null) return cached;
    if (computing.contains(id)) return 0.0; // cycle guard

    final bird = ancestors[id];
    if (bird == null || bird.fatherId == null || bird.motherId == null) {
      memo[id] = 0.0;
      return 0.0;
    }

    computing.add(id);
    final fatherPaths = <String, List<Set<String>>>{};
    final motherPaths = <String, List<Set<String>>>{};
    // Propagate the truncation signal: an ancestor whose own pedigree exceeds
    // maxAncestorDepth under-estimates F_A in the (1 + F_A) term, so the
    // subject's coefficient is a lower bound and must be reported as such.
    //
    // DEFENSIVE, and currently unreachable — measured 2026-07-26, do not
    // re-litigate. This traversal restarts depth at 0 but walks a SUBSET of the
    // same chain the top-level pass already walked, starting deeper in absolute
    // terms. So any pedigree long enough to trip the limit here has already
    // tripped it there, and `depthLimited` is set either way. Sweeping chain
    // lengths 0..16 with and without these two arguments produced byte-identical
    // results, which is why no test can isolate this path: one would pass
    // regardless, exactly the vacuous-assertion trap fixed in
    // multi_locus_masking_test. Keep the propagation — it stops being redundant
    // the moment the top-level bound and this one stop sharing a chain (e.g. a
    // per-ancestor depth budget, or ancestors supplied by a second source).
    _collectPaths(
      bird.fatherId!,
      ancestors,
      fatherPaths,
      const {},
      0,
      onDepthLimit: onDepthLimit,
    );
    _collectPaths(
      bird.motherId!,
      ancestors,
      motherPaths,
      const {},
      0,
      onDepthLimit: onDepthLimit,
    );

    double f = 0.0;
    for (final ancestorId in fatherPaths.keys.where(motherPaths.containsKey)) {
      final fA = _inbreedingOf(
        ancestorId,
        ancestors,
        memo,
        computing,
        onDepthLimit: onDepthLimit,
      );
      for (final pf in fatherPaths[ancestorId]!) {
        for (final pm in motherPaths[ancestorId]!) {
          if (_sharesOnly(pf, pm, ancestorId)) {
            f +=
                math.pow(0.5, (pf.length - 1) + (pm.length - 1) + 1) * (1 + fA);
          }
        }
      }
    }
    computing.remove(id);

    final result = f.clamp(0.0, 0.5).toDouble();
    memo[id] = result;
    return result;
  }

  /// Collects every path from [id]'s line into [collected], keyed by ancestor
  /// ID. Each stored entry is the set of individuals on that path (line root →
  /// ancestor, inclusive); the number of edges to the ancestor is
  /// `set.length - 1`.
  void _collectPaths(
    String id,
    Map<String, Bird> allAncestors,
    Map<String, List<Set<String>>> collected,
    Set<String> pathSoFar,
    int depth, {
    void Function()? onDepthLimit,
  }) {
    if (depth > GeneticsConstants.maxAncestorDepth) {
      onDepthLimit?.call();
      return;
    }

    final bird = allAncestors[id];
    if (bird == null) return;

    // Guard against cyclic pedigree data (an individual appearing twice on the
    // same path).
    if (pathSoFar.contains(id)) return;
    final nextPath = {...pathSoFar, id};

    collected.putIfAbsent(id, () => []).add(nextPath);

    if (bird.fatherId != null) {
      _collectPaths(
        bird.fatherId!,
        allAncestors,
        collected,
        nextPath,
        depth + 1,
        onDepthLimit: onDepthLimit,
      );
    }
    if (bird.motherId != null) {
      _collectPaths(
        bird.motherId!,
        allAncestors,
        collected,
        nextPath,
        depth + 1,
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
