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
  });
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

  const _RawResult({
    required this.phenotype,
    required this.probability,
    this.sex = OffspringSex.both,
    this.isCarrier = false,
    this.genotype,
    this.expressedMutationIds = const [],
    this.carriedMutationIds = const [],
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

  const _MultiLocusResult({
    required this.phenotypes,
    required this.probability,
    required this.sex,
    required this.carriedMutations,
    required this.genotypes,
    this.expressedMutationIds = const [],
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
