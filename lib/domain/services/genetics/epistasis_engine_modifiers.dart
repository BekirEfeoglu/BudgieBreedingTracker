part of 'epistasis_engine.dart';

/// Collects mutations masked by Ino (genetically present but not visible).
void _collectMaskedMutations(
  Set<String> visualMutations,
  Set<String> doubleFactorIds,
  bool hasCinnamon,
  List<String> parts,
  List<String> masked,
) {
  // Ino masks all melanin-based mutations visually
  if (visualMutations.contains('opaline')) masked.add('Opaline');
  if (visualMutations.contains('dark_factor')) {
    final dfLabel = doubleFactorIds.contains('dark_factor')
        ? 'Dark Factor (Double)'
        : 'Dark Factor (Single)';
    masked.add(dfLabel);
  }
  if (visualMutations.contains('grey')) masked.add('Grey');
  if (visualMutations.contains('violet')) masked.add('Violet');
  if (visualMutations.contains('spangle')) {
    final spLabel = doubleFactorIds.contains('spangle')
        ? 'Double Factor Spangle'
        : 'Spangle';
    masked.add(spLabel);
  }
  if (visualMutations.contains('dilute')) masked.add('Dilute');
  if (visualMutations.contains('slate')) masked.add('Slate');
  if (visualMutations.contains('clearwing')) masked.add('Clearwing');
  if (visualMutations.contains('greywing')) masked.add('Greywing');
  if (visualMutations.contains('pearly')) masked.add('Pearly');
  if (visualMutations.contains('pallid')) masked.add('Pallid');
  // Cinnamon is masked by Ino unless it's already part of the Lacewing name
  if (hasCinnamon && !parts.contains('Lacewing')) {
    masked.add('Cinnamon');
  }
}

/// Adds yellowface-related naming to parts list.
void _addYellowfaceNaming(
  List<String> parts, {
  required bool hasYellowface,
  required bool hasIno,
  required bool hasYf1,
  required bool hasYf2,
  required bool hasGoldenface,
  required bool hasBlueFactor1,
  required bool hasBlueFactor2,
  required bool isBlue,
  required Set<String> doubleFactorIds,
}) {
  if (hasYellowface && !hasIno) {
    if (hasYf1) {
      if (isBlue) {
        // Yellowface Type 1 DF paradox: double factor = white-faced
        if (doubleFactorIds.contains('yellowface_type1')) {
          parts.add('Whitefaced');
        } else {
          parts.add('Yellowface Type I');
        }
      }
      // Green series: no visible effect (yellow mask already present)
    }
    if (hasYf2) {
      if (isBlue) {
        if (doubleFactorIds.contains('yellowface_type2')) {
          parts.add('Yellowface Type II DF');
        } else {
          parts.add('Yellowface Type II');
        }
      }
    }
    if (hasGoldenface) {
      parts.add('Goldenface');
    }
    if (hasBlueFactor1) {
      parts.add('Blue Factor I');
    }
    if (hasBlueFactor2) {
      parts.add('Blue Factor II');
    }
  } else if (hasYellowface && hasIno && !(hasYf2 && isBlue)) {
    // Yellowface + Ino but not Creamino -> just note Yellowface
    if (hasYf1 && isBlue) {
      if (doubleFactorIds.contains('yellowface_type1')) {
        parts.add('Whitefaced');
      } else {
        parts.add('Yellowface Type I');
      }
    }
    if (hasYf2 && !isBlue) parts.add('Yellowface Type II');
    if (hasGoldenface && !isBlue) parts.add('Goldenface');
    if (hasBlueFactor1 && !isBlue) parts.add('Blue Factor I');
    if (hasBlueFactor2 && !isBlue) parts.add('Blue Factor II');
  }
}

/// Adds base color naming with grey, violet, and dark factor logic.
void _addBaseColorNaming(
  List<String> parts, {
  required bool isBlue,
  required bool hasGrey,
  required bool hasViolet,
  required int darkFactorCount,
  required _BaseColor baseColor,
  required Set<String> doubleFactorIds,
}) {
  if (hasGrey) {
    // Grey with dark factor naming:
    // Green: Light Grey-Green (0DF), Dark Grey-Green (1DF), Olive Grey-Green (2DF)
    // Blue: Grey (0DF), Dark Grey (1DF), Mauve Grey (2DF)
    final greyPrefix = switch (darkFactorCount) {
      0 => '',
      1 => isBlue ? 'Dark ' : 'Dark ',
      >= 2 => isBlue ? 'Mauve ' : 'Olive ',
      _ => '',
    };
    if (isBlue) {
      parts.add('${greyPrefix}Grey');
    } else {
      parts.add('${greyPrefix}Grey-Green');
    }
  }

  // Visual Violet: best on Cobalt (Blue+1DF+V) or Double Violet on Skyblue
  final isDoubleViolet = hasViolet && doubleFactorIds.contains('violet');
  if (hasViolet && isBlue && (darkFactorCount == 1 || isDoubleViolet)) {
    parts.add('Visual Violet');
  } else if (hasViolet) {
    parts.add('Violet');
  }

  // Base color + dark factor naming (skipped for Grey -- already handled above)
  if (!hasGrey) {
    final baseName = _resolveBaseColorName(baseColor, darkFactorCount);
    if (baseName != null) {
      parts.add(baseName);
    }
  }
}

