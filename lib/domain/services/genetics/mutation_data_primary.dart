import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';

/// Primary budgie mutations: autosomal recessive, dominant, and
/// incomplete dominant mutations.
///
/// Part of [MutationData] — see `mutation_data.dart` for the unified list.
abstract class MutationDataPrimary {
  /// Core autosomal mutations (Blue Series, Dilution, Dark Factor, Violet,
  /// Grey, Anthracite, Blackface, Spangle, and Pied mutations).
  static const List<BudgieMutationRecord> coreMutations = [
    // ── Blue Series Allelic Locus ──
    // Note: blue is autosomalRecessive individually but shares locusId 'blue_series'
    // with yellowface/goldenface (incompleteDominant). The allelic series calculator
    // uses locusId + dominanceRank for cross results, not individual inheritanceType.
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
          'Clear flight feathers and tail with normal body - recessive',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'cf',
      alleles: ['cf+', 'cf'],
      category: 'Pied',
      visualEffect: 'Clear flight and tail feathers, small head patch',
    ),
    // Note: Dutch Pied inheritance is debated (dominant vs recessive).
    // Current classification follows the dominant interpretation.
    BudgieMutationRecord(
      id: 'dutch_pied',
      name: 'Dutch Pied',
      localizationKey: 'genetics.mutation_dutch_pied',
      description:
          'Pied variant with variable clear patches and normal iris ring',
      inheritanceType: InheritanceType.autosomalDominant,
      dominance: Dominance.dominant,
      alleleSymbol: 'Dp',
      alleles: ['Dp+', 'Dp'],
      category: 'Pied',
      visualEffect: 'Irregular pied pattern with preserved body saturation',
    ),
  ];
}
