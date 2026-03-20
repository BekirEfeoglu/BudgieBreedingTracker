import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';

typedef InbreedingData = ({
  double coefficient,
  InbreedingRisk risk,
  Set<String> commonAncestorIds,
});

/// Calculates inbreeding coefficient and common ancestor IDs for a bird.
InbreedingData calculateInbreedingForBird(
  String birdId,
  Map<String, Bird> ancestors,
) {
  const calculator = InbreedingCalculator();
  final coefficient = calculator.calculate(
    birdId: birdId,
    ancestors: ancestors,
  );
  final risk = calculator.assessRisk(coefficient);
  final commonIds = calculator.findCommonAncestors(
    birdId: birdId,
    ancestors: ancestors,
  );
  return (coefficient: coefficient, risk: risk, commonAncestorIds: commonIds);
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
      return calculateInbreedingForBird(params.entityId, ancestors);
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

  void countAncestors(String? id, int depth) {
    if (id == null || depth > maxDepth) return;
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
