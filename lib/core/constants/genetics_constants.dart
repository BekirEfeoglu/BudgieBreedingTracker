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

  /// Ino locus on Z chromosome (WBO/MUTAVI hierarchy, guide §176-182 / K7).
  /// SIMPLE dominance runs: ino+ > Texas Clearbody (tcb) > Pearly (prl) >
  /// Ino (ino). Pallid (pal) is NOT a linear link in that chain — it
  /// CO-EXPRESSES with the other alleles (pal+ino → PallidIno/Lacewing,
  /// pal+prl → Pallid Pearly, …), resolved via explicit compound rules in
  /// `allele_resolver_compounds.dart`; pallid's linear `dominanceRank`
  /// (`mutation_data_sex_linked.dart`) is a fallback that is never reached.
  static const String locusIno = 'ino_locus';

  /// Crested locus: tufted / half-circular / full-circular alleles.
  /// The double-factor (homozygous) crested subset is classified
  /// `LethalSeverity.subVital` in `lethal_combination_database.dart` (v6, 2026-
  /// 07-10) to match the cited source MUTAVI K10 ("Crest: A Subvital
  /// Character"). Only the ~25% DF subset is flagged, not every crested pairing.
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
  ///
  /// v4 (2026-07-02): full-dominant allelic-series homozygotes are tagged
  /// "(double)" so the double-factor subset is a distinct offspring result
  /// instead of merging with single-factor birds. This splits e.g. crested ×
  /// crested into a separate ~25% DF result (correctly flagged as DF-lethal),
  /// changing the offspring set for crested crosses.
  ///
  /// v5 (2026-07-09): the multi-locus combiner no longer collapses the
  /// homozygous double-factor subset into the single-factor phenotype group.
  /// Previously the epistasis compound name was identical for homo/heterozygous
  /// dominant, so they merged into one key and the doubleFactorIds tag was
  /// overwritten/lost — silently dropping EVERY offspringHomozygous lethal
  /// (crested, DF spangle, feather duster, DF dominant pied) in any multi-locus
  /// cross. The DF subset is now a distinct "(double factor)" result keyed by
  /// its exact double-factor set, so those lethal/semi-lethal warnings fire in
  /// multi-locus crosses and their affected probability is the true ~25% subset.
  ///
  /// v6 (2026-07-10): viability audit aligned the lethal/sub-vital set with the
  /// cited MUTAVI sources. `df_crested` downgraded lethal → sub-vital (MUTAVI
  /// K10 titles crest "A Subvital Character"); the false-positive sub-vital
  /// warnings on healthy homozygous pairings — `df_spangle`, `ino_x_ino`,
  /// `pallid_x_pallid`, `texas_clearbody_x_texas_clearbody` — were removed. The
  /// ino-locus alleles Pearly/Pallid are no longer listed as "masked by Ino"
  /// (they co-express/resolve via the allelic-series resolver). These change the
  /// viability warning set/severity and the maskedMutations output.
  ///
  /// v7 (2026-07-10): Ino now masks the melanin-based pattern mutations
  /// Blackface, Saddleback, Mottled and Faded in the phenotype name (they are
  /// erased by ino's full melanin removal), reporting them via maskedMutations
  /// like Opaline/Cinnamon. Crest stays unmasked (feather structure). Pied /
  /// Fallow / Clearbody are intentionally left unmasked (debatable). Changes the
  /// phenotype name + maskedMutations output for ino + these patterns.
  ///
  /// v8 (2026-07-10): removed the `df_dominant_pied` semi-lethal viability
  /// warning. DF Australian Dominant Pied is a viable, commonly bred variety
  /// (the double factor just shows more extensive pied markings); the prior
  /// "reduced viability" warning was unsourced and failed the same v6 criterion
  /// applied to DF Spangle / Ino×Ino / Pallid / Texas Clearbody — the cited
  /// MUTAVI guide does NOT flag it. Changes the viability warning set.
  static const int calculationVersion = 8;

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
