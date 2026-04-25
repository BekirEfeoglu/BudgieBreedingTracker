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
  /// ~32 cM apart, approximately 32% of gametes will be recombinant.
  /// Gene order on Z: Opaline — Cinnamon — Ino.
  /// Reference: MUTAVI, Crossing-over in the Sex-chromosome of the Male
  /// Budgerigar (sexchrom article).
  static const double opalineCinnamonRecombination = 0.32;

  /// Recombination rate between Opaline and Ino loci on the Z chromosome.
  ///
  /// ~30 cM apart, approximately 30% of gametes will be recombinant.
  /// Estimated from: Op–Cin (~32 cM) − Cin–Ino (~3 cM) ≈ 29–30 cM.
  /// Not directly measured in MUTAVI sexchrom article; derived from flanking
  /// distances.
  static const double opalineInoRecombination = 0.30;

  /// Recombination rate between Cinnamon and Slate loci on the Z chromosome.
  ///
  /// ~5 cM apart, approximately 5% of gametes will be recombinant.
  /// Gene order on Z: Opaline — Cinnamon — Ino — Slate.
  /// Reference: MUTAVI research data, test-mating studies.
  static const double cinnamonSlateRecombination = 0.05;

  /// Recombination rate between Opaline and Slate loci on the Z chromosome.
  ///
  /// ~40.5 cM apart, approximately 40.5% of gametes will be recombinant.
  /// Reference: MUTAVI, Crossing-over in the Sex-chromosome of the Male
  /// Budgerigar (sexchrom article).
  static const double opalineSlateRecombination = 0.405;

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

  // ── Modifier / pattern mutation IDs ──
  static const String mutBlackface = 'blackface';
  static const String mutSpangle = 'spangle';
  static const String mutViolet = 'violet';
  static const String mutDarkFactor = 'dark_factor';
  static const String mutGrey = 'grey';
  static const String mutGreywing = 'greywing';
  static const String mutClearwing = 'clearwing';
  static const String mutYellowfaceType1 = 'yellowface_type1';
  static const String mutYellowfaceType2 = 'yellowface_type2';
  static const String mutGoldenface = 'goldenface';
  static const String mutBlueFactor1 = 'bluefactor_1';
  static const String mutBlueFactor2 = 'bluefactor_2';

  // ── Dilution / Fallow / Pattern mutation IDs ──
  static const String mutDilute = 'dilute';
  static const String mutAnthracite = 'anthracite';
  static const String mutFallowEnglish = 'fallow_english';
  static const String mutFallowGerman = 'fallow_german';
  static const String mutFallowScottish = 'fallow_scottish';
  static const String mutSaddleback = 'saddleback';
  static const String mutDominantClearbody = 'dominant_clearbody';
  static const String mutFaded = 'faded';
  static const String mutMottled = 'mottled';
  static const String mutFeatherDuster = 'feather_duster';

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

  // ── Calculation version ──
  /// Increment whenever recombination constants or allele resolver logic
  /// changes in a way that would alter offspring results.
  /// Used to detect stale GeneticsHistory entries.
  ///
  /// v3 (2026-04-19): Z-chromosome linkage extended to all ino_locus alleles
  /// (pallid, pearly, texas_clearbody) with cinnamon/slate/opaline so that
  /// biologically linked sex-linked crosses return correct recombinant
  /// probabilities instead of treating them as independent loci.
  static const int calculationVersion = 3;

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
