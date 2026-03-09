/// Constants for budgie genetics calculations.
abstract final class GeneticsConstants {
  // ── Inbreeding thresholds (coefficient of kinship) ──
  static const double inbreedingMinimal = 0.0625;
  static const double inbreedingLow = 0.125;
  static const double inbreedingModerate = 0.25;
  static const double inbreedingHigh = 0.375;
  static const double inbreedingCritical = 0.5;

  // ── Recombination rates ──

  /// Recombination rate between Cinnamon and Ino loci on the Z chromosome.
  ///
  /// These two sex-linked recessive genes are ~3 cM apart, meaning
  /// approximately 3% of gametes will be recombinant (crossover).
  /// Reference: Warner & Daniels (1/36 ≈ 2.8%), MUTAVI research data.
  static const double cinnamonInoRecombination = 0.03;

  /// Recombination rate between Opaline and Cinnamon loci on the Z chromosome.
  ///
  /// ~34 cM apart, approximately 34% of gametes will be recombinant.
  /// Gene order on Z: Opaline — Cinnamon — Ino.
  /// Reference: MUTAVI/WBO Z chromosome gene map.
  static const double opalineCinnamonRecombination = 0.34;

  /// Recombination rate between Opaline and Ino loci on the Z chromosome.
  ///
  /// ~30 cM apart, approximately 30% of gametes will be recombinant.
  /// Reference: MUTAVI/WBO Z chromosome gene map.
  static const double opalineInoRecombination = 0.30;

  // ── Allelic series locus IDs ──
  /// Mutations sharing a locusId are alleles of the same gene.
  static const String locusDilution = 'dilution';
  static const String locusBlueSeries = 'blue_series';

  /// Ino locus on Z chromosome:
  /// ino+ > pallid > ino^cl (Texas Clearbody) > ino.
  static const String locusIno = 'ino_locus';

  /// Crested locus: tufted / half-circular / full-circular alleles.
  /// Crested pairings are treated as sub-vital risk in viability warnings.
  static const String locusCrested = 'crested';

  // ── Crested allele IDs ──
  static const Set<String> crestedAlleleIds = {
    'crested_tufted',
    'crested_half_circular',
    'crested_full_circular',
  };
}
