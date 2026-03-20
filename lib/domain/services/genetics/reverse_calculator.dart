import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator_helpers.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator_models.dart';

export 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator_helpers.dart';
export 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator_models.dart';

class ReverseCalculator {
  static const int _maxOptionsPerLocus =
      GeneticsConstants.reverseMaxOptionsPerLocus;
  static const int _maxIntermediateCombinations =
      GeneticsConstants.reverseMaxIntermediateCombinations;
  static const int _maxFinalCombinations =
      GeneticsConstants.reverseMaxFinalCombinations;

  const ReverseCalculator();

  /// Calculates potential parent genotypes that yield the given target mutations.
  ///
  /// The [targetMutationIds] must be the exact visual mutations desired
  /// in the offspring.
  List<ReverseCalculationResult> calculateParents(
    Set<String> targetMutationIds,
  ) {
    if (targetMutationIds.isEmpty) return [];

    // Group target mutations by locus
    final Map<String, List<String>> targetLoci = {};
    for (final mutId in targetMutationIds) {
      final record = MutationDatabase.getById(mutId);
      if (record != null) {
        targetLoci.putIfAbsent(record.locusId ?? mutId, () => []).add(mutId);
      }
    }

    const calculator = MendelianCalculator();
    final List<List<LocusPairResult>> locusOptions = [];

    for (final entry in targetLoci.entries) {
      final locusId = entry.key;
      final targetIdsAtLocus = entry.value;

      final optionsAtLocus = _findValidPairsForLocus(
        locusId,
        targetIdsAtLocus,
        calculator,
      );

      if (optionsAtLocus.isEmpty) {
        return []; // Impossible combination at this locus
      }
      locusOptions.add(optionsAtLocus);
    }

    final combinations = ReverseCalculatorHelpers.combineLocusOptions(
      locusOptions,
      maxIntermediateCombinations: _maxIntermediateCombinations,
      maxFinalCombinations: _maxFinalCombinations,
    );

    combinations.sort((a, b) => b.maxProbability.compareTo(a.maxProbability));

    return combinations.take(25).toList();
  }

  List<LocusPairResult> _findValidPairsForLocus(
    String locusId,
    List<String> targetIdsAtLocus,
    MendelianCalculator calculator,
  ) {
    final fatherGenotypes =
        ReverseCalculatorHelpers.generateAllGenotypesAtLocus(
      locusId,
      BirdGender.male,
    );
    final motherGenotypes =
        ReverseCalculatorHelpers.generateAllGenotypesAtLocus(
      locusId,
      BirdGender.female,
    );

    final List<LocusPairResult> validPairs = [];

    for (final fg in fatherGenotypes) {
      for (final mg in motherGenotypes) {
        if (!ReverseCalculatorHelpers.canPossiblyProduceTargets(
          fg,
          mg,
          targetIdsAtLocus,
        )) {
          continue;
        }

        final father = ParentGenotype(gender: BirdGender.male, mutations: fg);
        final mother = ParentGenotype(gender: BirdGender.female, mutations: mg);

        final offspring = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        double probMale = 0.0;
        double probFemale = 0.0;

        for (final res in offspring) {
          if (res.isCarrier) continue;

          bool meetsRequirement = true;
          for (final t in targetIdsAtLocus) {
            if (!res.visualMutations.contains(t)) {
              meetsRequirement = false;
              break;
            }
          }

          if (meetsRequirement) {
            if (res.sex == OffspringSex.male) {
              probMale += res.probability * 2;
            } else if (res.sex == OffspringSex.female) {
              probFemale += res.probability * 2;
            } else {
              probMale += res.probability;
              probFemale += res.probability;
            }
          }
        }

        if (probMale > 0 || probFemale > 0) {
          validPairs.add(
            LocusPairResult(
              fatherGenotype: fg,
              motherGenotype: mg,
              probabilityMale: probMale.clamp(0.0, 1.0),
              probabilityFemale: probFemale.clamp(0.0, 1.0),
            ),
          );
        }
      }
    }

    validPairs.sort((a, b) {
      final aScore = a.probabilityMale > a.probabilityFemale
          ? a.probabilityMale
          : a.probabilityFemale;
      final bScore = b.probabilityMale > b.probabilityFemale
          ? b.probabilityMale
          : b.probabilityFemale;
      return bScore.compareTo(aScore);
    });

    if (validPairs.length <= _maxOptionsPerLocus) return validPairs;
    return validPairs.take(_maxOptionsPerLocus).toList();
  }
}
