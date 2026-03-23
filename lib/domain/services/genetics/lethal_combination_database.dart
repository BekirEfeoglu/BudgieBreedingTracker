import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';

export 'package:budgie_breeding_tracker/domain/services/genetics/viability_analyzer.dart';

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
    // ── Crested × Crested (Embryonic Lethal for DF) ──
    // Classical genetics: homozygous crested (DF) is embryonic lethal.
    // 25% of Crested × Crested offspring die in shell.
    LethalCombination(
      id: 'df_crested',
      nameKey: 'genetics.lethal_df_crested_name',
      descriptionKey: 'genetics.lethal_df_crested_desc',
      severity: LethalSeverity.lethal,
      affectedRate: 0.25,
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

    // ── Double Factor Dominant Pied (Semi-Lethal) ──
    // DF Dominant (Australian) Pied has significantly reduced viability.
    // Dominant Pied × Dominant Pied → 25% DF with elevated mortality.
    LethalCombination(
      id: 'df_dominant_pied',
      nameKey: 'genetics.lethal_df_dominant_pied_name',
      descriptionKey: 'genetics.lethal_df_dominant_pied_desc',
      severity: LethalSeverity.semiLethal,
      affectedRate: 1.0,
      requiredMutationIds: {'dominant_pied'},
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
      requiredMutationIds: {GeneticsConstants.mutIno},
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

