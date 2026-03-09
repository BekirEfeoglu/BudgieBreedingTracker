/// Inheritance type for budgie mutations.
enum InheritanceType {
  autosomalRecessive,
  autosomalDominant,
  autosomalIncompleteDominant,
  sexLinkedRecessive,
  /// Codominant sex-linked inheritance.
  /// Reserved for future mutations where both alleles on Z are
  /// independently expressed (no known budgie mutation uses this yet).
  sexLinkedCodominant;

  /// Human-readable label key.
  String get labelKey => switch (this) {
    InheritanceType.autosomalRecessive => 'genetics.autosomal_recessive',
    InheritanceType.autosomalDominant => 'genetics.autosomal_dominant',
    InheritanceType.autosomalIncompleteDominant => 'genetics.autosomal_incomplete_dominant',
    InheritanceType.sexLinkedRecessive => 'genetics.sex_linked_recessive',
    InheritanceType.sexLinkedCodominant => 'genetics.sex_linked_codominant',
  };

  /// Short badge abbreviation for UI display.
  String get badge => switch (this) {
    InheritanceType.autosomalRecessive => 'AR',
    InheritanceType.autosomalDominant => 'AD',
    InheritanceType.autosomalIncompleteDominant => 'AID',
    InheritanceType.sexLinkedRecessive => 'SLR',
    InheritanceType.sexLinkedCodominant => 'SLC',
  };
}

/// Dominance pattern for a mutation allele.
enum Dominance {
  dominant,
  recessive,
  incompleteDominant,
  codominant;
}

/// Detailed budgie mutation record in the reference catalog.
class BudgieMutationRecord {
  final String id;
  final String name;
  final String localizationKey;
  final String description;
  final InheritanceType inheritanceType;
  final Dominance dominance;
  final String alleleSymbol;
  final List<String> alleles;
  final String category;
  final String? visualEffect;

  /// Locus group ID for allelic series. Mutations sharing the same [locusId]
  /// are alleles of the same gene (e.g., greywing/clearwing/dilute = 'dilution').
  /// null = independent locus (standard single-gene mutation).
  final String? locusId;

  /// Dominance rank within an allelic series. Higher = more dominant.
  /// Wild-type (+) is implicitly the highest rank.
  /// Only meaningful when [locusId] is non-null. 0 = default.
  final int dominanceRank;

  const BudgieMutationRecord({
    required this.id,
    required this.name,
    required this.localizationKey,
    required this.description,
    required this.inheritanceType,
    required this.dominance,
    required this.alleleSymbol,
    required this.alleles,
    required this.category,
    this.visualEffect,
    this.locusId,
    this.dominanceRank = 0,
  });

  bool get isSexLinked =>
      inheritanceType == InheritanceType.sexLinkedRecessive ||
      inheritanceType == InheritanceType.sexLinkedCodominant;

  bool get isAutosomal => !isSexLinked;
}
