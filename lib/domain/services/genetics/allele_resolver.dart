part of 'mendelian_calculator.dart';

/// Determines the two alleles a parent contributes at an allelic series locus.
///
/// Returns a list of two allele identifiers:
/// - 'wildtype' for the wild-type allele
/// - mutation ID for the mutant allele
List<String> _getAllelesAtLocus(
  String locusId,
  Set<String> relevantMutIds,
  ParentGenotype parent,
) {
  final selectedAtLocus = parent.getMutationsAtLocus(locusId);

  if (selectedAtLocus.isEmpty) {
    return ['wildtype', 'wildtype'];
  }

  if (selectedAtLocus.length == 1) {
    final mutId = selectedAtLocus.first;
    final state = parent.getState(mutId);
    return switch (state) {
      AlleleState.visual => [mutId, mutId], // Homozygous
      AlleleState.carrier => [mutId, 'wildtype'], // Heterozygous
      AlleleState.split => [mutId, 'wildtype'],
      null => ['wildtype', 'wildtype'],
    };
  }

  // 2 mutations selected at same locus = compound heterozygote
  // (e.g., greywing + clearwing → Full-Body Greywing)
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
    return ['wildtype', 'W'];
  }

  // Female is hemizygous: only one Z allele at sex-linked loci
  final mutId = selectedAtLocus.first;
  final state = mother.getState(mutId);
  if (state != null) {
    return [mutId, 'W'];
  }
  return ['wildtype', 'W'];
}

/// Sorts allelic pair into a canonical key for grouping.
String _sortAllelicPair(String a, String b) {
  if (a == 'wildtype' && b != 'wildtype') return '$b|$a';
  if (b == 'wildtype' && a != 'wildtype') return '$a|$b';
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
  if (allele1 == 'wildtype' && allele2 == 'wildtype') {
    return const _AllelicPhenotypeResult(
      phenotype: 'Normal',
      genotype: '+/+',
      expressedIds: [],
      carriedIds: [],
    );
  }

  // One wild-type, one mutant: wild-type is dominant over all mutants
  if (allele1 == 'wildtype' || allele2 == 'wildtype') {
    final mutant = allele1 == 'wildtype' ? allele2 : allele1;
    final record = MutationDatabase.getById(mutant);
    final sym = record?.alleleSymbol ?? mutant;
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

/// Dilution locus compound heterozygote resolution.
_AllelicPhenotypeResult _resolveDilutionCompound(
  String allele1,
  String allele2,
  String sym1,
  String sym2,
  int rank1,
  int rank2,
) {
  final alleles = {allele1, allele2};

  // greywing + clearwing = Full-Body Greywing
  if (alleles.contains('greywing') && alleles.contains('clearwing')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Full-Body Greywing',
      genotype: 'gw/cw',
      expressedIds: ['greywing', 'clearwing'],
      carriedIds: [],
    );
  }

  // greywing + dilute: greywing dominant, dilute carried
  if (alleles.contains('greywing') && alleles.contains('dilute')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Greywing',
      genotype: 'gw/dil',
      expressedIds: ['greywing'],
      carriedIds: ['dilute'],
    );
  }

  // clearwing + dilute: clearwing dominant, dilute carried
  if (alleles.contains('clearwing') && alleles.contains('dilute')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Clearwing',
      genotype: 'cw/dil',
      expressedIds: ['clearwing'],
      carriedIds: ['dilute'],
    );
  }

  // Fallback: higher rank dominates
  if (rank1 >= rank2) {
    return _AllelicPhenotypeResult(
      phenotype: MutationDatabase.getById(allele1)?.name ?? allele1,
      genotype: '$sym1/$sym2',
      expressedIds: [allele1],
      carriedIds: [allele2],
    );
  }
  return _AllelicPhenotypeResult(
    phenotype: MutationDatabase.getById(allele2)?.name ?? allele2,
    genotype: '$sym2/$sym1',
    expressedIds: [allele2],
    carriedIds: [allele1],
  );
}

