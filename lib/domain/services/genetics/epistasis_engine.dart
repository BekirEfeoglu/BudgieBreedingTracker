import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';

/// Result of compound phenotype resolution, including masked mutations.
class CompoundPhenotypeResult {
  /// The resolved compound phenotype name (e.g., "Albino", "Cobalt Opaline").
  final String name;

  /// Mutations masked by Ino that are genetically present but not visible.
  /// e.g., an Albino bird may carry Opaline, Dark Factor hidden under Ino.
  final List<String> maskedMutations;

  const CompoundPhenotypeResult({
    required this.name,
    this.maskedMutations = const [],
  });
}

/// Epistasis engine for resolving compound phenotype names
/// from multiple interacting mutations in budgies.
///
/// Handles gene interactions such as:
/// - Ino + Blue = Albino
/// - Ino + Green = Lutino
/// - Cinnamon + Ino = Lacewing
/// - Dark Factor dosage + Base Color = variety naming
/// - Violet + Blue + 1DF = Visual Violet
/// - Grey + Green = Grey-Green, Grey + Blue = Grey
/// - Yellowface Type 2 + Blue + Ino = Creamino
/// - Yellowface Type 1 DF = White-faced (paradoxical)
/// - Recessive Pied + Clearflight Pied = Dark-Eyed Clear
class EpistasisEngine {
  const EpistasisEngine();

  /// Resolves a compound phenotype name from a set of visual mutation IDs.
  ///
  /// Returns a human-readable compound name (e.g., "Cobalt Opaline Spangle")
  /// or "Normal" if no special epistatic naming applies.
  String resolveCompoundPhenotype(Set<String> visualMutations) {
    return resolveCompoundPhenotypeDetailed(visualMutations).name;
  }

  /// Resolves compound phenotype with detailed info including masked mutations.
  ///
  /// [doubleFactorIds] contains mutation IDs that are homozygous (double factor)
  /// in this particular offspring. Used for incomplete dominant special naming
  /// (e.g., Yellowface Type I DF → Whitefaced paradox).
  CompoundPhenotypeResult resolveCompoundPhenotypeDetailed(
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
      // Yellowface + Ino but not Creamino → just note Yellowface
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

    // 8. Build base color name with dark factor
    if (!hasIno) {
      // Only name base color if not Ino (Ino overrides everything)
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

      // Visual Violet: best on Cobalt (Blue+1DF+V) or Double Violet on Skyblue (Blue+0DF+VV)
      final isDoubleViolet = hasViolet && doubleFactorIds.contains('violet');
      if (hasViolet && isBlue && (darkFactorCount == 1 || isDoubleViolet)) {
        parts.add('Visual Violet');
      } else if (hasViolet) {
        parts.add('Violet');
      }

      // Base color + dark factor naming (skipped for Grey — already handled above)
      if (!hasGrey) {
        final baseName = _resolveBaseColorName(
          baseColor,
          darkFactorCount,
        );
        if (baseName != null) {
          parts.add(baseName);
        }
      }
    }

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

    // 12. Fallow
    if (visualMutations.contains('fallow_english')) {
      parts.add('English Fallow');
    }
    if (visualMutations.contains('fallow_german')) {
      parts.add('German Fallow');
    }

    // 13. Feather structure (crested compound heterozygote detection)
    final activeCrested = GeneticsConstants.crestedAlleleIds
        .where(visualMutations.contains)
        .toList();
    if (activeCrested.length >= 2) {
      // Compound heterozygote: two different crested alleles
      final labels = activeCrested.map((id) => switch (id) {
        'crested_tufted' => 'Tufted',
        'crested_half_circular' => 'Half-Circular',
        'crested_full_circular' => 'Full-Circular',
        _ => id,
      }).toList();
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

    final uniqueParts = <String>[];
    for (final part in parts) {
      if (!uniqueParts.contains(part)) uniqueParts.add(part);
    }

    final name = uniqueParts.isEmpty ? 'Normal' : uniqueParts.join(' ');
    return CompoundPhenotypeResult(name: name, maskedMutations: masked);
  }

  /// Returns a list of epistatic interactions detected in the mutation set.
  List<EpistaticInteraction> getInteractions(Set<String> mutations) {
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

    // Yellowface on green series → no visible effect
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

  /// Resolves base color name from base color series and dark factor count.
  String? _resolveBaseColorName(
    _BaseColor base,
    int darkFactorCount,
  ) {
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
}

/// Internal enum for base color series.
enum _BaseColor { green, blue }

/// Represents an epistatic interaction between mutations.
class EpistaticInteraction {
  /// IDs of the mutations involved in this interaction.
  final List<String> mutationIds;

  /// Name of the resulting compound phenotype.
  final String resultName;

  /// Human-readable description of the interaction.
  final String description;

  const EpistaticInteraction({
    required this.mutationIds,
    required this.resultName,
    required this.description,
  });
}
