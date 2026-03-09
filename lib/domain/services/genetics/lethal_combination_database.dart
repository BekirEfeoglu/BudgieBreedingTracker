import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';

/// Severity of a lethal allele combination.
enum LethalSeverity {
  /// Embryonic lethal — most offspring with this combo die before hatching.
  lethal,

  /// Semi-lethal — significantly reduced viability, many die young.
  semiLethal,

  /// Sub-vital — viable but weakened offspring with health issues.
  subVital;

  /// Localization key for severity label.
  String get labelKey => switch (this) {
    LethalSeverity.lethal => 'genetics.lethal_severity_lethal',
    LethalSeverity.semiLethal => 'genetics.lethal_severity_semi_lethal',
    LethalSeverity.subVital => 'genetics.lethal_severity_sub_vital',
  };
}

/// A known lethal or semi-lethal allele combination in budgies.
class LethalCombination {
  /// Unique identifier for this combination.
  final String id;

  /// Localization key for the combination name.
  final String nameKey;

  /// Localization key for detailed description.
  final String descriptionKey;

  /// The severity level of this combination.
  final LethalSeverity severity;

  /// Estimated mortality/weakness rate (0.0 to 1.0).
  /// For lethal: ~0.25 of offspring affected per Mendelian ratio.
  final double affectedRate;

  /// Mutation IDs that must ALL be present in an offspring's visual mutations
  /// for this combination to trigger. For homozygous checks, see [requiresHomozygous].
  final Set<String> requiredMutationIds;

  /// If true, the combination requires the mutation to be homozygous (double factor).
  /// Used for incomplete dominant mutations like Crested DF, Spangle DF.
  final bool requiresHomozygous;

  const LethalCombination({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.severity,
    required this.affectedRate,
    required this.requiredMutationIds,
    this.requiresHomozygous = false,
  });
}

/// Result of viability analysis for a single offspring prediction.
class ViabilityWarning {
  /// The lethal combination that was detected.
  final LethalCombination combination;

  /// The offspring result that triggered this warning.
  final OffspringResult offspring;

  const ViabilityWarning({required this.combination, required this.offspring});
}

/// Summary of lethal combination analysis for an entire cross result set.
class LethalAnalysisResult {
  /// Individual warnings per affected offspring.
  final List<ViabilityWarning> warnings;

  /// Overall highest severity found.
  final LethalSeverity? highestSeverity;

  /// Total probability of offspring affected by any lethal combination.
  final double totalAffectedProbability;

  const LethalAnalysisResult({
    required this.warnings,
    required this.highestSeverity,
    required this.totalAffectedProbability,
  });

  /// True if any lethal or semi-lethal combinations were detected.
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Database of known lethal and semi-lethal allele combinations in budgies.
///
/// References:
/// - MUTAVI research on crested sub-vital outcomes
/// - WBO breeding guidelines on Ino x Ino viability
/// - Standard aviculture literature on DF Spangle weakness
abstract class LethalCombinationDatabase {
  /// All known lethal/semi-lethal combinations.
  static const List<LethalCombination> allCombinations = [
    // ── Crested × Crested (Sub-vital Risk) ──
    // Recent aviculture references describe the crested factor as sub-vital:
    // elevated mortality and developmental/neurological issues can appear
    // in crested pairings, not only in classical DF outcomes.
    LethalCombination(
      id: 'df_crested',
      nameKey: 'genetics.lethal_df_crested_name',
      descriptionKey: 'genetics.lethal_df_crested_desc',
      severity: LethalSeverity.subVital,
      affectedRate: 0.48,
      requiredMutationIds: GeneticsConstants.crestedAlleleIds,
      requiresHomozygous: false,
    ),

    // ── Double Factor Spangle (Sub-vital) ──
    // DF Spangle birds are viable but often weaker with reduced feather quality.
    // Spangle x Spangle → 25% DF Spangle, 50% SF Spangle, 25% Normal.
    LethalCombination(
      id: 'df_spangle',
      nameKey: 'genetics.lethal_df_spangle_name',
      descriptionKey: 'genetics.lethal_df_spangle_desc',
      severity: LethalSeverity.subVital,
      affectedRate: 1.0,
      requiredMutationIds: {'spangle'},
      requiresHomozygous: true,
    ),

    // ── Visual Ino x Visual Ino (Semi-Lethal) ──
    // Both parents visual Ino → all offspring visual Ino.
    // Documented health issues: feather cysts, reduced immune function,
    // smaller size, higher chick mortality, eye problems.
    // The genetics guide explicitly warns against this combination.
    LethalCombination(
      id: 'ino_x_ino',
      nameKey: 'genetics.lethal_ino_x_ino_name',
      descriptionKey: 'genetics.lethal_ino_x_ino_desc',
      severity: LethalSeverity.semiLethal,
      affectedRate: 1.0,
      requiredMutationIds: {'ino'},
      requiresHomozygous: false,
    ),
  ];

  /// Find a combination by ID.
  static LethalCombination? getById(String id) {
    for (final combo in allCombinations) {
      if (combo.id == id) return combo;
    }
    return null;
  }
}

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
      final fatherHasIno = fatherMutations.contains('ino');
      final motherHasIno = motherMutations.contains('ino');
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

    // Homozygous check: look for "DF" or double factor indicators in phenotype
    if (combo.requiresHomozygous) {
      // Both parents must carry any mutation from the required set.
      // For crested: father has any crested variant AND mother has any crested variant.
      final fatherHas = combo.requiredMutationIds.any(fatherMutations.contains);
      final motherHas = combo.requiredMutationIds.any(motherMutations.contains);

      if (fatherHas && motherHas) {
        // DF offspring are possible — find them in results
        for (final result in offspringResults) {
          final phenotypeLower = result.phenotype.toLowerCase();
          final compoundLower = result.compoundPhenotype?.toLowerCase() ?? '';
          // Check for DF/double factor indicators using all mutation IDs
          final hasDF = combo.requiredMutationIds.any(
            (id) =>
                _isDoubleFactorPhenotype(phenotypeLower, id) ||
                _isDoubleFactorPhenotype(compoundLower, id),
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

  /// Checks if a phenotype string indicates a double factor (homozygous) state.
  ///
  /// Autosomal dominant uses "(homozygous)" suffix, while autosomal incomplete
  /// dominant uses "(double)" or "DF" prefix.
  bool _isDoubleFactorPhenotype(String phenotype, String mutationId) {
    return switch (mutationId) {
      'crested_tufted' || 'crested_half_circular' || 'crested_full_circular' =>
        (phenotype.contains('crested') && phenotype.contains('homozygous')) ||
            phenotype.contains('df crested') ||
            phenotype.contains('double factor crested'),
      'spangle' =>
        phenotype.contains('spangle') &&
            (phenotype.contains('double') || phenotype.contains('df spangle')),
      _ =>
        phenotype.contains('df $mutationId') ||
            (phenotype.contains(mutationId) &&
                phenotype.contains('homozygous')),
    };
  }
}