/// Blue series locus compound heterozygote resolution.
_AllelicPhenotypeResult _resolveBlueSeriesCompound(
  String allele1,
  String allele2,
  String sym1,
  String sym2,
  int rank1,
  int rank2,
) {
  final alleles = {allele1, allele2};

  // yellowface_type2 + blue = Yellowface II Blue
  if (alleles.contains('yellowface_type2') && alleles.contains('blue')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Yellowface Type II Blue',
      genotype: 'Yf2/bl',
      expressedIds: ['yellowface_type2', 'blue'],
      carriedIds: [],
    );
  }

  // yellowface_type1 + blue = Yellowface I Blue
  if (alleles.contains('yellowface_type1') && alleles.contains('blue')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Yellowface Type I Blue',
      genotype: 'Yf1/bl',
      expressedIds: ['yellowface_type1', 'blue'],
      carriedIds: [],
    );
  }

  // yellowface_type2 + yellowface_type1 = Yellowface II (yf2 > yf1)
  if (alleles.contains('yellowface_type2') &&
      alleles.contains('yellowface_type1')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Yellowface Type II',
      genotype: 'Yf2/Yf1',
      expressedIds: ['yellowface_type2'],
      carriedIds: ['yellowface_type1'],
    );
  }

  // goldenface + blue = Goldenface Blue
  if (alleles.contains('goldenface') && alleles.contains('blue')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Goldenface Blue',
      genotype: 'Gf/bl',
      expressedIds: ['goldenface', 'blue'],
      carriedIds: [],
    );
  }

  // turquoise + blue = Turquoise Blue
  if (alleles.contains('turquoise') && alleles.contains('blue')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Turquoise Blue',
      genotype: 'Tq/bl',
      expressedIds: ['turquoise', 'blue'],
      carriedIds: [],
    );
  }

  // aqua + blue = Aqua Blue
  if (alleles.contains('aqua') && alleles.contains('blue')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Aqua Blue',
      genotype: 'Aq/bl',
      expressedIds: ['aqua', 'blue'],
      carriedIds: [],
    );
  }

  // turquoise + aqua = Turquoise Aqua (co-expressed parblue blend)
  if (alleles.contains('turquoise') && alleles.contains('aqua')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Turquoise Aqua',
      genotype: 'Tq/Aq',
      expressedIds: ['turquoise', 'aqua'],
      carriedIds: [],
    );
  }

  // bluefactor_1 + blue = Blue Factor I Blue
  if (alleles.contains('bluefactor_1') && alleles.contains('blue')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Blue Factor I Blue',
      genotype: 'Bf1/bl',
      expressedIds: ['bluefactor_1', 'blue'],
      carriedIds: [],
    );
  }

  // bluefactor_2 + blue = Blue Factor II Blue
  if (alleles.contains('bluefactor_2') && alleles.contains('blue')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Blue Factor II Blue',
      genotype: 'Bf2/bl',
      expressedIds: ['bluefactor_2', 'blue'],
      carriedIds: [],
    );
  }

  // bluefactor_2 + bluefactor_1 = Blue Factor II
  if (alleles.contains('bluefactor_2') && alleles.contains('bluefactor_1')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Blue Factor II',
      genotype: 'Bf2/Bf1',
      expressedIds: ['bluefactor_2'],
      carriedIds: ['bluefactor_1'],
    );
  }

  // Fallback: higher rank dominates
  if (rank1 >= rank2) {
    return _AllelicPhenotypeResult(
      phenotype: MutationDatabase.getById(allele1)?.name ?? allele1,
      genotype: '$sym1/$sym2',
      expressedIds: [allele1],
      carriedIds: [allele2],
    );
  }
  return _AllelicPhenotypeResult(
    phenotype: MutationDatabase.getById(allele2)?.name ?? allele2,
    genotype: '$sym2/$sym1',
    expressedIds: [allele2],
    carriedIds: [allele1],
  );
}

/// Ino locus compound heterozygote resolution.
_AllelicPhenotypeResult _resolveInoCompound(
  String allele1,
  String allele2,
  String sym1,
  String sym2,
  int rank1,
  int rank2,
) {
  final alleles = {allele1, allele2};

  // pallid + ino = PallidIno (often termed Lacewing in aviculture)
  if (alleles.contains('pallid') && alleles.contains('ino')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'PallidIno (Lacewing)',
      genotype: 'pal/ino',
      expressedIds: ['pallid', 'ino'],
      carriedIds: [],
    );
  }

  // texas_clearbody + ino = Texas Clearbody (ino carried)
  if (alleles.contains('texas_clearbody') && alleles.contains('ino')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Texas Clearbody',
      genotype: 'tcb/ino',
      expressedIds: ['texas_clearbody'],
      carriedIds: ['ino'],
    );
  }

  // texas_clearbody + pallid = Pallid Texas Clearbody
  if (alleles.contains('texas_clearbody') && alleles.contains('pallid')) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Pallid Texas Clearbody',
      genotype: 'pal/tcb',
      expressedIds: ['pallid', 'texas_clearbody'],
      carriedIds: [],
    );
  }

  // Fallback: higher rank dominates
  if (rank1 >= rank2) {
    return _AllelicPhenotypeResult(
      phenotype: MutationDatabase.getById(allele1)?.name ?? allele1,
      genotype: '$sym1/$sym2',
      expressedIds: [allele1],
      carriedIds: [allele2],
    );
  }
  return _AllelicPhenotypeResult(
    phenotype: MutationDatabase.getById(allele2)?.name ?? allele2,
    genotype: '$sym2/$sym1',
    expressedIds: [allele2],
    carriedIds: [allele1],
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
  if (ids.contains('cinnamon') && ids.contains('ino')) return 'Lacewing';
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
  if (alleleId == 'wildtype') return '+';
  if (alleleId == 'W') return 'W';
  final record = MutationDatabase.getById(alleleId);
  return record?.alleleSymbol ?? alleleId;
}