/// Adds pattern mutations, melanin modifiers, pied, fallow, crest,
/// clearbody, and saddleback naming (steps 9-15).
void _addPatternAndModifierNaming(
  List<String> parts, {
  required Set<String> visualMutations,
  required Set<String> doubleFactorIds,
  required bool hasIno,
  required bool hasCinnamon,
  required bool hasBlackface,
}) {
  // 9. Pattern mutations (order: Spangle > Opaline > Clearwing/Greywing)
  if (!hasIno || (hasIno && hasCinnamon)) {
    // Lacewing shows patterns, pure Ino doesn't
    final hasSpangle = visualMutations.contains('spangle');
    final isDoubleSpangle = hasSpangle && doubleFactorIds.contains('spangle');
    final hasOpaline = visualMutations.contains('opaline');
    final hasPearly = visualMutations.contains('pearly');
    final hasClearwing = visualMutations.contains('clearwing');
    final hasGreywing = visualMutations.contains('greywing');
    // Full-Body Greywing: compound heterozygote of greywing + clearwing
    final hasFullBodyGreywing = hasGreywing && hasClearwing;

    if (isDoubleSpangle) {
      if (hasBlackface) {
        parts.add('Melanistic Double Factor Spangle');
      } else {
        parts.add('Double Factor Spangle');
      }
    } else if (hasSpangle) {
      if (hasBlackface) {
        parts.add('Melanistic Spangle');
      } else {
        parts.add('Spangle');
      }
    }

    if (hasOpaline) parts.add('Opaline');
    if (hasPearly) parts.add('Pearly');

    if (hasFullBodyGreywing) {
      parts.add('Full-Body Greywing');
    } else if (hasGreywing) {
      parts.add('Greywing');
    } else if (hasClearwing) {
      parts.add('Clearwing');
    }
  }

  // 10. Melanin modifiers (if not already covered by Ino/Lacewing)
  if (!hasIno) {
    if (hasCinnamon) parts.add('Cinnamon');
    if (visualMutations.contains('dilute')) parts.add('Dilute');
    if (visualMutations.contains('slate')) parts.add('Slate');
    if (visualMutations.contains('anthracite')) {
      if (doubleFactorIds.contains('anthracite')) {
        parts.add('Double Factor Anthracite');
      } else {
        parts.add('Single Factor Anthracite');
      }
    }
    if (visualMutations.contains('pallid')) parts.add('Pallid');
  }

  // 11. Pied mutations + Dark-Eyed Clear detection
  _addPiedNaming(parts, visualMutations);

  // 12. Fallow
  if (visualMutations.contains('fallow_english')) {
    parts.add('English Fallow');
  }
  if (visualMutations.contains('fallow_german')) {
    parts.add('German Fallow');
  }

  // 13. Feather structure (crested compound heterozygote detection)
  _addCrestedNaming(parts, visualMutations);

  // 14. Clearbody
  if (visualMutations.contains('texas_clearbody')) {
    parts.add('Texas Clearbody');
  }
  if (visualMutations.contains('dominant_clearbody')) {
    parts.add('Dominant Clearbody');
  }

  // 15. Saddleback
  if (visualMutations.contains('saddleback')) {
    parts.add('Saddleback');
  }
  if (hasBlackface && !visualMutations.contains('spangle')) {
    parts.add('Blackface');
  }
}

/// Adds pied mutation naming including Dark-Eyed Clear detection.
void _addPiedNaming(List<String> parts, Set<String> visualMutations) {
  final hasRecessivePied = visualMutations.contains('recessive_pied');
  final hasClearflightPied = visualMutations.contains('clearflight_pied');
  final hasDominantPied = visualMutations.contains('dominant_pied');
  final hasDutchPied = visualMutations.contains('dutch_pied');

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
            'crested_tufted' => 'Tufted',
            'crested_half_circular' => 'Half-Circular',
            'crested_full_circular' => 'Full-Circular',
            _ => id,
          },
        )
        .toList();
    parts.add('${labels.join('/')} Compound Crest');
  } else {
    if (visualMutations.contains('crested_tufted')) {
      parts.add('Tufted');
    }
    if (visualMutations.contains('crested_half_circular')) {
      parts.add('Half-Circular Crest');
    }
    if (visualMutations.contains('crested_full_circular')) {
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
