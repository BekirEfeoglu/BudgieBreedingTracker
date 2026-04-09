part of 'mendelian_calculator.dart';

/// Wild-type allele identifier used in allele pair representations.
const _kWildtype = 'wildtype';

/// W chromosome identifier for sex-linked (ZW) inheritance.
/// Female birds are ZW; the W chromosome carries no color gene alleles.
const _kWChromosome = 'W';

/// Determines the two alleles a parent contributes at an allelic series locus.
///
/// Returns a list of two allele identifiers:
/// - [_kWildtype] for the wild-type allele
/// - mutation ID for the mutant allele
List<String> _getAllelesAtLocus(
  String locusId,
  Set<String> relevantMutIds,
  ParentGenotype parent,
) {
  final selectedAtLocus = parent.getMutationsAtLocus(locusId);

  if (selectedAtLocus.isEmpty) {
    return [_kWildtype, _kWildtype];
  }

  if (selectedAtLocus.length == 1) {
    final mutId = selectedAtLocus.first;
    final state = parent.getState(mutId);
    return switch (state) {
      AlleleState.visual => [mutId, mutId], // Homozygous
      AlleleState.carrier => [mutId, _kWildtype], // Heterozygous
      AlleleState.split => [mutId, _kWildtype],
      null => [_kWildtype, _kWildtype],
    };
  }

  // 2 mutations selected at same locus = compound heterozygote
  // (e.g., greywing + clearwing → Full-Body Greywing)
  // Only the first two are biologically meaningful (diploid organism).
  if (selectedAtLocus.length > 2) {
    AppLogger.warning(
      '[AlleleResolver] More than 2 mutations selected at locus $locusId: '
      '${selectedAtLocus.length} found, using first 2',
    );
  }
  return [selectedAtLocus[0], selectedAtLocus[1]];
}

/// Returns the mother's alleles at a sex-linked allelic series locus.
///
/// Mother (ZW) is hemizygous: one Z allele + W chromosome.
/// Unlike autosomal where she has two alleles, she contributes
/// either her Z allele or W to offspring.
List<String> _getSexLinkedMotherAllelesAtLocus(
  String locusId,
  Set<String> relevantMutIds,
  ParentGenotype mother,
) {
  final selectedAtLocus = mother.getMutationsAtLocus(locusId);

  if (selectedAtLocus.isEmpty) {
    return [_kWildtype, _kWChromosome];
  }

  // Female is hemizygous: only one Z allele at sex-linked loci
  final mutId = selectedAtLocus.first;
  final state = mother.getState(mutId);
  if (state != null) {
    return [mutId, _kWChromosome];
  }
  return [_kWildtype, _kWChromosome];
}

/// Sorts allelic pair into a canonical key for grouping.
String _sortAllelicPair(String a, String b) {
  if (a == _kWildtype && b != _kWildtype) return '$b|$a';
  if (b == _kWildtype && a != _kWildtype) return '$a|$b';
  if (a.compareTo(b) <= 0) return '$a|$b';
  return '$b|$a';
}

/// Resolves the phenotype from two alleles at an allelic series locus.
_AllelicPhenotypeResult _resolveAllelicPhenotype(
  String locusId,
  String allele1,
  String allele2,
) {
  // Both wild-type
  if (allele1 == _kWildtype && allele2 == _kWildtype) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Normal',
      genotype: '+/+',
      expressedIds: [],
      carriedIds: [],
    );
  }

  // One wild-type, one mutant
  if (allele1 == _kWildtype || allele2 == _kWildtype) {
    final mutant = allele1 == _kWildtype ? allele2 : allele1;
    final record = MutationDatabase.getById(mutant);
    final sym = record?.alleleSymbol ?? mutant;

    // Dominant / incomplete dominant: heterozygote is visually expressed
    if (record != null &&
        (record.inheritanceType == InheritanceType.autosomalDominant ||
         record.inheritanceType == InheritanceType.autosomalIncompleteDominant)) {
      final name = record.name;
      return _AllelicPhenotypeResult(
        phenotype: name,
        genotype: '$sym/+',
        expressedIds: [mutant],
        carriedIds: const [],
      );
    }

    // Recessive: wild-type is dominant, mutant is carried
    return _AllelicPhenotypeResult(
      phenotype: 'Normal',
      isCarrier: true,
      genotype: '$sym/+',
      expressedIds: const [],
      carriedIds: [mutant],
    );
  }

  // Both same mutant: homozygous mutant
  if (allele1 == allele2) {
    final record = MutationDatabase.getById(allele1);
    final name = record?.name ?? allele1;
    final sym = record?.alleleSymbol ?? allele1;
    return _AllelicPhenotypeResult(
      phenotype: name,
      genotype: '$sym/$sym',
      expressedIds: [allele1],
      carriedIds: const [],
    );
  }

  // Compound heterozygote: two different mutants at same locus
  return _resolveCompoundHeterozygote(locusId, allele1, allele2);
}

