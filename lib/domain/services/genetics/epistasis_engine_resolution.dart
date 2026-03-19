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
      visualMutations.contains('blue') ||
      visualMutations.contains('aqua') ||
      visualMutations.contains('turquoise') ||
      visualMutations.contains('bluefactor_1') ||
      visualMutations.contains('bluefactor_2');
  final baseColor = isBlue ? _BaseColor.blue : _BaseColor.green;

  // 2. Yellowface detection
  final hasYf1 = visualMutations.contains('yellowface_type1');
  final hasYf2 = visualMutations.contains('yellowface_type2');
  final hasGoldenface = visualMutations.contains('goldenface');
  final hasBlueFactor1 = visualMutations.contains('bluefactor_1');
  final hasBlueFactor2 = visualMutations.contains('bluefactor_2');
  final hasYellowface =
      hasYf1 || hasYf2 || hasGoldenface || hasBlueFactor1 || hasBlueFactor2;

  // 3. Check for Ino interactions FIRST (overrides base color naming)
  final hasIno = visualMutations.contains('ino');
  final hasCinnamon = visualMutations.contains('cinnamon');
  final hasPallid = visualMutations.contains('pallid');
  final hasBlackface = visualMutations.contains('blackface');

  // 3a. PallidIno and Creamino combinations
  if (hasIno && hasPallid) {
    parts.add('PallidIno (Lacewing)');
  } else if (hasIno &&
      (hasYf2 || hasGoldenface || hasBlueFactor1 || hasBlueFactor2) &&
      isBlue) {
    // Creamino: Yellowface Type II/Goldenface + Blue + Ino
    parts.add('Creamino');
  } else if (hasIno && hasCinnamon) {
    // Lacewing: Cinnamon + Ino combination
    parts.add('Lacewing');
  } else if (hasIno) {
    if (isBlue) {
      parts.add('Albino');
    } else {
      parts.add('Lutino');
    }
  }

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
  final hasDarkFactor = visualMutations.contains('dark_factor');
  final darkFactorCount = !hasDarkFactor
      ? 0
      : doubleFactorIds.contains('dark_factor')
      ? 2
      : 1;

  // 5. Violet factor
  final hasViolet = visualMutations.contains('violet');

  // 6. Grey factor
  final hasGrey = visualMutations.contains('grey');

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
