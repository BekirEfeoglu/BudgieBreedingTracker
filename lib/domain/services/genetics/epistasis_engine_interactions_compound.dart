part of 'epistasis_engine.dart';

void _addPiedInteractions(
  _InteractionFlags f,
  List<EpistaticInteraction> interactions,
) {
  if (f.hasRecessivePied && f.hasClearflightPied) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutRecessivePied, GeneticsConstants.mutClearflightPied],
        resultName: 'Dark-Eyed Clear',
        description:
            'Recessive Pied + Clearflight Pied combination produces '
            'a Dark-Eyed Clear: solid yellow/white bird with dark eyes '
            '(no white iris ring).',
      ),
    );
  }

  if (f.hasDutchPied && f.hasDominantPied) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutDutchPied, GeneticsConstants.mutDominantPied],
        resultName: 'Double Dominant Pied',
        description:
            'Dutch Pied and Dominant Pied together are labelled as a '
            'double dominant pied-style combination.',
      ),
    );
  }

  if (f.hasDutchPied && f.hasClearflightPied && !f.hasRecessivePied) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutDutchPied, GeneticsConstants.mutClearflightPied],
        resultName: 'Dutch Clearflight Pied',
        description:
            'Dutch Pied with Clearflight Pied can be tracked as a distinct '
            'clearflight-dutch pied combination.',
      ),
    );
  }
}

void _addBlackfaceSpangleInteractions(
  _InteractionFlags f,
  List<EpistaticInteraction> interactions,
) {
  if (f.hasBlackface && f.hasSpangle) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutBlackface, GeneticsConstants.mutSpangle],
        resultName: 'Melanistic Spangle',
        description:
            'Blackface with Spangle can produce a heavier melanin-edged '
            'spangle presentation (melanistic-style look).',
      ),
    );
  }
}

void _addYellowfaceMaskedInteractions(
  Set<String> mutations,
  _InteractionFlags f,
  List<EpistaticInteraction> interactions,
) {
  if ((mutations.contains(GeneticsConstants.mutYellowfaceType1) ||
          mutations.contains(GeneticsConstants.mutYellowfaceType2)) &&
      !f.isBlue) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutYellowfaceType1],
        resultName: 'Yellowface (masked)',
        description:
            'Yellowface on green series birds has no visible effect, '
            'as the yellow pigment is already present. The bird carries '
            'the Yellowface gene but appears normal green series.',
      ),
    );
  }
}

void _addParblueInoInteractions(
  Set<String> mutations,
  _InteractionFlags f,
  List<EpistaticInteraction> interactions,
) {
  if (f.hasIno && (f.hasAqua || f.hasTurquoise) && !f.hasCinnamon) {
    final parblueType = f.hasAqua ? 'Aqua' : 'Turquoise';
    interactions.add(
      EpistaticInteraction(
        mutationIds: [
          f.hasAqua ? GeneticsConstants.mutAqua : GeneticsConstants.mutTurquoise,
          GeneticsConstants.mutIno,
        ],
        resultName: '$parblueType Ino',
        description:
            '$parblueType parblue allele + Ino: melanin removed but '
            'parblue-level psittacin retained. Produces a unique '
            'pale-toned ino with residual body colour.',
      ),
    );
  }
}

void _addPearlyInteractions(
  Set<String> mutations,
  _InteractionFlags f,
  List<EpistaticInteraction> interactions,
) {
  final hasPearly = mutations.contains(GeneticsConstants.mutPearly);
  final hasOpaline = mutations.contains(GeneticsConstants.mutOpaline);

  if (hasPearly && hasOpaline) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutPearly, GeneticsConstants.mutOpaline],
        resultName: 'Opaline Pearly',
        description:
            'Pearly + Opaline combination: both sex-linked pattern '
            'modifiers interact to produce a distinctive pearled-opaline '
            'wing pattern with enhanced mantle colour.',
      ),
    );
  }

  if (hasPearly && f.hasCinnamon) {
    interactions.add(
      const EpistaticInteraction(
        mutationIds: [GeneticsConstants.mutPearly, GeneticsConstants.mutCinnamon],
        resultName: 'Cinnamon Pearly',
        description:
            'Pearly + Cinnamon combination: pearled wing pattern '
            'rendered in warm brown tones instead of black.',
      ),
    );
  }
}

void _addCrestedCompoundInteractions(
  Set<String> mutations,
  List<EpistaticInteraction> interactions,
) {
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
}
