import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';

/// Yellowface / Blue Series allelic locus mutations and legacy ID mappings.
///
/// Part of [MutationData] — see `mutation_data.dart` for the unified list.
abstract class MutationDataCompounds {
  /// Yellowface and Blue Series allelic locus mutations.
  static const List<BudgieMutationRecord> yellowfaceMutations = [
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

  /// Legacy ID to current ID mapping for backward compatibility with saved data.
  static const legacyIdMap = {
    'dark_factor_single': 'dark_factor',
    'dark_factor_double': 'dark_factor',
    'spangle_single': 'spangle',
    'spangle_double': 'spangle',
    'fullbody_greywing': 'greywing',
    'lacewing': GeneticsConstants.mutIno,
    'pallidino': GeneticsConstants.mutPallid,
    'lutino': GeneticsConstants.mutIno,
    'albino': GeneticsConstants.mutIno,
  };
}
