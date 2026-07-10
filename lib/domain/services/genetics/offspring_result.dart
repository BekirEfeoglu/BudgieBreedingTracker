part of 'mendelian_calculator.dart';

/// Sex category for offspring results.
enum OffspringSex { male, female, both }

/// Result of an offspring prediction calculation.
class OffspringResult {
  final String phenotype;
  final double probability;
  final OffspringSex sex;
  final bool isCarrier;
  final String? genotype;

  /// List of individual visual mutation IDs in this phenotype.
  final List<String> visualMutations;

  /// Compound phenotype name after epistasis resolution (e.g., "Albino").
  final String? compoundPhenotype;

  /// List of carried (non-visual) mutation IDs.
  final List<String> carriedMutations;

  /// List of mutations masked by epistasis (e.g., Ino masks Opaline).
  final List<String> maskedMutations;

  /// Lethal combination IDs affecting this offspring (empty = no risk).
  final List<String> lethalCombinationIds;

  /// Mutation IDs that are homozygous (double factor) in this offspring.
  /// Used by ViabilityAnalyzer for structural DF detection.
  final Set<String> doubleFactorIds;

  const OffspringResult({
    required this.phenotype,
    required this.probability,
    this.sex = OffspringSex.both,
    this.isCarrier = false,
    this.genotype,
    this.visualMutations = const [],
    this.compoundPhenotype,
    this.carriedMutations = const [],
    this.maskedMutations = const [],
    this.lethalCombinationIds = const [],
    this.doubleFactorIds = const {},
  });
}

/// Diagnostics about probability pruning during a multi-locus calculation.
///
/// The engine discards very-low-probability combinations while building the
/// multi-locus Cartesian product (to prevent combinatorial explosion) and then
/// normalizes the survivors to sum to 1.0. That normalization hides the fact
/// that some probability mass was dropped, so results can read as more certain
/// than they are. This carries the numbers the UI needs to warn honestly.
///
/// [none] means no combinatorial pruning happened — the result set is complete
/// (bar sub-0.1% numerical-noise filtering, which is expected and not counted).
class PruningDiagnostics {
  const PruningDiagnostics({
    this.wasPruned = false,
    this.prunedStateCount = 0,
    this.discardedProbabilityMassBeforeNormalization = 0.0,
    this.earlyPruningThreshold = GeneticsConstants.probabilityPruningThreshold,
    this.minResultThreshold = GeneticsConstants.probabilityMinThreshold,
    this.normalized = false,
  });

  /// True when the early combinatorial pruning discarded at least one state.
  final bool wasPruned;

  /// How many combination states the early pruning removed.
  final int prunedStateCount;

  /// Sum of the raw (pre-normalization) joint probabilities of the pruned
  /// states. Per-locus distributions each sum to ~1.0, so their product does
  /// too — this reads directly as "≈X% of the probability mass was dropped".
  final double discardedProbabilityMassBeforeNormalization;

  /// The early-pruning threshold applied (`probabilityPruningThreshold`).
  final double earlyPruningThreshold;

  /// The final min-result threshold applied (`probabilityMinThreshold`).
  final double minResultThreshold;

  /// Whether the returned probabilities were normalized to sum to 1.0.
  final bool normalized;

  /// No combinatorial pruning occurred.
  static const PruningDiagnostics none = PruningDiagnostics();
}

/// An offspring calculation paired with its [PruningDiagnostics].
///
/// [MendelianCalculator.calculateDetailed] returns this; the plain
/// [MendelianCalculator.calculateFromGenotypes] returns just [results] so its
/// output is byte-identical to before this diagnostic existed.
class OffspringCalculation {
  const OffspringCalculation({
    required this.results,
    required this.diagnostics,
  });

  final List<OffspringResult> results;
  final PruningDiagnostics diagnostics;

  /// An empty calculation with no pruning.
  static const OffspringCalculation empty = OffspringCalculation(
    results: [],
    diagnostics: PruningDiagnostics.none,
  );
}

/// Data for Punnett square visualization.
class PunnettSquareData {
  final String mutationName;
  final List<String> fatherAlleles;
  final List<String> motherAlleles;
  final List<List<String>> cells;
  final bool isSexLinked;

  const PunnettSquareData({
    required this.mutationName,
    required this.fatherAlleles,
    required this.motherAlleles,
    required this.cells,
    required this.isSexLinked,
  });
}

/// Internal raw result before combining.
class _RawResult {
  final String phenotype;
  final double probability;
  final OffspringSex sex;
  final bool isCarrier;
  final String? genotype;

  /// Mutation IDs visually expressed in this result.
  final List<String> expressedMutationIds;

  /// Mutation IDs carried but not visually expressed.
  final List<String> carriedMutationIds;

  /// Mutation IDs present in a double dose (two mutant alleles at one locus —
  /// homozygous or compound heterozygote). Used by [ViabilityAnalyzer] to flag
  /// double-factor lethal combinations for allelic-series mutations that don't
  /// carry a `(double)` phenotype string marker.
  final Set<String> doubleFactorIds;

  const _RawResult({
    required this.phenotype,
    required this.probability,
    this.sex = OffspringSex.both,
    this.isCarrier = false,
    this.genotype,
    this.expressedMutationIds = const [],
    this.carriedMutationIds = const [],
    this.doubleFactorIds = const {},
  });
}

/// Internal result for multi-locus combination.
class _MultiLocusResult {
  final List<String> phenotypes;
  final double probability;
  final OffspringSex sex;
  final List<String> carriedMutations;
  final List<String> genotypes;
  final List<String> expressedMutationIds;

  /// Mutation IDs present in a double dose across the combined loci.
  final Set<String> doubleFactorIds;

  const _MultiLocusResult({
    required this.phenotypes,
    required this.probability,
    required this.sex,
    required this.carriedMutations,
    required this.genotypes,
    this.expressedMutationIds = const [],
    this.doubleFactorIds = const {},
  });
}

/// Result of resolving a phenotype from two alleles at an allelic series locus.
class _AllelicPhenotypeResult {
  final String phenotype;
  final bool isCarrier;
  final String genotype;
  final List<String> expressedIds;
  final List<String> carriedIds;

  const _AllelicPhenotypeResult({
    required this.phenotype,
    this.isCarrier = false,
    required this.genotype,
    required this.expressedIds,
    required this.carriedIds,
  });
}

/// Gamete for linked sex-linked loci (e.g., Cinnamon-Ino, Opaline-Cinnamon).
class _LinkageGamete {
  final bool mut1;
  final bool mut2;
  final double prob;
  final bool isW;

  const _LinkageGamete({
    required this.mut1,
    required this.mut2,
    required this.prob,
    this.isW = false,
  });
}
