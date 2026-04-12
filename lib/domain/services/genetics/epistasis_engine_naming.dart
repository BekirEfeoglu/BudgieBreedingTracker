part of 'epistasis_engine.dart';

/// Adds pied mutation naming including Dark-Eyed Clear detection.
void _addPiedNaming(List<String> parts, Set<String> visualMutations) {
  final hasRecessivePied = visualMutations.contains(GeneticsConstants.mutRecessivePied);
  final hasClearflightPied = visualMutations.contains(GeneticsConstants.mutClearflightPied);
  final hasDominantPied = visualMutations.contains(GeneticsConstants.mutDominantPied);
  final hasDutchPied = visualMutations.contains(GeneticsConstants.mutDutchPied);

  if (hasRecessivePied && hasClearflightPied) {
    // Dark-Eyed Clear: Recessive Pied + Clearflight Pied
    parts.add('Dark-Eyed Clear');
  } else {
    if (hasRecessivePied) parts.add('Recessive Pied');
    if (hasClearflightPied && hasDutchPied) {
      parts.add('Dutch Clearflight Pied');
    } else if (hasClearflightPied) {
      parts.add('Clearflight Pied');
    }
  }

  if (hasDominantPied && hasDutchPied) {
    parts.add('Double Dominant Pied');
  } else {
    if (hasDominantPied) parts.add('Dominant Pied');
    if (hasDutchPied) parts.add('Dutch Pied');
  }
}

/// Adds crested mutation naming with compound heterozygote detection.
void _addCrestedNaming(List<String> parts, Set<String> visualMutations) {
  final activeCrested = GeneticsConstants.crestedAlleleIds
      .where(visualMutations.contains)
      .toList();
  if (activeCrested.length >= 2) {
    // Compound heterozygote: two different crested alleles
    final labels = activeCrested
        .map(
          (id) => switch (id) {
            GeneticsConstants.mutCrestedTufted => 'Tufted',
            GeneticsConstants.mutCrestedHalfCircular => 'Half-Circular',
            GeneticsConstants.mutCrestedFullCircular => 'Full-Circular',
            _ => id,
          },
        )
        .toList();
    parts.add('${labels.join('/')} Compound Crest');
  } else {
    if (visualMutations.contains(GeneticsConstants.mutCrestedTufted)) {
      parts.add('Tufted');
    }
    if (visualMutations.contains(GeneticsConstants.mutCrestedHalfCircular)) {
      parts.add('Half-Circular Crest');
    }
    if (visualMutations.contains(GeneticsConstants.mutCrestedFullCircular)) {
      parts.add('Full-Circular Crest');
    }
  }
}

/// Resolves base color name from base color series and dark factor count.
String? _resolveBaseColorName(_BaseColor base, int darkFactorCount) {
  return switch ((base, darkFactorCount)) {
    (_BaseColor.green, 0) => 'Light Green',
    (_BaseColor.green, 1) => 'Dark Green',
    (_BaseColor.green, >= 2) => 'Olive',
    (_BaseColor.blue, 0) => 'Skyblue',
    (_BaseColor.blue, 1) => 'Cobalt',
    (_BaseColor.blue, >= 2) => 'Mauve',
    _ => null,
  };
}
