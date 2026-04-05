part of 'epistasis_engine.dart';

/// Resolves compound phenotype with detailed info including masked mutations.
///
/// [visualMutations] contains the set of visual mutation IDs.
/// [doubleFactorIds] contains mutation IDs that are homozygous (double factor).
CompoundPhenotypeResult _resolveCompoundPhenotypeDetailed(
  Set<String> visualMutations, {
  Set<String> doubleFactorIds = const {},
}) {
  if (visualMutations.isEmpty) {
    return const CompoundPhenotypeResult(name: 'Normal');
  }

  final parts = <String>[];
  final masked = <String>[];

  // 1. Determine base color (green or blue series)
  final isBlue =
      visualMutations.contains(GeneticsConstants.mutBlue) ||
      visualMutations.contains(GeneticsConstants.mutAqua) ||
      visualMutations.contains(GeneticsConstants.mutTurquoise) ||
      visualMutations.contains(GeneticsConstants.mutBlueFactor1) ||
      visualMutations.contains(GeneticsConstants.mutBlueFactor2);
  final baseColor = isBlue ? _BaseColor.blue : _BaseColor.green;

  // 2. Yellowface detection
  final hasYf1 = visualMutations.contains(GeneticsConstants.mutYellowfaceType1);
  final hasYf2 = visualMutations.contains(GeneticsConstants.mutYellowfaceType2);
  final hasGoldenface = visualMutations.contains(GeneticsConstants.mutGoldenface);
  final hasBlueFactor1 = visualMutations.contains(GeneticsConstants.mutBlueFactor1);
  final hasBlueFactor2 = visualMutations.contains(GeneticsConstants.mutBlueFactor2);
  final hasYellowface =
      hasYf1 || hasYf2 || hasGoldenface || hasBlueFactor1 || hasBlueFactor2;

  // 3. Check for Ino interactions FIRST (overrides base color naming)
  final hasIno = visualMutations.contains(GeneticsConstants.mutIno);
  final hasCinnamon = visualMutations.contains(GeneticsConstants.mutCinnamon);
  final hasPallid = visualMutations.contains(GeneticsConstants.mutPallid);
  final hasBlackface = visualMutations.contains(GeneticsConstants.mutBlackface);

  // 3a. Ino naming: Albino/Lutino/Lacewing/Creamino/PallidIno
  _addInoNaming(
    parts,
    hasIno: hasIno,
    hasCinnamon: hasCinnamon,
    hasPallid: hasPallid,
    hasYf2: hasYf2,
    hasGoldenface: hasGoldenface,
    hasBlueFactor1: hasBlueFactor1,
    hasBlueFactor2: hasBlueFactor2,
    isBlue: isBlue,
  );

  // 3b. Collect mutations masked by Ino
  if (hasIno) {
    _collectMaskedMutations(
      visualMutations,
      doubleFactorIds,
      hasCinnamon,
      parts,
      masked,
    );
  }

  // 4. Dark factor dosage (single locus: SF=1 copy, DF=2 copies)
  final hasDarkFactor = visualMutations.contains(GeneticsConstants.mutDarkFactor);
  final darkFactorCount = !hasDarkFactor
      ? 0
      : doubleFactorIds.contains(GeneticsConstants.mutDarkFactor)
      ? 2
      : 1;

  // 5. Violet factor
  final hasViolet = visualMutations.contains(GeneticsConstants.mutViolet);

  // 6. Grey factor
  final hasGrey = visualMutations.contains(GeneticsConstants.mutGrey);

  // 7. Yellowface naming (only when not already Creamino)
  _addYellowfaceNaming(
    parts,
    hasYellowface: hasYellowface,
    hasIno: hasIno,
    hasYf1: hasYf1,
    hasYf2: hasYf2,
    hasGoldenface: hasGoldenface,
    hasBlueFactor1: hasBlueFactor1,
    hasBlueFactor2: hasBlueFactor2,
    isBlue: isBlue,
    doubleFactorIds: doubleFactorIds,
  );

  // 8. Build base color name with dark factor
  if (!hasIno) {
    _addBaseColorNaming(
      parts,
      isBlue: isBlue,
      hasGrey: hasGrey,
      hasViolet: hasViolet,
      darkFactorCount: darkFactorCount,
      baseColor: baseColor,
      doubleFactorIds: doubleFactorIds,
    );
  }

  // 9-15. Pattern mutations, melanin modifiers, pied, fallow, crest,
  //        clearbody, saddleback
  _addPatternAndModifierNaming(
    parts,
    visualMutations: visualMutations,
    doubleFactorIds: doubleFactorIds,
    hasIno: hasIno,
    hasCinnamon: hasCinnamon,
    hasBlackface: hasBlackface,
  );

  final uniqueParts = <String>[];
  for (final part in parts) {
    if (!uniqueParts.contains(part)) uniqueParts.add(part);
  }

  final name = uniqueParts.isEmpty ? 'Normal' : uniqueParts.join(' ');
  return CompoundPhenotypeResult(name: name, maskedMutations: masked);
}
