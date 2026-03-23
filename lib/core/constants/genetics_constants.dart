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

  /// Recombination rate between Cinnamon and Slate loci on the Z chromosome.
  ///
  /// ~5 cM apart, approximately 5% of gametes will be recombinant.
  /// Gene order on Z: Opaline — Cinnamon — Ino — Slate.
  /// Reference: MUTAVI research data, test-mating studies.
  static const double cinnamonSlateRecombination = 0.05;

  /// Recombination rate between Opaline and Slate loci on the Z chromosome.
  ///
  /// ~40 cM apart, approximately 40% of gametes will be recombinant.
  /// Derived from gene order: O–C (34 cM) + C–S (5 cM) ≈ 39–40 cM.
  /// Reference: MUTAVI Z chromosome gene map.
  static const double opalineSlateRecombination = 0.40;

  /// Recombination rate between Ino and Slate loci on the Z chromosome.
  ///
  /// ~2 cM apart (estimated), approximately 2% of gametes will be
  /// recombinant. Derived from gene order: C–S (5 cM) − C–I (3 cM) ≈ 2 cM.
  /// Reference: Estimated from MUTAVI Z chromosome gene map distances.
  static const double inoSlateRecombination = 0.02;

  // ── Allelic series locus IDs ──
  /// Mutations sharing a locusId are alleles of the same gene.
  static const String locusDilution = 'dilution';
  static const String locusBlueSeries = 'blue_series';

  /// Ino locus on Z chromosome (WBO/MUTAVI hierarchy):
  /// ino+ > Texas Clearbody (tcb) > Pearly (prl) > Pallid (pal) > Ino (ino).
  static const String locusIno = 'ino_locus';

  /// Crested locus: tufted / half-circular / full-circular alleles.
  /// Crested pairings are treated as sub-vital risk in viability warnings.
  static const String locusCrested = 'crested';

  // ── Sex-linked mutation IDs ──
  static const String mutIno = 'ino';
  static const String mutCinnamon = 'cinnamon';
  static const String mutSlate = 'slate';
  static const String mutOpaline = 'opaline';
  static const String mutPallid = 'pallid';
  static const String mutPearly = 'pearly';
  static const String mutTexasClearbody = 'texas_clearbody';

  // ── Autosomal mutation IDs ──
  static const String mutBlue = 'blue';
  static const String mutAqua = 'aqua';
  static const String mutTurquoise = 'turquoise';

  // ── Pied mutation IDs ──
  static const String mutRecessivePied = 'recessive_pied';
  static const String mutClearflightPied = 'clearflight_pied';
  static const String mutDominantPied = 'dominant_pied';
  static const String mutDutchPied = 'dutch_pied';

  // ── Crested allele IDs ──
  static const String mutCrestedTufted = 'crested_tufted';
  static const String mutCrestedHalfCircular = 'crested_half_circular';
  static const String mutCrestedFullCircular = 'crested_full_circular';

  static const Set<String> crestedAlleleIds = {
    mutCrestedTufted,
    mutCrestedHalfCircular,
    mutCrestedFullCircular,
  };

  // ── ReverseCalculator limits ──
  /// Maximum parent genotype options evaluated per locus in reverse calculation.
  static const int reverseMaxOptionsPerLocus = 180;

  /// Maximum intermediate combinations during reverse calculation cross-product.
  static const int reverseMaxIntermediateCombinations = 3000;

  /// Maximum final combinations returned from reverse calculation.
  static const int reverseMaxFinalCombinations = 500;

  // ── Ancestor traversal ──
  /// Maximum recursion depth for pedigree ancestor collection.
  static const int maxAncestorDepth = 10;

  // ── Display limits ──
  /// Maximum number of reverse calculation results shown to the user.
  static const int reverseMaxDisplayResults = 25;

  // ── Probability thresholds ──
  /// Minimum probability for an offspring combination to survive early pruning.
  /// Below this, combinations are discarded during Cartesian product build.
  static const double probabilityPruningThreshold = 0.0005;

  /// Minimum probability for an offspring result to appear in the final list.
  /// Below this, results are filtered as numerical noise.
  static const double probabilityMinThreshold = 0.001;
}
