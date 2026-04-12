import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';

/// Sex-linked recessive, rare/newer, crested, and clearbody mutations.
///
/// Part of [MutationData] — see `mutation_data.dart` for the unified list.
abstract class MutationDataSexLinked {
  /// Sex-linked recessive, rare, crested, and clearbody mutations.
  static const List<BudgieMutationRecord> sexLinkedAndRareMutations = [
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
      dominanceRank: 2,
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
    // Note: Pearly's placement at ino_locus is based on current WBO classification.
    // Some researchers debate this — if evidence changes, move to own locus.
    BudgieMutationRecord(
      id: 'pearly',
      name: 'Pearly',
      localizationKey: 'genetics.mutation_pearly',
      description:
          'Ino-locus allele (ino^py) producing pearled edging on wing markings',
      inheritanceType: InheritanceType.sexLinkedRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'prl',
      alleles: ['prl+', 'prl'],
      category: 'Ino',
      visualEffect: 'Pearled wing pattern with softened edging',
      locusId: 'ino_locus',
      dominanceRank: 3,
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
    // Scottish Fallow (Bronze Fallow) — third recognized fallow type.
    // Distinct locus from English and German Fallow.
    BudgieMutationRecord(
      id: 'fallow_scottish',
      name: 'Fallow (Scottish)',
      localizationKey: 'genetics.mutation_fallow_scottish',
      description:
          'Third fallow type, also known as Bronze Fallow. Distinct gene locus from English and German',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'fs',
      alleles: ['fs+', 'fs'],
      category: 'Fallow',
      visualEffect: 'Bronze-toned markings, solid red eyes, warm body color',
    ),
    // Faded — reduces melanin intensity differently from Dilute.
    BudgieMutationRecord(
      id: 'faded',
      name: 'Faded',
      localizationKey: 'genetics.mutation_faded',
      description: 'Progressive melanin reduction producing a washed-out appearance',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'fd',
      alleles: ['fd+', 'fd'],
      category: 'Melanin Modifier',
      visualEffect: 'Washed-out body color with faded wing markings',
    ),
    // Mottled — progressive loss of melanin patches with each moult.
    BudgieMutationRecord(
      id: 'mottled',
      name: 'Mottled',
      localizationKey: 'genetics.mutation_mottled',
      description:
          'Progressive mutation where melanin patches disappear with each moult cycle',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'mo',
      alleles: ['mo+', 'mo'],
      category: 'Pattern',
      visualEffect: 'Increasing clear patches with each moult, variable expression',
    ),
    // Feather Duster — always lethal condition with continuously growing feathers.
    // Homozygous recessive. Affected chicks rarely survive beyond a few months.
    BudgieMutationRecord(
      id: 'feather_duster',
      name: 'Feather Duster',
      localizationKey: 'genetics.mutation_feather_duster',
      description:
          'Lethal autosomal recessive causing continuously growing, curly feathers. '
          'Homozygous birds (fd/fd) rarely survive beyond a few months',
      inheritanceType: InheritanceType.autosomalRecessive,
      dominance: Dominance.recessive,
      alleleSymbol: 'fdu',
      alleles: ['fdu+', 'fdu'],
      category: 'Feather Structure',
      visualEffect: 'Long, curly, continuously growing feathers; inability to fly',
    ),

    // ── Crested Allelic Locus ──
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
      dominanceRank: 4,
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
  ];
}
