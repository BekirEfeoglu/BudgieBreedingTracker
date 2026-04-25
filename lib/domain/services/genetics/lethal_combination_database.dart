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

/// Which layer of the pairing triggers a lethal combination warning.
enum LethalScope {
  /// Both parents must visually express the single required mutation, and
  /// every offspring is flagged as affected (e.g. Ino × Ino, Pallid × Pallid).
  parentBothVisual,

  /// Each parent must visually express at least one mutation from the set
  /// (e.g. any Crested allele × any Crested allele).
  parentAnyVisual,

  /// An individual offspring must be homozygous (double factor) for the
  /// required mutation (e.g. DF Spangle, DF Dominant Pied, Feather Duster).
  offspringHomozygous,

  /// An individual offspring must visually express every required mutation.
  /// Used for classic compound phenotype warnings.
  offspringVisual,
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

  /// Mutation IDs involved in this combination. Interpretation depends on
  /// [scope]: `parentBothVisual` uses the first ID for each parent check,
  /// `parentAnyVisual` matches any allele from the set, `offspringHomozygous`
  /// uses the first ID for a double-factor offspring check, and
  /// `offspringVisual` requires every ID to appear in offspring visuals.
  final Set<String> requiredMutationIds;

  /// Which layer of the pairing triggers the warning — parent-level or
  /// offspring-level, and whether the match is homozygous, every-visual, or
  /// any-visual.
  final LethalScope scope;

  const LethalCombination({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.severity,
    required this.affectedRate,
    required this.requiredMutationIds,
    this.scope = LethalScope.offspringVisual,
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
      scope: LethalScope.parentAnyVisual,
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
      requiredMutationIds: {GeneticsConstants.mutSpangle},
      scope: LethalScope.offspringHomozygous,
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
      requiredMutationIds: {GeneticsConstants.mutDominantPied},
      scope: LethalScope.offspringHomozygous,
    ),

    // ── Visual Ino x Visual Ino (Sub-Vital) ──
    // Both parents visual Ino → all offspring visual Ino.
    // Documented health issues: feather cysts, reduced immune function,
    // smaller size, higher chick mortality, eye problems.
    // Classified as sub-vital rather than semi-lethal: offspring are viable
    // but with reduced fitness. The genetics guide warns against this combination.
    LethalCombination(
      id: 'ino_x_ino',
      nameKey: 'genetics.lethal_ino_x_ino_name',
      descriptionKey: 'genetics.lethal_ino_x_ino_desc',
      severity: LethalSeverity.subVital,
      affectedRate: 1.0,
      requiredMutationIds: {GeneticsConstants.mutIno},
      scope: LethalScope.parentBothVisual,
    ),
    // ── Feather Duster (Lethal) ──
    // Homozygous feather duster (fdu/fdu) is invariably lethal.
    // Affected chicks have continuously growing, curly feathers and rarely
    // survive beyond a few months. Both parents must carry the gene.
    LethalCombination(
      id: 'df_feather_duster',
      nameKey: 'genetics.lethal_feather_duster_name',
      descriptionKey: 'genetics.lethal_feather_duster_desc',
      severity: LethalSeverity.lethal,
      affectedRate: 1.0,
      requiredMutationIds: {GeneticsConstants.mutFeatherDuster},
      scope: LethalScope.offspringHomozygous,
    ),

    // ── Visual Pallid × Visual Pallid (Sub-Vital) ──
    // Pallid belongs to the same ino_locus as Ino but removes less melanin.
    // Homozygous Pallid offspring are viable but show reduced body melanin,
    // increased eye sensitivity, and somewhat lower vigour. Weaker effect
    // than full Ino but still flagged as sub-vital so breeders can plan
    // around the ino-locus homozygosity risk.
    LethalCombination(
      id: 'pallid_x_pallid',
      nameKey: 'genetics.lethal_pallid_x_pallid_name',
      descriptionKey: 'genetics.lethal_pallid_x_pallid_desc',
      severity: LethalSeverity.subVital,
      affectedRate: 1.0,
      requiredMutationIds: {GeneticsConstants.mutPallid},
      scope: LethalScope.parentBothVisual,
    ),

    // ── Visual Texas Clearbody × Visual Texas Clearbody (Sub-Vital) ──
    // Texas Clearbody is an ino_locus allele that reduces body melanin while
    // preserving wing markings. Homozygous offspring can exhibit eye and
    // immune issues analogous (though milder) to full Ino × Ino. Treated as
    // sub-vital to warn breeders about the ino-locus dosage effect.
    LethalCombination(
      id: 'texas_clearbody_x_texas_clearbody',
      nameKey: 'genetics.lethal_tcb_x_tcb_name',
      descriptionKey: 'genetics.lethal_tcb_x_tcb_desc',
      severity: LethalSeverity.subVital,
      affectedRate: 1.0,
      requiredMutationIds: {GeneticsConstants.mutTexasClearbody},
      scope: LethalScope.parentBothVisual,
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

