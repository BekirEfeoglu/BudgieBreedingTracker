import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

/// Represents a potential parent combination to produce a target offspring.
class ReverseCalculationResult {
  final ParentGenotype father;
  final ParentGenotype mother;
  final double probabilityMale;
  final double probabilityFemale;

  const ReverseCalculationResult({
    required this.father,
    required this.mother,
    required this.probabilityMale,
    required this.probabilityFemale,
  });

  /// Probability regardless of sex, assuming ~50/50 male/female split.
  double get probabilityAny => (probabilityMale + probabilityFemale) / 2;

  /// The highest available chance across overall, male-only, and female-only.
  double get maxProbability {
    final any = probabilityAny;
    final bySex = probabilityMale > probabilityFemale
        ? probabilityMale
        : probabilityFemale;
    return any > bySex ? any : bySex;
  }
}

class _LocusPairResult {
  final Map<String, AlleleState> fatherGenotype;
  final Map<String, AlleleState> motherGenotype;
  final double probabilityMale;
  final double probabilityFemale;

  const _LocusPairResult({
    required this.fatherGenotype,
    required this.motherGenotype,
    required this.probabilityMale,
    required this.probabilityFemale,
  });
}

class ReverseCalculator {
  static const int _maxOptionsPerLocus = 180;
  static const int _maxIntermediateCombinations = 3000;
  static const int _maxFinalCombinations = 500;

  const ReverseCalculator();

  /// Calculates potential parent genotypes that yield the given target mutations.
  ///
  /// The [targetMutationIds] must be the exact visual mutations desired in the offspring.
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
    final List<List<_LocusPairResult>> locusOptions = [];

    // For each affected locus, compute exactly what parent pairs yield the target.
    for (final entry in targetLoci.entries) {
      final locusId = entry.key;
      final targetIdsAtLocus = entry.value;

      final optionsAtLocus = _findValidPairsForLocus(
        locusId, // We use this locus string locally to query Database
        targetIdsAtLocus,
        calculator,
      );

      if (optionsAtLocus.isEmpty) {
        return []; // Impossible combination at this locus
      }
      locusOptions.add(optionsAtLocus);
    }

    // Combine identical parent combinations across loci
    final combinations = _combineLocusOptions(locusOptions);

    // Sort descending by highest probability of achieving the outcome
    combinations.sort((a, b) => b.maxProbability.compareTo(a.maxProbability));

    return combinations.take(25).toList();
  }

  List<_LocusPairResult> _findValidPairsForLocus(
    String locusId,
    List<String> targetIdsAtLocus,
    MendelianCalculator calculator,
  ) {
    final fatherGenotypes = _generateAllGenotypesAtLocus(
      locusId,
      BirdGender.male,
    );
    final motherGenotypes = _generateAllGenotypesAtLocus(
      locusId,
      BirdGender.female,
    );

    final List<_LocusPairResult> validPairs = [];

    for (final fg in fatherGenotypes) {
      for (final mg in motherGenotypes) {
        // Early pruning: for recessive targets, at least one parent must
        // carry or express the alleles. Skip obviously impossible pairs.
        if (!_canPossiblyProduceTargets(fg, mg, targetIdsAtLocus)) continue;

        final father = ParentGenotype(gender: BirdGender.male, mutations: fg);
        final mother = ParentGenotype(gender: BirdGender.female, mutations: mg);

        // Calculate using forward mendelian calculator methods
        final offspring = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        // Calculate the probability of encountering the targetIds in visual format.
        // It must contain ALL target ids defined for this locus
        double probMale = 0.0;
        double probFemale = 0.0;

        for (final res in offspring) {
          // Exclude carriers when asserting if it's visually present
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
              probMale +=
                  res.probability *
                  2; // scale back to gender-specific pool of 1.0
            } else if (res.sex == OffspringSex.female) {
              probFemale += res.probability * 2;
            } else {
              // Unknown/Any gender pool
              probMale += res.probability;
              probFemale += res.probability;
            }
          }
        }

        if (probMale > 0 || probFemale > 0) {
          validPairs.add(
            _LocusPairResult(
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

  /// Quick check: can this parent pair possibly produce offspring
  /// with the target mutation IDs? For each target, at least one parent
  /// must carry or express the allele.
  bool _canPossiblyProduceTargets(
    Map<String, AlleleState> fatherGeno,
    Map<String, AlleleState> motherGeno,
    List<String> targetIds,
  ) {
    for (final targetId in targetIds) {
      final fatherHas = fatherGeno.containsKey(targetId);
      final motherHas = motherGeno.containsKey(targetId);
      // If neither parent carries any form of this allele,
      // offspring cannot possibly express it.
      if (!fatherHas && !motherHas) return false;
    }
    return true;
  }

  List<Map<String, AlleleState>> _generateAllGenotypesAtLocus(
    String locusId,
    BirdGender gender,
  ) {
    var records = MutationDatabase.getByLocusId(locusId);
    if (records.isEmpty) {
      // In case the locusId was an independent mutation ID that didn't have locusId set
      final singleRecord = MutationDatabase.getById(locusId);
      if (singleRecord == null) return [{}];
      records = [singleRecord];
    }

    final isSexLinked = records.first.isSexLinked;
    final mutIds = records.map((r) => r.id).toList();

    final List<Map<String, AlleleState>> genotypes = [{}]; // Normal

    if (isSexLinked && gender == BirdGender.female) {
      // Female sex-linked can only be Visual (homozygous essentially)
      for (final mutId in mutIds) {
        genotypes.add({mutId: AlleleState.visual});
      }
    } else {
      // Single mutations
      for (final mutId in mutIds) {
        genotypes.add({mutId: AlleleState.visual});

        final rec = MutationDatabase.getById(mutId);
        // For recessive vs incomplete dominant
        if (rec != null) {
          genotypes.add({mutId: AlleleState.carrier});
        }
      }

      // Combinations of two mutations (split or compound heterozygote)
      for (int i = 0; i < mutIds.length; i++) {
        for (int j = i + 1; j < mutIds.length; j++) {
          if (isSexLinked) {
            genotypes.add({
              mutIds[i]: AlleleState.split,
              mutIds[j]: AlleleState.split,
            });
          } else {
            // compound heterozygote
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

  List<ReverseCalculationResult> _combineLocusOptions(
    List<List<_LocusPairResult>> locusOptions,
  ) {
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
    current = _dedupeAndTrim(current, limit: _maxIntermediateCombinations);

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
      current = _dedupeAndTrim(
        nextCombinations,
        limit: _maxIntermediateCombinations,
      );
    }

    return _dedupeAndTrim(current, limit: _maxFinalCombinations);
  }

  List<ReverseCalculationResult> _dedupeAndTrim(
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

  String _buildSignature(ReverseCalculationResult result) {
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
