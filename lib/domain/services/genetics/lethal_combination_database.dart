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
  /// `offspringHomozygous` uses the first ID for a double-factor offspring
  /// check, and `offspringVisual` requires every ID to appear in offspring
  /// visuals.
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
    // ── Crested × Crested (Sub-Vital for DF) ──
    // The app's cited source, MUTAVI K10 ("Crest: A Subvital Character in the
    // Budgerigar"), classifies crest as SUB-VITAL — associated with embryo loss
    // and neurological issues but not strictly 100% lethal. Only the ~25% of
    // offspring that inherit two crest-locus alleles (DF, whether homozygous or
    // a compound of two crest alleles) are affected, so this uses offspring-
    // level homozygous scope (affectedRate 1.0 over that DF subset) rather than
    // flagging every offspring of a crested pairing. Downgraded from `lethal`
    // 2026-07-10 to match the cited source (v6).
    LethalCombination(
      id: 'df_crested',
      nameKey: 'genetics.lethal_df_crested_name',
      descriptionKey: 'genetics.lethal_df_crested_desc',
      severity: LethalSeverity.subVital,
      affectedRate: 1.0,
      requiredMutationIds: GeneticsConstants.crestedAlleleIds,
      scope: LethalScope.offspringHomozygous,
    ),

    // NOTE: Double Factor Spangle was removed as a viability warning
    // (2026-07-10, v6). DF Spangle birds are fully viable, commonly bred
    // all-yellow/all-white birds; any reduced feather quality is cosmetic, not
    // a fitness/survival concern, so a sub-vital warning over-stated the risk.

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

    // NOTE: Ino × Ino was removed as a viability warning (2026-07-10, v6).
    // Lutino/Albino budgies are a standard, healthy, widely-bred variety and
    // Ino × Ino simply yields more Ino offspring; there is no established
    // sub-vital effect for budgie ino homozygosity, and the cited guide does
    // NOT warn against this pairing (an earlier comment mis-attributed it).
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

    // NOTE: Pallid × Pallid and Texas Clearbody × Texas Clearbody were removed
    // as viability warnings (2026-07-10, v6) for the same reason as Ino × Ino —
    // these ino-locus alleles are viable in the homozygous state and the cited
    // source does not flag their homozygosity as sub-vital.
  ];

  /// Find a combination by ID.
  static LethalCombination? getById(String id) {
    for (final combo in allCombinations) {
      if (combo.id == id) return combo;
    }
    return null;
  }
}
