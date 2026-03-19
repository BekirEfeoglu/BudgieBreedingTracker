part of 'epistasis_engine.dart';

/// Returns a list of epistatic interactions detected in the mutation set.
List<EpistaticInteraction> _getInteractions(Set<String> mutations) {
  final interactions = <EpistaticInteraction>[];

  final isBlue =
      mutations.contains('blue') ||
      mutations.contains('aqua') ||
      mutations.contains('turquoise') ||
      mutations.contains('bluefactor_1') ||
      mutations.contains('bluefactor_2');
  final hasIno = mutations.contains('ino');
  final hasCinnamon = mutations.contains('cinnamon');
  final hasPallid = mutations.contains('pallid');
  final hasBlackface = mutations.contains('blackface');
  final hasSpangle = mutations.contains('spangle');
  final hasViolet = mutations.contains('violet');
  final hasDarkFactor = mutations.contains('dark_factor');
  final hasYf2 = mutations.contains('yellowface_type2');
  final hasGoldenface = mutations.contains('goldenface');
  final hasBlueFactor1 = mutations.contains('bluefactor_1');
  final hasBlueFactor2 = mutations.contains('bluefactor_2');
  final hasRecessivePied = mutations.contains('recessive_pied');
  final hasClearflightPied = mutations.contains('clearflight_pied');
  final hasDominantPied = mutations.contains('dominant_pied');
  final hasDutchPied = mutations.contains('dutch_pied');

  // PallidIno / Creamino
  if (hasIno && hasPallid) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['pallid', 'ino'],
        resultName: 'PallidIno (Lacewing)',
        description:
            'Pallid and Ino are alleles at the same sex-linked locus; '
            'their compound state yields a lacewing-like phenotype.',
      ),
    );
  } else if (hasIno &&
      (hasYf2 || hasGoldenface || hasBlueFactor1 || hasBlueFactor2) &&
      isBlue) {
    final creaminoSource = hasYf2
        ? 'yellowface_type2'
        : hasGoldenface
        ? 'goldenface'
        : hasBlueFactor2
        ? 'bluefactor_2'
        : 'bluefactor_1';
    interactions.add(
      EpistaticInteraction(
        mutationIds: [creaminoSource, 'blue', 'ino'],
        resultName: 'Creamino',
        description:
            'Yellowface/Blue-factor allele + Blue + Ino produces Creamino: '
            'a creamy yellowish-white bird with red eyes.',
      ),
    );
  } else if (hasIno && isBlue) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['ino', 'blue'],
        resultName: 'Albino',
        description:
            'Ino gene removes all melanin. Combined with blue series, '
            'produces a white bird with red eyes (Albino).',
      ),
    );
  }

  if (hasIno && !isBlue) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['ino'],
        resultName: 'Lutino',
        description:
            'Ino gene removes all melanin from green series, '
            'producing a yellow bird with red eyes (Lutino).',
      ),
    );
  }

  if (hasIno && hasCinnamon) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['ino', 'cinnamon'],
        resultName: 'Lacewing',
        description:
            'Cinnamon + Ino combination. Shows faint cinnamon markings '
            'on an ino background. Both are sex-linked recessive.',
      ),
    );
  }

  if (hasViolet && isBlue && hasDarkFactor) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['violet', 'blue', 'dark_factor'],
        resultName: 'Visual Violet',
        description:
            'Violet factor shows best on Cobalt (Blue + 1 Dark Factor). '
            'Double Violet on Skyblue (VV + 0 DF) also produces visual violet.',
      ),
    );
  }

  if (mutations.contains('grey') && !isBlue) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['grey'],
        resultName: 'Grey-Green',
        description:
            'Grey factor on green series produces Grey-Green, '
            'a distinct olive-grey coloration.',
      ),
    );
  }

  if (mutations.contains('greywing') && mutations.contains('clearwing')) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['greywing', 'clearwing'],
        resultName: 'Full-Body Greywing',
        description:
            'Greywing/Clearwing heterozygote produces a Full-Body '
            'colour Greywing (diluted body, normal-intensity wing markings).',
      ),
    );
  }

  // Dark-Eyed Clear: Recessive Pied + Clearflight Pied
  if (hasRecessivePied && hasClearflightPied) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['recessive_pied', 'clearflight_pied'],
        resultName: 'Dark-Eyed Clear',
        description:
            'Recessive Pied + Clearflight Pied combination produces '
            'a Dark-Eyed Clear: solid yellow/white bird with dark eyes '
            '(no white iris ring).',
      ),
    );
  }

  if (hasBlackface && hasSpangle) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['blackface', 'spangle'],
        resultName: 'Melanistic Spangle',
        description:
            'Blackface with Spangle can produce a heavier melanin-edged '
            'spangle presentation (melanistic-style look).',
      ),
    );
  }

  if (hasDutchPied && hasDominantPied) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['dutch_pied', 'dominant_pied'],
        resultName: 'Double Dominant Pied',
        description:
            'Dutch Pied and Dominant Pied together are labelled as a '
            'double dominant pied-style combination.',
      ),
    );
  }

  if (hasDutchPied && hasClearflightPied && !hasRecessivePied) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['dutch_pied', 'clearflight_pied'],
        resultName: 'Dutch Clearflight Pied',
        description:
            'Dutch Pied with Clearflight Pied can be tracked as a distinct '
            'clearflight-dutch pied combination.',
      ),
    );
  }

  // Yellowface on green series -> no visible effect
  if ((mutations.contains('yellowface_type1') ||
          mutations.contains('yellowface_type2')) &&
      !isBlue) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['yellowface_type1'],
        resultName: 'Yellowface (masked)',
        description:
            'Yellowface on green series birds has no visible effect, '
            'as the yellow pigment is already present. The bird carries '
            'the Yellowface gene but appears normal green series.',
      ),
    );
  }

  // Aqua/Turquoise + Ino interactions
  final hasAqua = mutations.contains('aqua');
  final hasTurquoise = mutations.contains('turquoise');
  if (hasIno && (hasAqua || hasTurquoise) && !hasCinnamon) {
    final parblueType = hasAqua ? 'Aqua' : 'Turquoise';
    interactions.add(
      EpistaticInteraction(
        mutationIds: [hasAqua ? 'aqua' : 'turquoise', 'ino'],
        resultName: '$parblueType Ino',
        description:
            '$parblueType parblue allele + Ino: melanin removed but '
            'parblue-level psittacin retained. Produces a unique '
            'pale-toned ino with residual body colour.',
      ),
    );
  }

  // Pearly + Opaline interaction
  final hasPearly = mutations.contains('pearly');
  final hasOpaline = mutations.contains('opaline');
  if (hasPearly && hasOpaline) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['pearly', 'opaline'],
        resultName: 'Opaline Pearly',
        description:
            'Pearly + Opaline combination: both sex-linked pattern '
            'modifiers interact to produce a distinctive pearled-opaline '
            'wing pattern with enhanced mantle colour.',
      ),
    );
  }

  // Pearly + Cinnamon interaction
  if (hasPearly && hasCinnamon) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: ['pearly', 'cinnamon'],
        resultName: 'Cinnamon Pearly',
        description:
            'Pearly + Cinnamon combination: pearled wing pattern '
            'rendered in warm brown tones instead of black.',
      ),
    );
  }

  // Crested compound heterozygote
  final activeCrested = GeneticsConstants.crestedAlleleIds
      .where(mutations.contains)
      .toList();
  if (activeCrested.length >= 2) {
    interactions.add(
      EpistaticInteraction(
        mutationIds: activeCrested,
        resultName: 'Crested Compound',
        description:
            'Two different crested alleles at the same locus: '
            'the resulting crest may show intermediate '
            'or mixed characteristics of both crest types.',
      ),
    );
  }

  return interactions;
}