/// Resolves phenotype for compound heterozygotes within allelic series.
_AllelicPhenotypeResult _resolveCompoundHeterozygote(
  String locusId,
  String allele1,
  String allele2,
) {
  final record1 = MutationDatabase.getById(allele1);
  final record2 = MutationDatabase.getById(allele2);
  final sym1 = record1?.alleleSymbol ?? allele1;
  final sym2 = record2?.alleleSymbol ?? allele2;
  final rank1 = record1?.dominanceRank ?? 0;
  final rank2 = record2?.dominanceRank ?? 0;

  // Dilution locus specific interactions
  if (locusId == GeneticsConstants.locusDilution) {
    return _resolveDilutionCompound(allele1, allele2, sym1, sym2, rank1, rank2);
  }

  // Blue series locus specific interactions
  if (locusId == GeneticsConstants.locusBlueSeries) {
    return _resolveBlueSeriesCompound(
      allele1,
      allele2,
      sym1,
      sym2,
      rank1,
      rank2,
    );
  }

  // Ino locus specific interactions
  if (locusId == GeneticsConstants.locusIno) {
    return _resolveInoCompound(allele1, allele2, sym1, sym2, rank1, rank2);
  }

  // Generic: higher rank dominates
  if (rank1 > rank2) {
    return _AllelicPhenotypeResult(
      phenotype: record1?.name ?? allele1,
      genotype: '$sym1/$sym2',
      expressedIds: [allele1],
      carriedIds: [allele2],
    );
  }
  if (rank2 > rank1) {
    return _AllelicPhenotypeResult(
      phenotype: record2?.name ?? allele2,
      genotype: '$sym2/$sym1',
      expressedIds: [allele2],
      carriedIds: [allele1],
    );
  }

  // Equal rank: codominant display
  final name1 = record1?.name ?? allele1;
  final name2 = record2?.name ?? allele2;
  return _AllelicPhenotypeResult(
    phenotype: '$name1 / $name2',
    genotype: '$sym1/$sym2',
    expressedIds: [allele1, allele2],
    carriedIds: const [],
  );
}

/// Resolves the compound phenotype name when both linked mutations are visual.
String _resolveLinkedCompoundName(
  String id1,
  String id2,
  String name1,
  String name2,
) {
  final ids = {id1, id2};
  if (ids.contains(GeneticsConstants.mutCinnamon) &&
      ids.contains(GeneticsConstants.mutIno)) {
    return 'Lacewing';
  }
  final names = [name1, name2]..sort();
  return names.join(' ');
}

/// Returns allele pair for autosomal recessive.
/// visual(aa)=[a,a], carrier(Aa)=[A,a], absent(AA)=[A,A]
List<String> _getAllelePair(AlleleState? state) {
  return switch (state) {
    AlleleState.visual => ['a', 'a'],
    AlleleState.carrier => ['A', 'a'],
    AlleleState.split => ['A', 'a'], // treat as carrier
    null => ['A', 'A'],
  };
}

/// Returns allele pair for autosomal dominant.
/// visual = homozygous [A,A] (double copy),
/// carrier = heterozygous [A,a] (single copy),
/// absent = wild type [a,a].
List<String> _getDominantAllelePair(AlleleState? state) {
  return switch (state) {
    AlleleState.visual => ['A', 'A'], // Homozygous (double copy)
    AlleleState.carrier => ['A', 'a'], // Heterozygous (single copy)
    AlleleState.split => ['A', 'a'], // treat as single copy
    null => ['a', 'a'], // Wild type
  };
}

/// Returns allele pair for incomplete dominant.
/// visual = homozygous [A,A] (double factor / DF),
/// carrier = heterozygous [A,a] (single factor / SF),
/// absent = wild type [a,a].
List<String> _getIncompleteDominantAllelePair(AlleleState? state) {
  return switch (state) {
    AlleleState.visual => ['A', 'A'], // DF (homozygous)
    AlleleState.carrier => ['A', 'a'], // SF (heterozygous)
    AlleleState.split => ['A', 'a'], // treat as SF
    null => ['a', 'a'], // wild type
  };
}

/// Sorts allele pair for consistent genotype keys.
/// Capital (dominant) alleles come first: 'A' before 'a'.
String _sortAlleles(String a, String b) {
  final aIsUpper = a.isNotEmpty && a.codeUnitAt(0) < 97; // A-Z = 65-90
  final bIsUpper = b.isNotEmpty && b.codeUnitAt(0) < 97;
  if (aIsUpper && !bIsUpper) return '$a$b';
  if (bIsUpper && !aIsUpper) return '$b$a';
  return '$a$b';
}

/// Returns human-readable name for an allele ID.
String _alleleDisplayName(String alleleId) {
  if (alleleId == _kWildtype) return '+';
  if (alleleId == _kWChromosome) return _kWChromosome;
  final record = MutationDatabase.getById(alleleId);
  return record?.alleleSymbol ?? alleleId;
}
