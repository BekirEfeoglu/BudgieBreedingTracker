import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
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

    // Find highest severity
    final highestSeverity = warnings
        .map((w) => w.combination.severity)
        .reduce((a, b) => a.index <= b.index ? a : b);

    // Sum affected probabilities with combination-specific impact rate.
    final totalAffected = warnings
        .fold(
          0.0,
          (sum, w) =>
              sum + (w.offspring.probability * w.combination.affectedRate),
        )
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
    final warnings = <ViabilityWarning>[];

    // Special case: Ino x Ino — check parent-level
    if (combo.id == 'ino_x_ino') {
      final fatherHasIno =
          fatherMutations.contains(GeneticsConstants.mutIno);
      final motherHasIno =
          motherMutations.contains(GeneticsConstants.mutIno);
      if (fatherHasIno && motherHasIno) {
        // All offspring are affected when both parents are visual Ino
        for (final result in offspringResults) {
          warnings.add(ViabilityWarning(combination: combo, offspring: result));
        }
      }
      return warnings;
    }

    // Special case: Crested x Crested — pairing-level sub-vital risk.
    if (combo.id == 'df_crested') {
      final fatherHasCrested = combo.requiredMutationIds.any(
        fatherMutations.contains,
      );
      final motherHasCrested = combo.requiredMutationIds.any(
        motherMutations.contains,
      );
      if (fatherHasCrested && motherHasCrested) {
        for (final result in offspringResults) {
          warnings.add(ViabilityWarning(combination: combo, offspring: result));
        }
      }
      return warnings;
    }

    // Homozygous check: use structural doubleFactorIds from OffspringResult
    if (combo.requiresHomozygous) {
      final fatherHas = combo.requiredMutationIds.any(fatherMutations.contains);
      final motherHas = combo.requiredMutationIds.any(motherMutations.contains);

      if (fatherHas && motherHas) {
        for (final result in offspringResults) {
          final hasDF = combo.requiredMutationIds.any(
            result.doubleFactorIds.contains,
          );
          if (hasDF) {
            warnings.add(
              ViabilityWarning(combination: combo, offspring: result),
            );
          }
        }
      }
      return warnings;
    }

    // Standard check: all required mutations present in offspring
    for (final result in offspringResults) {
      final offspringVisual = result.visualMutations.toSet();
      if (combo.requiredMutationIds.every(
        (id) => offspringVisual.contains(id),
      )) {
        warnings.add(ViabilityWarning(combination: combo, offspring: result));
      }
    }

    return warnings;
  }

}
