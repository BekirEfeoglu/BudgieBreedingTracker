import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';

/// Analyzes offspring results for lethal allele combinations.
class ViabilityAnalyzer {
  const ViabilityAnalyzer();

  /// Analyzes a set of offspring results for lethal combinations.
  ///
  /// [fatherMutations] and [motherMutations] are the parent visual mutation sets,
  /// needed to detect parent-level combinations (like Ino x Ino).
  /// [offspringResults] are the calculated offspring predictions.
  LethalAnalysisResult analyze({
    required Set<String> fatherMutations,
    required Set<String> motherMutations,
    required List<OffspringResult> offspringResults,
  }) {
    final warnings = <ViabilityWarning>[];

    for (final combo in LethalCombinationDatabase.allCombinations) {
      final comboWarnings = _checkCombination(
        combo,
        fatherMutations: fatherMutations,
        motherMutations: motherMutations,
        offspringResults: offspringResults,
      );
      warnings.addAll(comboWarnings);
    }

    if (warnings.isEmpty) {
      return const LethalAnalysisResult(
        warnings: [],
        highestSeverity: null,
        totalAffectedProbability: 0.0,
      );
    }

    // Find highest severity — enum declares lethal < semiLethal < subVital, so
    // the lowest index wins.
    final highestSeverity = warnings
        .map((w) => w.combination.severity)
        .reduce((a, b) => a.index <= b.index ? a : b);

    // Aggregate affected probability per offspring so that an offspring hit by
    // multiple warnings does not contribute twice. We take the highest impact
    // (probability × affectedRate) because reduced viability from overlapping
    // causes is not additive — the worst cause dominates the outcome.
    final impactByOffspring = <OffspringResult, double>{};
    for (final w in warnings) {
      final impact = w.offspring.probability * w.combination.affectedRate;
      final current = impactByOffspring[w.offspring] ?? 0.0;
      if (impact > current) {
        impactByOffspring[w.offspring] = impact;
      }
    }
    final totalAffected = impactByOffspring.values
        .fold<double>(0.0, (sum, v) => sum + v)
        .clamp(0.0, 1.0);

    return LethalAnalysisResult(
      warnings: warnings,
      highestSeverity: highestSeverity,
      totalAffectedProbability: totalAffected,
    );
  }

  List<ViabilityWarning> _checkCombination(
    LethalCombination combo, {
    required Set<String> fatherMutations,
    required Set<String> motherMutations,
    required List<OffspringResult> offspringResults,
  }) {
    switch (combo.scope) {
      case LethalScope.parentBothVisual:
        return _checkParentBothVisual(combo, fatherMutations, motherMutations,
            offspringResults);
      case LethalScope.parentAnyVisual:
        return _checkParentAnyVisual(combo, fatherMutations, motherMutations,
            offspringResults);
      case LethalScope.offspringHomozygous:
        return _checkOffspringHomozygous(combo, fatherMutations, motherMutations,
            offspringResults);
      case LethalScope.offspringVisual:
        return _checkOffspringVisual(combo, offspringResults);
    }
  }

  List<ViabilityWarning> _checkParentBothVisual(
    LethalCombination combo,
    Set<String> fatherMutations,
    Set<String> motherMutations,
    List<OffspringResult> offspringResults,
  ) {
    // Both parents must visually express the single required mutation.
    final mutId = combo.requiredMutationIds.first;
    if (!fatherMutations.contains(mutId) || !motherMutations.contains(mutId)) {
      return const [];
    }
    return [
      for (final result in offspringResults)
        ViabilityWarning(combination: combo, offspring: result),
    ];
  }

  List<ViabilityWarning> _checkParentAnyVisual(
    LethalCombination combo,
    Set<String> fatherMutations,
    Set<String> motherMutations,
    List<OffspringResult> offspringResults,
  ) {
    // Each parent must visually express at least one allele from the set.
    final fatherHasAny =
        combo.requiredMutationIds.any(fatherMutations.contains);
    final motherHasAny =
        combo.requiredMutationIds.any(motherMutations.contains);
    if (!fatherHasAny || !motherHasAny) return const [];
    return [
      for (final result in offspringResults)
        ViabilityWarning(combination: combo, offspring: result),
    ];
  }

  List<ViabilityWarning> _checkOffspringHomozygous(
    LethalCombination combo,
    Set<String> fatherMutations,
    Set<String> motherMutations,
    List<OffspringResult> offspringResults,
  ) {
    // Short-circuit: if neither parent can contribute the allele, no offspring
    // can be homozygous for it.
    final fatherCanProvide =
        combo.requiredMutationIds.any(fatherMutations.contains);
    final motherCanProvide =
        combo.requiredMutationIds.any(motherMutations.contains);
    if (!fatherCanProvide || !motherCanProvide) return const [];

    final warnings = <ViabilityWarning>[];
    for (final result in offspringResults) {
      final hasDoubleFactor = combo.requiredMutationIds.any(
        result.doubleFactorIds.contains,
      );
      if (hasDoubleFactor) {
        warnings.add(ViabilityWarning(combination: combo, offspring: result));
      }
    }
    return warnings;
  }

  List<ViabilityWarning> _checkOffspringVisual(
    LethalCombination combo,
    List<OffspringResult> offspringResults,
  ) {
    // Offspring must visually express every required mutation.
    final warnings = <ViabilityWarning>[];
    for (final result in offspringResults) {
      final visual = result.visualMutations.toSet();
      if (combo.requiredMutationIds.every(visual.contains)) {
        warnings.add(ViabilityWarning(combination: combo, offspring: result));
      }
    }
    return warnings;
  }
}
