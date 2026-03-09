import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';

/// Static catalog of budgie (Melopsittacus undulatus) mutations currently
/// modelled by the app.
abstract class MutationData {
  /// All known budgie mutations.
  static const List<BudgieMutationRecord> allMutations = [
    // ── Blue Series Allelic Locus ──
    // blue / yellowface_type1 / yellowface_type2 / goldenface / turquoise /
    // aqua / bluefactor_1 / bluefactor_2
    BudgieMutationRecord(
      id: 'blue',
      name: 'Blue',
      localizationKey: 'genetics.mutation_blue',
      description:
          'Removes yellow pigment (psittacin), leaving blue structural color',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'bl',
      alleles: ['bl+', 'bl'],
      category: 'Blue / Yellowface',
      visualEffect: 'Green becomes Blue, Yellow becomes White',
      locusId: 'blue_series',
      dominanceRank: 1,
    ),

    // ── Dilution Allelic Locus (greywing / clearwing / dilute) ──
    // These are alleles of the same gene: wild-type(+) > greywing ≈ clearwing > dilute
    // Greywing/Clearwing compound heterozygote = Full-Body Greywing (calculator produces this)
    BudgieMutationRecord(
      id: 'dilute',
      name: 'Dilute',
      localizationKey: 'genetics.mutation_dilute',
      description: 'Dilutes melanin to approximately 30% of normal',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'dil',
      alleles: ['dil+', 'dil'],
      category: 'Dilution',
      visualEffect:
          'Light Green becomes Light Yellow, Cobalt becomes Mauve-tint',
      locusId: 'dilution',
      dominanceRank: 1,
    ),
    BudgieMutationRecord(
      id: 'greywing',
      name: 'Greywing',
      localizationKey: 'genetics.mutation_greywing',
      description:
          'Dilutes wing markings to grey while body color is partially diluted',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'gw',
      alleles: ['gw+', 'gw'],
      category: 'Dilution',
      visualEffect: 'Wing markings become grey, body 50% diluted',
      locusId: 'dilution',
      dominanceRank: 3,
    ),
    BudgieMutationRecord(
      id: 'clearwing',
      name: 'Clearwing',
      localizationKey: 'genetics.mutation_clearwing',
      description: 'Dilutes wing markings with intensified body color',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'cw',
      alleles: ['cw+', 'cw'],
      category: 'Dilution',
      visualEffect: 'Light wing markings with bright body color',
      locusId: 'dilution',
      dominanceRank: 3,
    ),

    // ── Dark Factor (Autosomal Incomplete Dominant) ──
    // Single locus: 0 copies = normal, 1 copy (SF) = one shade darker, 2 copies (DF) = two shades darker
    BudgieMutationRecord(
      id: 'dark_factor',
      name: 'Dark Factor',
      localizationKey: 'genetics.mutation_dark_factor',
      description:
          'Incomplete dominant: SF darkens one shade, DF darkens two shades',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'D',
      alleles: ['D+', 'D'],
      category: 'Dark Factor',
      visualEffect:
          'SF: Light Green→Dark Green / Skyblue→Cobalt. DF: Light Green→Olive / Skyblue→Mauve',
    ),

    // ── Violet Factor (Autosomal Incomplete Dominant) ──
    BudgieMutationRecord(
      id: 'violet',
      name: 'Violet',
      localizationKey: 'genetics.mutation_violet',
      description: 'Modifies blue pigment to produce violet hue',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'V',
      alleles: ['V+', 'V'],
      category: 'Violet',
      visualEffect: 'Best visible on single dark factor blue (Visual Violet)',
    ),

    // ── Grey Factor (Autosomal Dominant) ──
    BudgieMutationRecord(
      id: 'grey',
      name: 'Grey',
      localizationKey: 'genetics.mutation_grey',
      description: 'Adds grey overtone to the base color',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'G',
      alleles: ['G+', 'G'],
      category: 'Grey',
      visualEffect: 'Green becomes Grey-Green, Blue becomes Grey',
    ),
    BudgieMutationRecord(
      id: 'anthracite',
      name: 'Anthracite',
      localizationKey: 'genetics.mutation_anthracite',
      description:
          'Darkening factor with dose-dependent effect, strongest in blue series',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'An',
      alleles: ['An+', 'An'],
      category: 'Melanin Modifier',
      visualEffect: 'SF: deepened tone, DF: near-charcoal body color',
    ),
    BudgieMutationRecord(
      id: 'blackface',
      name: 'Blackface',
      localizationKey: 'genetics.mutation_blackface',
      description: 'Increases dark melanin expression in the facial mask area',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'Bf',
      alleles: ['Bf+', 'Bf'],
      category: 'Pattern',
      visualEffect: 'Expanded dark facial markings and stronger contrast',
    ),

    // ── Spangle (Autosomal Incomplete Dominant) ──
    // Single locus: 0 copies = normal, 1 copy (SF) = reversed markings, 2 copies (DF) = near-solid
    BudgieMutationRecord(
      id: 'spangle',
      name: 'Spangle',
      localizationKey: 'genetics.mutation_spangle',
      description:
          'Incomplete dominant: SF reverses wing markings, DF produces near-solid color',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'Sp',
      alleles: ['Sp+', 'Sp'],
      category: 'Pattern',
      visualEffect:
          'SF: Reversed wing markings. DF: Almost entirely yellow/white',
    ),

    // ── Pied Mutations ──
    BudgieMutationRecord(
      id: 'recessive_pied',
      name: 'Recessive Pied',
      localizationKey: 'genetics.mutation_recessive_pied',
      description: 'Random patches of clear (non-melanin) feathers',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'pi',
      alleles: ['pi+', 'pi'],
      category: 'Pied',
      visualEffect: 'Random clear patches, often solid-colored eyes',
    ),
    BudgieMutationRecord(
      id: 'dominant_pied',
      name: 'Dominant Pied (Australian)',
      localizationKey: 'genetics.mutation_dominant_pied',
      description: 'Band of clear feathers across body',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'Pi',
      alleles: ['Pi+', 'Pi'],
      category: 'Pied',
      visualEffect: 'Clear band across chest/belly area',
    ),
    BudgieMutationRecord(
      id: 'clearflight_pied',
      name: 'Clearflight Pied',
      localizationKey: 'genetics.mutation_clearflight_pied',
      description:
          'Clear flight feathers and tail with normal body - dominant to normal',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'Cf',
      alleles: ['Cf+', 'Cf'],
      category: 'Pied',
      visualEffect: 'Clear flight and tail feathers, small head patch',
    ),
    BudgieMutationRecord(
      id: 'dutch_pied',
      name: 'Dutch Pied',
      localizationKey: 'genetics.mutation_dutch_pied',
      description:
          'Dominant pied variant with variable clear patches and normal iris ring',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'Dp',
      alleles: ['Dp+', 'Dp'],
      category: 'Pied',
      visualEffect: 'Irregular pied pattern with preserved body saturation',
    ),

    // ── Sex-Linked Recessive Mutations ──
    BudgieMutationRecord(
      id: 'pallid',
      name: 'Pallid',
      localizationKey: 'genetics.mutation_pallid',
      description:
          'Sex-linked allele at ino locus reducing melanin without full Ino depigmentation',
      inheritanceType: InheritanceType.sexLinkedRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'pal',
      alleles: ['pal+', 'pal'],
      category: 'Ino',
      visualEffect:
          'Softened markings with diluted melanin and clearer body tone',
      locusId: 'ino_locus',
      dominanceRank: 3,
    ),
    BudgieMutationRecord(
      id: 'ino',
      name: 'Ino',
      localizationKey: 'genetics.mutation_ino',
      description:
          'Removes all melanin (ino gene on Z chromosome). '
          'Green series = Lutino (yellow), Blue series = Albino (white)',
      inheritanceType: InheritanceType.sexLinkedRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'ino',
      alleles: ['ino+', 'ino'],
      category: 'Ino',
      visualEffect: 'Green series = Lutino, Blue series = Albino',
      locusId: 'ino_locus',
      dominanceRank: 1,
    ),
    BudgieMutationRecord(
      id: 'opaline',
      name: 'Opaline',
      localizationKey: 'genetics.mutation_opaline',
      description:
          'Reduces head/wing markings and increases body color on mantle',
      inheritanceType: InheritanceType.sexLinkedRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'op',
      alleles: ['op+', 'op'],
      category: 'Pattern',
      visualEffect: 'V-shaped mantle, reduced barring on head and wings',
    ),
    BudgieMutationRecord(
      id: 'pearly',
      name: 'Pearly',
      localizationKey: 'genetics.mutation_pearly',
      description:
          'Sex-linked pattern modifier producing pearled edging on wing markings',
      inheritanceType: InheritanceType.sexLinkedRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'prl',
      alleles: ['prl+', 'prl'],
      category: 'Pattern',
      visualEffect: 'Pearled wing pattern with softened edging',
    ),
    BudgieMutationRecord(
      id: 'cinnamon',
      name: 'Cinnamon',
      localizationKey: 'genetics.mutation_cinnamon',
      description: 'Converts black melanin to brown',
      inheritanceType: InheritanceType.sexLinkedRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'cin',
      alleles: ['cin+', 'cin'],
      category: 'Melanin Modifier',
      visualEffect: 'Brown markings instead of black, warm body tone',
    ),
    BudgieMutationRecord(
      id: 'slate',
      name: 'Slate',
      localizationKey: 'genetics.mutation_slate',
      description: 'Modifies melanin structure to produce slate-blue tone',
      inheritanceType: InheritanceType.sexLinkedRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'sl',
      alleles: ['sl+', 'sl'],
      category: 'Melanin Modifier',
      // Note: Slate is on the Z chromosome but its map distance to
      // Opaline/Cinnamon/Ino is not well-characterised in literature.
      // Linkage is assumed independent until reliable recombination
      // data becomes available.
      visualEffect: 'Dark slate-blue body color',
    ),

    // ── Rare / Newer Mutations ──
    BudgieMutationRecord(
      id: 'fallow_english',
      name: 'Fallow (English)',
      localizationKey: 'genetics.mutation_fallow_english',
      description: 'Reduces melanin with distinctive red/plum eye color',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'fe',
      alleles: ['fe+', 'fe'],
      category: 'Fallow',
      visualEffect: 'Muted markings, red/plum eyes, warm body color',
    ),
    BudgieMutationRecord(
      id: 'fallow_german',
      name: 'Fallow (German)',
      localizationKey: 'genetics.mutation_fallow_german',
      description: 'Similar to English Fallow but different gene locus',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'fg',
      alleles: ['fg+', 'fg'],
      category: 'Fallow',
      visualEffect: 'Brighter body than English, plum eyes',
    ),
    BudgieMutationRecord(
      id: 'saddleback',
      name: 'Saddleback',
      localizationKey: 'genetics.mutation_saddleback',
      description: 'V-shaped marking on mantle area',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'sb',
      alleles: ['sb+', 'sb'],
      category: 'Pattern',
      visualEffect: 'Clear V-shaped area on back with normal wing markings',
    ),
    // ── Crested Allelic Locus (tufted / half-circular / full-circular) ──
    // All crested types share the same gene locus on an autosome.
    // Different alleles produce different crest shapes.
    // Pairings are treated as sub-vital risk in viability analysis.
    BudgieMutationRecord(
      id: 'crested_tufted',
      name: 'Crested (Tufted)',
      localizationKey: 'genetics.mutation_crested_tufted',
      description:
          'Circular crest on top of head. Dominant factor with sub-vital risk in crested pairings',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'Cr',
      alleles: ['Cr+', 'Cr'],
      category: 'Feather Structure',
      visualEffect: 'Circular tuft of feathers on crown',
      locusId: 'crested',
      dominanceRank: 3,
    ),
    BudgieMutationRecord(
      id: 'crested_half_circular',
      name: 'Crested (Half-Circular)',
      localizationKey: 'genetics.mutation_crested_half_circular',
      description:
          'Half-circular crest on front of head. Dominant factor with sub-vital risk in crested pairings',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'Crhc',
      alleles: ['Cr+', 'Crhc'],
      category: 'Feather Structure',
      visualEffect: 'Half-circle crest falling forward',
      locusId: 'crested',
      dominanceRank: 2,
    ),
    BudgieMutationRecord(
      id: 'crested_full_circular',
      name: 'Crested (Full-Circular)',
      localizationKey: 'genetics.mutation_crested_full_circular',
      description:
          'Full circular crest radiating from center point. Dominant factor with sub-vital risk in crested pairings',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'Crfc',
      alleles: ['Cr+', 'Crfc'],
      category: 'Feather Structure',
      visualEffect: 'Full circular corona crest',
      locusId: 'crested',
      dominanceRank: 1,
    ),
    // Lacewing removed: it's a phenotype from Cinnamon + Ino combination,
    // not a separate mutation. The calculator/epistasis engine produces it.
    BudgieMutationRecord(
      id: 'texas_clearbody',
      name: 'Texas Clearbody',
      localizationKey: 'genetics.mutation_texas_clearbody',
      description: 'Reduces body melanin while keeping wing markings',
      inheritanceType: InheritanceType.sexLinkedRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'tcb',
      alleles: ['tcb+', 'tcb'],
      category: 'Clearbody',
      visualEffect: 'Bright body color with normal dark wing markings',
      locusId: 'ino_locus',
      dominanceRank: 2,
    ),
    BudgieMutationRecord(
      id: 'dominant_clearbody',
      name: 'Dominant Clearbody',
      localizationKey: 'genetics.mutation_dominant_clearbody',
      description:
          'Autosomal dominant clearbody form with reduced body melanin expression',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'Dcb',
      alleles: ['Dcb+', 'Dcb'],
      category: 'Clearbody',
      visualEffect: 'Cleaner body color with retained wing markings',
    ),

    // ── Yellowface Mutations — part of Blue Series allelic locus ──
    BudgieMutationRecord(
      id: 'yellowface_type1',
      name: 'Yellowface Type I',
      localizationKey: 'genetics.mutation_yellowface_type1',
      description:
          'Single factor: yellow mask on blue body. Double factor: white-faced (paradoxical loss)',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'Yf1',
      alleles: ['Yf1+', 'Yf1'],
      category: 'Blue / Yellowface',
      visualEffect: 'SF: yellow mask on blue body, DF: white-faced (no yellow)',
      locusId: 'blue_series',
      dominanceRank: 2,
    ),
    BudgieMutationRecord(
      id: 'yellowface_type2',
      name: 'Yellowface Type II',
      localizationKey: 'genetics.mutation_yellowface_type2',
      description:
          'Single factor: yellow mask with yellow body suffusion. Double factor: stronger suffusion',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'Yf2',
      alleles: ['Yf2+', 'Yf2'],
      category: 'Blue / Yellowface',
      visualEffect:
          'SF: yellow mask + body suffusion, DF: stronger yellow throughout',
      locusId: 'blue_series',
      dominanceRank: 3,
    ),
    BudgieMutationRecord(
      id: 'goldenface',
      name: 'Goldenface',
      localizationKey: 'genetics.mutation_goldenface',
      description:
          'Intense yellowface allele with stronger mask pigmentation and body suffusion',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'Gf',
      alleles: ['Gf+', 'Gf'],
      category: 'Blue / Yellowface',
      visualEffect:
          'Deep golden mask; stronger yellow suffusion on blue series',
      locusId: 'blue_series',
      dominanceRank: 4,
    ),
    BudgieMutationRecord(
      id: 'aqua',
      name: 'Aqua',
      localizationKey: 'genetics.mutation_aqua',
      description:
          'Parblue-type allele at the blue locus producing aqua-toned body color',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'Aq',
      alleles: ['Aq+', 'Aq'],
      category: 'Blue / Yellowface',
      visualEffect: 'Blue series shifts toward aqua/turquoise tones',
      locusId: 'blue_series',
      dominanceRank: 5,
    ),
    BudgieMutationRecord(
      id: 'turquoise',
      name: 'Turquoise',
      localizationKey: 'genetics.mutation_turquoise',
      description:
          'Parblue-type allele with stronger green-blue suffusion than aqua',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'Tq',
      alleles: ['Tq+', 'Tq'],
      category: 'Blue / Yellowface',
      visualEffect: 'Blue series shifts to richer turquoise shades',
      locusId: 'blue_series',
      dominanceRank: 6,
    ),
    BudgieMutationRecord(
      id: 'bluefactor_1',
      name: 'Blue Factor I',
      localizationKey: 'genetics.mutation_bluefactor_1',
      description:
          'Parblue-range allele used in some standards to represent lighter blue-factor expression',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'Bf1',
      alleles: ['Bf1+', 'Bf1'],
      category: 'Blue / Yellowface',
      visualEffect: 'Blue-series expression with mild greenish suffusion',
      locusId: 'blue_series',
      dominanceRank: 7,
    ),
    BudgieMutationRecord(
      id: 'bluefactor_2',
      name: 'Blue Factor II',
      localizationKey: 'genetics.mutation_bluefactor_2',
      description:
          'Parblue-range allele used in some standards for deeper blue-factor expression',
      inheritanceType: InheritanceType.autosomalIncompleteDominant,
      dominance: Dominance.incompleteDominant,
      alleleSymbol: 'Bf2',
      alleles: ['Bf2+', 'Bf2'],
      category: 'Blue / Yellowface',
      visualEffect:
          'Blue-series expression with stronger suffusion than Blue Factor I',
      locusId: 'blue_series',
      dominanceRank: 8,
    ),
  ];

  /// Legacy ID → current ID mapping for backward compatibility with saved data.
  static const legacyIdMap = {
    'dark_factor_single': 'dark_factor',
    'dark_factor_double': 'dark_factor',
    'spangle_single': 'spangle',
    'spangle_double': 'spangle',
    'fullbody_greywing': 'greywing',
    'lacewing': 'ino',
    'pallidino': 'pallid',
    'lutino': 'ino',
    'albino': 'ino',
  };
}
