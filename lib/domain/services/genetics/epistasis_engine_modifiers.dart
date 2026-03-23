part of 'epistasis_engine.dart';

// Phenotype display names in this file (e.g., "Whitefaced", "Yellowface Type I")
// are standardized English aviculture terms from WBO/MUTAVI nomenclature.
// UI localization is handled by PhenotypeLocalizer in the features layer,
// which maps these English terms to localized display names via .tr() keys.

/// Adds Ino-specific naming: Albino/Lutino/Lacewing/Creamino/PallidIno.
void _addInoNaming(
  List<String> parts, {
  required bool hasIno,
  required bool hasCinnamon,
  required bool hasPallid,
  required bool hasYf2,
  required bool hasGoldenface,
  required bool hasBlueFactor1,
  required bool hasBlueFactor2,
  required bool isBlue,
}) {
  if (!hasIno) return;
  if (hasPallid) {
    parts.add('PallidIno (Lacewing)');
  } else if ((hasYf2 || hasGoldenface || hasBlueFactor1 || hasBlueFactor2) &&
      isBlue) {
    parts.add('Creamino');
  } else if (hasCinnamon) {
    parts.add('Lacewing');
  } else if (isBlue) {
    parts.add('Albino');
  } else {
    parts.add('Lutino');
  }
}

/// Collects mutations masked by Ino (genetically present but not visible).
void _collectMaskedMutations(
  Set<String> visualMutations,
  Set<String> doubleFactorIds,
  bool hasCinnamon,
  List<String> parts,
  List<String> masked,
) {
  // Ino masks all melanin-based mutations visually
  if (visualMutations.contains(GeneticsConstants.mutOpaline)) masked.add('Opaline');
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
  if (visualMutations.contains(GeneticsConstants.mutSlate)) masked.add('Slate');
  if (visualMutations.contains('clearwing')) masked.add('Clearwing');
  if (visualMutations.contains('greywing')) masked.add('Greywing');
  if (visualMutations.contains(GeneticsConstants.mutPearly)) masked.add('Pearly');
  if (visualMutations.contains(GeneticsConstants.mutPallid)) masked.add('Pallid');
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
        // Whitefaced paradox: suppress for Ino+Blue (already Albino)
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
  if (!hasIno) {
    // Ino masks all pattern mutations; Lacewing only reveals cinnamon markings
    final hasSpangle = visualMutations.contains('spangle');
    final isDoubleSpangle = hasSpangle && doubleFactorIds.contains('spangle');
    final hasOpaline = visualMutations.contains(GeneticsConstants.mutOpaline);
    final hasPearly = visualMutations.contains(GeneticsConstants.mutPearly);
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
    if (visualMutations.contains(GeneticsConstants.mutSlate)) parts.add('Slate');
    if (visualMutations.contains('anthracite')) {
      if (doubleFactorIds.contains('anthracite')) {
        parts.add('Double Factor Anthracite');
      } else {
        parts.add('Single Factor Anthracite');
      }
    }
    if (visualMutations.contains(GeneticsConstants.mutPallid)) parts.add('Pallid');
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
  if (visualMutations.contains(GeneticsConstants.mutTexasClearbody)) {
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

