part of 'mendelian_calculator.dart';

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
  if (alleles.contains('yellowface_type2') &&
      alleles.contains(GeneticsConstants.mutBlue)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Yellowface Type II Blue',
      genotype: 'Yf2/bl',
      expressedIds: ['yellowface_type2', GeneticsConstants.mutBlue],
      carriedIds: [],
    );
  }

  // yellowface_type1 + blue = Yellowface I Blue
  if (alleles.contains('yellowface_type1') &&
      alleles.contains(GeneticsConstants.mutBlue)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Yellowface Type I Blue',
      genotype: 'Yf1/bl',
      expressedIds: ['yellowface_type1', GeneticsConstants.mutBlue],
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
  if (alleles.contains('goldenface') &&
      alleles.contains(GeneticsConstants.mutBlue)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Goldenface Blue',
      genotype: 'Gf/bl',
      expressedIds: ['goldenface', GeneticsConstants.mutBlue],
      carriedIds: [],
    );
  }

  // turquoise + blue = Turquoise Blue
  if (alleles.contains('turquoise') &&
      alleles.contains(GeneticsConstants.mutBlue)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Turquoise Blue',
      genotype: 'Tq/bl',
      expressedIds: ['turquoise', GeneticsConstants.mutBlue],
      carriedIds: [],
    );
  }

  // aqua + blue = Aqua Blue
  if (alleles.contains('aqua') &&
      alleles.contains(GeneticsConstants.mutBlue)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Aqua Blue',
      genotype: 'Aq/bl',
      expressedIds: ['aqua', GeneticsConstants.mutBlue],
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
  if (alleles.contains('bluefactor_1') &&
      alleles.contains(GeneticsConstants.mutBlue)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Blue Factor I Blue',
      genotype: 'Bf1/bl',
      expressedIds: ['bluefactor_1', GeneticsConstants.mutBlue],
      carriedIds: [],
    );
  }

  // bluefactor_2 + blue = Blue Factor II Blue
  if (alleles.contains('bluefactor_2') &&
      alleles.contains(GeneticsConstants.mutBlue)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Blue Factor II Blue',
      genotype: 'Bf2/bl',
      expressedIds: ['bluefactor_2', GeneticsConstants.mutBlue],
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
  if (alleles.contains(GeneticsConstants.mutPallid) &&
      alleles.contains(GeneticsConstants.mutIno)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'PallidIno (Lacewing)',
      genotype: 'pal/ino',
      expressedIds: [GeneticsConstants.mutPallid, GeneticsConstants.mutIno],
      carriedIds: [],
    );
  }

  // texas_clearbody + ino = Texas Clearbody (ino carried)
  if (alleles.contains(GeneticsConstants.mutTexasClearbody) &&
      alleles.contains(GeneticsConstants.mutIno)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Texas Clearbody',
      genotype: 'tcb/ino',
      expressedIds: [GeneticsConstants.mutTexasClearbody],
      carriedIds: [GeneticsConstants.mutIno],
    );
  }

  // texas_clearbody + pallid = Pallid Texas Clearbody
  if (alleles.contains(GeneticsConstants.mutTexasClearbody) &&
      alleles.contains(GeneticsConstants.mutPallid)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Pallid Texas Clearbody',
      genotype: 'pal/tcb',
      expressedIds: [
        GeneticsConstants.mutPallid,
        GeneticsConstants.mutTexasClearbody,
      ],
      carriedIds: [],
    );
  }

  // pearly + ino = Pearly (ino carried, pearly > ino)
  if (alleles.contains(GeneticsConstants.mutPearly) &&
      alleles.contains(GeneticsConstants.mutIno)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Pearly',
      genotype: 'prl/ino',
      expressedIds: [GeneticsConstants.mutPearly],
      carriedIds: [GeneticsConstants.mutIno],
    );
  }

  // texas_clearbody + pearly = Texas Clearbody (pearly carried, tcb > pearly)
  if (alleles.contains(GeneticsConstants.mutTexasClearbody) &&
      alleles.contains(GeneticsConstants.mutPearly)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Texas Clearbody',
      genotype: 'tcb/prl',
      expressedIds: [GeneticsConstants.mutTexasClearbody],
      carriedIds: [GeneticsConstants.mutPearly],
    );
  }

  // pearly + pallid = Pallid Pearly (both expressed, adjacent in hierarchy)
  if (alleles.contains(GeneticsConstants.mutPearly) &&
      alleles.contains(GeneticsConstants.mutPallid)) {
    return const _AllelicPhenotypeResult(
      phenotype: 'Pallid Pearly',
      genotype: 'prl/pal',
      expressedIds: [GeneticsConstants.mutPearly, GeneticsConstants.mutPallid],
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
