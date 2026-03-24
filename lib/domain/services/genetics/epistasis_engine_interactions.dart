part of 'epistasis_engine.dart';

/// Returns a list of epistatic interactions detected in the mutation set.
List<EpistaticInteraction> _getInteractions(Set<String> mutations) {
  final interactions = <EpistaticInteraction>[];

  final flags = _InteractionFlags.from(mutations);

  _addInoAllelicInteractions(mutations, flags, interactions);
  _addInoSeriesInteractions(flags, interactions);
  _addVioletDarkFactorInteractions(flags, interactions);
  _addGreyInteractions(mutations, flags, interactions);
  _addGreywingClearwingInteractions(mutations, interactions);
  _addPiedInteractions(flags, interactions);
  _addBlackfaceSpangleInteractions(flags, interactions);
  _addYellowfaceMaskedInteractions(mutations, flags, interactions);
  _addParblueInoInteractions(mutations, flags, interactions);
  _addPearlyInteractions(mutations, flags, interactions);
  _addCrestedCompoundInteractions(mutations, interactions);

  return interactions;
}

class _InteractionFlags {
  final bool isBlue;
  final bool hasIno;
  final bool hasCinnamon;
  final bool hasPallid;
  final bool hasBlackface;
  final bool hasSpangle;
  final bool hasViolet;
  final bool hasDarkFactor;
  final bool hasYf2;
  final bool hasGoldenface;
  final bool hasBlueFactor1;
  final bool hasBlueFactor2;
  final bool hasRecessivePied;
  final bool hasClearflightPied;
  final bool hasDominantPied;
  final bool hasDutchPied;
  final bool hasAqua;
  final bool hasTurquoise;

  const _InteractionFlags({
    required this.isBlue,
    required this.hasIno,
    required this.hasCinnamon,
    required this.hasPallid,
    required this.hasBlackface,
    required this.hasSpangle,
    required this.hasViolet,
    required this.hasDarkFactor,
    required this.hasYf2,
    required this.hasGoldenface,
    required this.hasBlueFactor1,
    required this.hasBlueFactor2,
    required this.hasRecessivePied,
    required this.hasClearflightPied,
    required this.hasDominantPied,
    required this.hasDutchPied,
    required this.hasAqua,
    required this.hasTurquoise,
  });

  factory _InteractionFlags.from(Set<String> mutations) {
    return _InteractionFlags(
      isBlue: mutations.contains(GeneticsConstants.mutBlue) ||
          mutations.contains(GeneticsConstants.mutAqua) ||
          mutations.contains(GeneticsConstants.mutTurquoise) ||
          mutations.contains(GeneticsConstants.mutBlueFactor1) ||
          mutations.contains(GeneticsConstants.mutBlueFactor2),
      hasIno: mutations.contains(GeneticsConstants.mutIno),
      hasCinnamon: mutations.contains(GeneticsConstants.mutCinnamon),
      hasPallid: mutations.contains(GeneticsConstants.mutPallid),
      hasBlackface: mutations.contains(GeneticsConstants.mutBlackface),
      hasSpangle: mutations.contains(GeneticsConstants.mutSpangle),
      hasViolet: mutations.contains(GeneticsConstants.mutViolet),
      hasDarkFactor: mutations.contains(GeneticsConstants.mutDarkFactor),
      hasYf2: mutations.contains(GeneticsConstants.mutYellowfaceType2),
      hasGoldenface: mutations.contains(GeneticsConstants.mutGoldenface),
      hasBlueFactor1: mutations.contains(GeneticsConstants.mutBlueFactor1),
      hasBlueFactor2: mutations.contains(GeneticsConstants.mutBlueFactor2),
      hasRecessivePied: mutations.contains(GeneticsConstants.mutRecessivePied),
      hasClearflightPied: mutations.contains(GeneticsConstants.mutClearflightPied),
      hasDominantPied: mutations.contains(GeneticsConstants.mutDominantPied),
      hasDutchPied: mutations.contains(GeneticsConstants.mutDutchPied),
      hasAqua: mutations.contains(GeneticsConstants.mutAqua),
      hasTurquoise: mutations.contains(GeneticsConstants.mutTurquoise),
    );
  }
}

