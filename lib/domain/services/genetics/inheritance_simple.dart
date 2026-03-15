part of 'mendelian_calculator.dart';

// ---------------------------------------------------------------------------
// Simple set-based inheritance (calculateOffspring flow)
// ---------------------------------------------------------------------------

/// Calculates autosomal inheritance outcomes for a single locus.
List<_RawResult> _calculateAutosomal(
  BudgieMutationRecord record,
  bool inFather,
  bool inMother,
) {
  final results = <_RawResult>[];

  switch (record.inheritanceType) {
    case InheritanceType.autosomalRecessive:
      results.addAll(_autosomalRecessive(record, inFather, inMother));
    case InheritanceType.autosomalDominant:
      results.addAll(_autosomalDominant(record, inFather, inMother));
    case InheritanceType.autosomalIncompleteDominant:
      results.addAll(_autosomalIncompleteDominant(record, inFather, inMother));
    case InheritanceType.sexLinkedRecessive:
    case InheritanceType.sexLinkedCodominant:
      break; // Handled separately
  }

  return results;
}

/// Autosomal recessive: Aa x Aa = 25% AA + 50% Aa + 25% aa
/// Both parents assumed heterozygous carriers if only one has the mutation,
/// homozygous if both have it.
List<_RawResult> _autosomalRecessive(
  BudgieMutationRecord record,
  bool inFather,
  bool inMother,
) {
  final name = record.name;
  final sym = record.alleleSymbol;

  if (inFather && inMother) {
    // Both homozygous: aa x aa = 100% aa (visual)
    return [
      _RawResult(
        phenotype: name,
        probability: 1.0,
        genotype: '$sym/$sym',
        expressedMutationIds: [record.id],
      ),
    ];
  }

  // One parent homozygous, other assumed carrier (heterozygous):
  // aa x Aa = 50% aa (visual) + 50% Aa (carrier)
  return [
    _RawResult(
      phenotype: name,
      probability: 0.50,
      genotype: '$sym/$sym',
      expressedMutationIds: [record.id],
    ),
    _RawResult(
      phenotype: '$name (carrier)',
      probability: 0.50,
      isCarrier: true,
      genotype: '$sym+/$sym',
      carriedMutationIds: [record.id],
    ),
  ];
}

/// Autosomal dominant: Aa x aa = 50% Aa (visual) + 50% aa (normal)
List<_RawResult> _autosomalDominant(
  BudgieMutationRecord record,
  bool inFather,
  bool inMother,
) {
  final name = record.name;
  final sym = record.alleleSymbol;

  if (inFather && inMother) {
    // Aa x Aa = 25% AA + 50% Aa + 25% aa
    return [
      _RawResult(
        phenotype: '$name (homozygous)',
        probability: 0.25,
        genotype: '$sym/$sym',
        expressedMutationIds: [record.id],
      ),
      _RawResult(
        phenotype: name,
        probability: 0.50,
        genotype: '$sym+/$sym',
        expressedMutationIds: [record.id],
      ),
      _RawResult(
        phenotype: 'Normal',
        probability: 0.25,
        genotype: '$sym+/$sym+',
      ),
    ];
  }

  // Aa x aa = 50% Aa + 50% aa
  return [
    _RawResult(
      phenotype: name,
      probability: 0.50,
      genotype: '$sym+/$sym',
      expressedMutationIds: [record.id],
    ),
    _RawResult(
      phenotype: 'Normal',
      probability: 0.50,
      genotype: '$sym+/$sym+',
    ),
  ];
}

/// Autosomal incomplete dominant: Dd x Dd = 25% DD + 50% Dd + 25% dd
/// Three distinct phenotypes (e.g., Dark Factor: 0/1/2 copies).
List<_RawResult> _autosomalIncompleteDominant(
  BudgieMutationRecord record,
  bool inFather,
  bool inMother,
) {
  final name = record.name;
  final sym = record.alleleSymbol;

  if (inFather && inMother) {
    // Dd x Dd = 25% DD + 50% Dd + 25% dd
    return [
      _RawResult(
        phenotype: '$name (double)',
        probability: 0.25,
        genotype: '$sym/$sym',
        expressedMutationIds: [record.id],
      ),
      _RawResult(
        phenotype: '$name (single)',
        probability: 0.50,
        genotype: '$sym+/$sym',
        expressedMutationIds: [record.id],
      ),
      _RawResult(
        phenotype: 'Normal',
        probability: 0.25,
        genotype: '$sym+/$sym+',
      ),
    ];
  }

  // Dd x dd = 50% Dd + 50% dd
  return [
    _RawResult(
      phenotype: '$name (single)',
      probability: 0.50,
      genotype: '$sym+/$sym',
      expressedMutationIds: [record.id],
    ),
    _RawResult(
      phenotype: 'Normal',
      probability: 0.50,
      genotype: '$sym+/$sym+',
    ),
  ];
}

/// Sex-linked recessive inheritance.
///
/// In budgies: males are ZZ, females are ZW.
/// Sex-linked mutations are on the Z chromosome.
///
/// Father (ZZ): if visual = Z*Z*, if carrier not possible for hemizygous
/// Mother (ZW): if visual = Z*W (hemizygous, always visual if has allele)
List<_RawResult> _calculateSexLinked(
  BudgieMutationRecord record,
  bool inFather,
  bool inMother,
) {
  final name = record.name;
  final sym = record.alleleSymbol;

  if (inFather && inMother) {
    // Father Z*Z* x Mother Z*W = all offspring carry/express
    // Male sons: Z*Z* (100% visual)
    // Female daughters: Z*W (100% visual)
    return [
      _RawResult(
        phenotype: name,
        probability: 0.50,
        sex: OffspringSex.male,
        genotype: 'Z${sym}Z$sym',
        expressedMutationIds: [record.id],
      ),
      _RawResult(
        phenotype: name,
        probability: 0.50,
        sex: OffspringSex.female,
        genotype: 'Z${sym}W',
        expressedMutationIds: [record.id],
      ),
    ];
  }

  if (inFather && !inMother) {
    // Father Z*Z* x Mother Z+W
    // Male sons: Z*Z+ (100% carrier, not visual)
    // Female daughters: Z*W (100% visual)
    return [
      _RawResult(
        phenotype: '$name (carrier)',
        probability: 0.50,
        sex: OffspringSex.male,
        isCarrier: true,
        genotype: 'Z${sym}Z+',
        carriedMutationIds: [record.id],
      ),
      _RawResult(
        phenotype: name,
        probability: 0.50,
        sex: OffspringSex.female,
        genotype: 'Z${sym}W',
        expressedMutationIds: [record.id],
      ),
    ];
  }

  if (!inFather && inMother) {
    // Father Z+Z+ x Mother Z*W
    // Male sons: Z+Z* (50% carrier) or Z+Z+ (50% normal)
    // Female daughters: Z+W (100% normal)
    // Simplified: Father assumed Z+Z+ (no mutation allele)
    return [
      _RawResult(
        phenotype: '$name (carrier)',
        probability: 0.50,
        sex: OffspringSex.male,
        isCarrier: true,
        genotype: 'Z+Z$sym',
        carriedMutationIds: [record.id],
      ),
      const _RawResult(
        phenotype: 'Normal',
        probability: 0.50,
        sex: OffspringSex.female,
        genotype: 'Z+W',
      ),
    ];
  }

  return const [];
}
