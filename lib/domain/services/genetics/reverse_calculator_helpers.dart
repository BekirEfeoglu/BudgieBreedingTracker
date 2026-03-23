import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator_models.dart';

/// Helper utilities for [ReverseCalculator].
///
/// Contains genotype generation, combination merging, deduplication, and
/// pruning helpers extracted to keep the main calculator under 300 lines.
abstract class ReverseCalculatorHelpers {
  /// Quick check: can this parent pair possibly produce offspring
  /// with the target mutation IDs?
  static bool canPossiblyProduceTargets(
    Map<String, AlleleState> fatherGeno,
    Map<String, AlleleState> motherGeno,
    List<String> targetIds,
  ) {
    for (final targetId in targetIds) {
      final fatherHas = fatherGeno.containsKey(targetId);
      final motherHas = motherGeno.containsKey(targetId);
      if (!fatherHas && !motherHas) return false;
    }
    return true;
  }

  /// Generates all possible genotype combinations at a given locus.
  static List<Map<String, AlleleState>> generateAllGenotypesAtLocus(
    String locusId,
    BirdGender gender,
  ) {
    var records = MutationDatabase.getByLocusId(locusId);
    if (records.isEmpty) {
      final singleRecord = MutationDatabase.getById(locusId);
      if (singleRecord == null) return [{}];
      records = [singleRecord];
    }

    final isSexLinked = records.first.isSexLinked;
    final mutIds = records.map((r) => r.id).toList();

    final List<Map<String, AlleleState>> genotypes = [{}]; // Normal

    if (isSexLinked && gender == BirdGender.female) {
      for (final mutId in mutIds) {
        genotypes.add({mutId: AlleleState.visual});
      }
    } else {
      for (final mutId in mutIds) {
        genotypes.add({mutId: AlleleState.visual});

        final rec = MutationDatabase.getById(mutId);
        if (rec != null) {
          genotypes.add({mutId: AlleleState.carrier});
        }
      }

      for (int i = 0; i < mutIds.length; i++) {
        for (int j = i + 1; j < mutIds.length; j++) {
          if (isSexLinked) {
            genotypes.add({
              mutIds[i]: AlleleState.split,
              mutIds[j]: AlleleState.split,
            });
          } else {
            genotypes.add({
              mutIds[i]: AlleleState.carrier,
              mutIds[j]: AlleleState.carrier,
            });
          }
        }
      }
    }

    return genotypes;
  }

  /// Combines locus-level options into full parent pair combinations.
  static List<ReverseCalculationResult> combineLocusOptions(
    List<List<LocusPairResult>> locusOptions, {
    required int maxIntermediateCombinations,
    required int maxFinalCombinations,
  }) {
    if (locusOptions.isEmpty) return [];

    List<ReverseCalculationResult> current = locusOptions.first.map((lr) {
      return ReverseCalculationResult(
        father: ParentGenotype(
          gender: BirdGender.male,
          mutations: lr.fatherGenotype,
        ),
        mother: ParentGenotype(
          gender: BirdGender.female,
          mutations: lr.motherGenotype,
        ),
        probabilityMale: lr.probabilityMale,
        probabilityFemale: lr.probabilityFemale,
      );
    }).toList();
    current = dedupeAndTrim(current, limit: maxIntermediateCombinations);

    for (int i = 1; i < locusOptions.length; i++) {
      final nextOptions = locusOptions[i];
      final List<ReverseCalculationResult> nextCombinations = [];

      for (final existing in current) {
        for (final opt in nextOptions) {
          final mergedFather = {
            ...existing.father.mutations,
            ...opt.fatherGenotype,
          };
          final mergedMother = {
            ...existing.mother.mutations,
            ...opt.motherGenotype,
          };

          nextCombinations.add(
            ReverseCalculationResult(
              father: ParentGenotype(
                gender: BirdGender.male,
                mutations: mergedFather,
              ),
              mother: ParentGenotype(
                gender: BirdGender.female,
                mutations: mergedMother,
              ),
              probabilityMale: existing.probabilityMale * opt.probabilityMale,
              probabilityFemale:
                  existing.probabilityFemale * opt.probabilityFemale,
            ),
          );
        }
      }
      current = dedupeAndTrim(
        nextCombinations,
        limit: maxIntermediateCombinations,
      );
    }

    return dedupeAndTrim(current, limit: maxFinalCombinations);
  }

  /// Deduplicates results by parent-pair signature and trims to [limit].
  static List<ReverseCalculationResult> dedupeAndTrim(
    List<ReverseCalculationResult> input, {
    required int limit,
  }) {
    if (input.isEmpty) return input;

    final bySignature = <String, ReverseCalculationResult>{};

    for (final result in input) {
      final signature = _buildSignature(result);
      final existing = bySignature[signature];
      if (existing == null || result.maxProbability > existing.maxProbability) {
        bySignature[signature] = result;
      }
    }

    final deduped = bySignature.values.toList()
      ..sort((a, b) => b.maxProbability.compareTo(a.maxProbability));

    if (deduped.length <= limit) return deduped;
    return deduped.take(limit).toList();
  }

  static String _buildSignature(ReverseCalculationResult result) {
    String encodeMutations(Map<String, AlleleState> mutations) {
      final entries = mutations.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return entries.map((e) => '${e.key}:${e.value.name}').join('|');
    }

    final fatherSig = encodeMutations(result.father.mutations);
    final motherSig = encodeMutations(result.mother.mutations);
    return '$fatherSig#$motherSig';
  }
}