void _addInoAllelicInteractions(
  Set<String> mutations,
  _InteractionFlags f,
  List<EpistaticInteraction> interactions,
) {
  if (f.hasIno && f.hasPallid) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutPallid, GeneticsConstants.mutIno],
        resultName: 'PallidIno (Lacewing)',
        description:
            'Pallid and Ino are alleles at the same sex-linked locus; '
            'their compound state yields a lacewing-like phenotype.',
      ),
    );
  } else if (f.hasIno &&
      (f.hasYf2 || f.hasGoldenface || f.hasBlueFactor1 || f.hasBlueFactor2) &&
      f.isBlue) {
    final creaminoSource = f.hasYf2
        ? GeneticsConstants.mutYellowfaceType2
        : f.hasGoldenface
        ? GeneticsConstants.mutGoldenface
        : f.hasBlueFactor2
        ? GeneticsConstants.mutBlueFactor2
        : GeneticsConstants.mutBlueFactor1;
    interactions.add(
      EpistaticInteraction(
        mutationIds: [creaminoSource, GeneticsConstants.mutBlue, GeneticsConstants.mutIno],
        resultName: 'Creamino',
        description:
            'Yellowface/Blue-factor allele + Blue + Ino produces Creamino: '
            'a creamy yellowish-white bird with red eyes.',
      ),
    );
  } else if (f.hasIno && f.isBlue) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutIno, GeneticsConstants.mutBlue],
        resultName: 'Albino',
        description:
            'Ino gene removes all melanin. Combined with blue series, '
            'produces a white bird with red eyes (Albino).',
      ),
    );
  }
}

void _addInoSeriesInteractions(
  _InteractionFlags f,
  List<EpistaticInteraction> interactions,
) {
  if (f.hasIno && !f.isBlue) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutIno],
        resultName: 'Lutino',
        description:
            'Ino gene removes all melanin from green series, '
            'producing a yellow bird with red eyes (Lutino).',
      ),
    );
  }

  if (f.hasIno && f.hasCinnamon) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutIno, GeneticsConstants.mutCinnamon],
        resultName: 'Lacewing',
        description:
            'Cinnamon + Ino combination. Shows faint cinnamon markings '
            'on an ino background. Both are sex-linked recessive.',
      ),
    );
  }
}

void _addVioletDarkFactorInteractions(
  _InteractionFlags f,
  List<EpistaticInteraction> interactions,
) {
  if (f.hasViolet && f.isBlue && f.hasDarkFactor) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [
          GeneticsConstants.mutViolet,
          GeneticsConstants.mutBlue,
          GeneticsConstants.mutDarkFactor,
        ],
        resultName: 'Visual Violet',
        description:
            'Violet factor shows best on Cobalt (Blue + 1 Dark Factor). '
            'Double Violet on Skyblue (VV + 0 DF) also produces visual violet.',
      ),
    );
  }
}

void _addGreyInteractions(
  Set<String> mutations,
  _InteractionFlags f,
  List<EpistaticInteraction> interactions,
) {
  if (mutations.contains(GeneticsConstants.mutGrey) && !f.isBlue) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutGrey],
        resultName: 'Grey-Green',
        description:
            'Grey factor on green series produces Grey-Green, '
            'a distinct olive-grey coloration.',
      ),
    );
  }
}

void _addGreywingClearwingInteractions(
  Set<String> mutations,
  List<EpistaticInteraction> interactions,
) {
  if (mutations.contains(GeneticsConstants.mutGreywing) &&
      mutations.contains(GeneticsConstants.mutClearwing)) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutGreywing, GeneticsConstants.mutClearwing],
        resultName: 'Full-Body Greywing',
        description:
            'Greywing/Clearwing heterozygote produces a Full-Body '
            'colour Greywing (diluted body, normal-intensity wing markings).',
      ),
    );
  }
}
