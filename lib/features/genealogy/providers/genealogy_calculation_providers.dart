import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:budgie_breeding_tracker/shared/providers/genealogy.dart';

typedef InbreedingData = ({
  double coefficient,
  InbreedingRisk risk,
  Set<String> commonAncestorIds,
  bool depthLimited,
});

/// Calculates inbreeding coefficient and common ancestor IDs for a bird.
///
/// [maxDepth] is the generation depth used to build [ancestors] (see
/// `ancestorsProvider`/`chickAncestorsProvider`). Since that map is already
/// truncated to the user's chosen pedigree depth (3-8) before it reaches
/// [InbreedingCalculator] — whose own internal depth cap is a much deeper,
/// fixed safety net unrelated to that setting — `detail.depthLimited` alone
/// can never reflect a truncation caused by [maxDepth]. [_isLineageTruncated]
/// checks the actual boundary so the UI can warn the coefficient may be an
/// underestimate.
InbreedingData calculateInbreedingForBird(
  String birdId,
  Map<String, Bird> ancestors, {
  int maxDepth = 5,
}) {
  const calculator = InbreedingCalculator();
  final detail = calculator.calculateDetailed(
    birdId: birdId,
    ancestors: ancestors,
  );
  final risk = calculator.assessRisk(detail.coefficient);
  final commonIds = calculator.findCommonAncestors(
    birdId: birdId,
    ancestors: ancestors,
  );
  return (
    coefficient: detail.coefficient,
    risk: risk,
    commonAncestorIds: commonIds,
    depthLimited:
        detail.depthLimited || _isLineageTruncated(birdId, ancestors, maxDepth),
  );
}

/// Whether ancestor collection stopped at [maxDepth] while a real parent
/// link still existed beyond it — i.e. the map was truncated by the
/// pedigree-depth setting, not because the lineage genuinely ends there.
bool _isLineageTruncated(
  String rootId,
  Map<String, Bird> ancestors,
  int maxDepth,
) {
  final visited = <String>{};
  bool truncated = false;

  void walk(String? id, int depth) {
    if (id == null || truncated || !visited.add(id)) return;
    final bird = ancestors[id];
    if (bird == null) return;
    if (depth >= maxDepth) {
      if (bird.fatherId != null || bird.motherId != null) truncated = true;
      return;
    }
    walk(bird.fatherId, depth + 1);
    walk(bird.motherId, depth + 1);
  }

  walk(rootId, 0);
  return truncated;
}

/// Memoized inbreeding data provider — recomputes only when ancestors change.
final inbreedingDataProvider =
    FutureProvider.family<InbreedingData, ({String entityId, bool isChick})>((
      ref,
      params,
    ) async {
      final ancestors = params.isChick
          ? await ref.watch(chickAncestorsProvider(params.entityId).future)
          : await ref.watch(ancestorsProvider(params.entityId).future);
      final maxDepth = ref.watch(pedigreeDepthProvider);
      return calculateInbreedingForBird(
        params.entityId,
        ancestors,
        maxDepth: maxDepth,
      );
    });

typedef AncestorStats = ({
  int found,
  int possible,
  int deepestGeneration,
  double completeness,
});

/// Calculates ancestor tree statistics from the ancestors map.
/// [maxDepth] determines possible ancestor count dynamically: sum(2^i, i=1..depth).
AncestorStats calculateAncestorStats(
  String rootId,
  Map<String, Bird> ancestors, {
  int maxDepth = 5,
}) {
  final root = ancestors[rootId];
  if (root == null) {
    return (found: 0, possible: 0, deepestGeneration: 0, completeness: 0.0);
  }

  int found = 0;
  int deepest = 0;
  // Cycle guard: a corrupted pedigree (sync conflict, manual import)
  // can list a bird as its own ancestor. Without `visited` the recursion
  // would overflow the stack — `maxDepth = 5` alone is not enough
  // because the cycle can fit within five levels.
  final visited = <String>{};

  void countAncestors(String? id, int depth) {
    if (id == null || depth > maxDepth) return;
    if (!visited.add(id)) return;
    final bird = ancestors[id];
    if (bird == null) return;
    if (depth > 0) found++; // Don't count root
    if (depth > deepest) deepest = depth;
    countAncestors(bird.fatherId, depth + 1);
    countAncestors(bird.motherId, depth + 1);
  }

  countAncestors(rootId, 0);

  // Possible ancestors for N generations: sum(2^i, i=1..N)
  int possible = 0;
  for (int i = 1; i <= maxDepth; i++) {
    possible += 1 << i; // 2^i
  }

  final completeness = possible > 0 ? (found / possible * 100) : 0.0;

  return (
    found: found,
    possible: possible,
    deepestGeneration: deepest,
    completeness: completeness,
  );
}

/// Memoized ancestor stats provider — recomputes only when ancestors/depth change.
final ancestorStatsProvider =
    FutureProvider.family<AncestorStats, ({String entityId, bool isChick})>((
      ref,
      params,
    ) async {
      final ancestors = params.isChick
          ? await ref.watch(chickAncestorsProvider(params.entityId).future)
          : await ref.watch(ancestorsProvider(params.entityId).future);
      final maxDepth = ref.watch(pedigreeDepthProvider);
      return calculateAncestorStats(
        params.entityId,
        ancestors,
        maxDepth: maxDepth,
      );
    });
