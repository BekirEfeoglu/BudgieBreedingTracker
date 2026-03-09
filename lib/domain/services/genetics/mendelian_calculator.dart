import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

part 'offspring_result.dart';
part 'allele_resolver.dart';
part 'punnett_square_builder.dart';
part 'inheritance_allelic_series.dart';
part 'inheritance_linked_pair.dart';
part 'inheritance_genotype.dart';
part 'inheritance_simple.dart';
part 'inheritance_combiner.dart';

/// Mendelian genetics calculator for budgie color mutations.
///
/// Uses [MutationDatabase] records to determine inheritance patterns
/// and calculates offspring phenotype probabilities from parent mutations.
class MendelianCalculator {
  const MendelianCalculator();

  /// Calculates offspring predictions from parent mutation IDs.
  ///
  /// [fatherMutations] and [motherMutations] are sets of mutation IDs
  /// from [MutationDatabase] (e.g., `{'blue', 'opaline'}`).
  /// Both parents are assumed homozygous visual for selected mutations.
  @Deprecated('Use calculateFromGenotypes instead for explicit allele state support')
  List<OffspringResult> calculateOffspring({
    required Set<String> fatherMutations,
    required Set<String> motherMutations,
  }) {
    if (fatherMutations.isEmpty && motherMutations.isEmpty) return [];

    final results = <_RawResult>[];

    // Separate autosomal and sex-linked mutations
    final allIds = {...fatherMutations, ...motherMutations};

    for (final mutationId in allIds) {
      final record = MutationDatabase.getById(mutationId);
      if (record == null) continue;

      final inFather = fatherMutations.contains(mutationId);
      final inMother = motherMutations.contains(mutationId);

      if (record.isSexLinked) {
        results.addAll(_calculateSexLinked(record, inFather, inMother));
      } else {
        results.addAll(_calculateAutosomal(record, inFather, inMother));
      }
    }

    // Combine and normalize results
    return _combineResults(results);
  }

  /// Advanced calculation using [ParentGenotype] with explicit allele states.
  ///
  /// This method supports carrier/visual distinction per mutation,
  /// enabling more accurate predictions than the simple set-based API.
  /// Uses multi-locus combination: calculates each locus independently,
  /// then multiplies probabilities across loci for compound phenotypes.
  ///
  /// Allelic series: mutations sharing the same [BudgieMutationRecord.locusId]
  /// are grouped and calculated together (e.g., greywing/clearwing/dilute).
  ///
  /// Sex-linked linkage: Cinnamon and Ino (~3 cM apart on Z) are calculated
  /// as linked loci when the father carries both. Opaline-Cinnamon (~34 cM)
  /// and Opaline-Ino (~30 cM) linkage is also modelled.
  /// For double-heterozygous males, both linkage phases are supported:
  /// coupling (carrier) and repulsion (split).
  List<OffspringResult> calculateFromGenotypes({
    required ParentGenotype father,
    required ParentGenotype mother,
  }) {
    if (father.isEmpty && mother.isEmpty) return [];

    // Collect all mutation IDs from both parents
    final allIds = {...father.allMutationIds, ...mother.allMutationIds};

    // Group mutations by locusId (allelic series) vs independent
    final allelicGroups = <String, Set<String>>{}; // locusId → mutation IDs
    final independentIds = <String>{};
    final processedLocusIds = <String>{};

    for (final mutationId in allIds) {
      final record = MutationDatabase.getById(mutationId);
      if (record == null) continue;

      if (record.locusId != null) {
        allelicGroups.putIfAbsent(record.locusId!, () => {}).add(mutationId);
      } else {
        independentIds.add(mutationId);
      }
    }

    // Calculate per-locus results
    final perLocusResults = <String, List<_RawResult>>{};

    bool fatherIsHeterozygousAt(String mutationId) {
      return switch (father.getState(mutationId)) {
        AlleleState.carrier || AlleleState.split => true,
        _ => false,
      };
    }

    // 1. Check for sex-linked linkage pairs on the Z chromosome.
    //    Priority: Cin-Ino (3 cM, tight) → Op-Cin (34 cM) → Op-Ino (30 cM).
    //    Only one pair per mutation is handled; remainder stay independent.
    final hasCinnamon = allIds.contains('cinnamon');
    final hasInoAllele = allIds.contains('ino');
    final hasOpaline = allIds.contains('opaline');

    // 1a. Cinnamon-Ino linkage (~3 cM — highest priority)
    final fatherHasBothCinInoAsHet =
        hasCinnamon &&
        hasInoAllele &&
        fatherIsHeterozygousAt('cinnamon') &&
        fatherIsHeterozygousAt('ino');

    if (fatherHasBothCinInoAsHet) {
      final linkedResults = _calculateGenericLinkedPair(
        mutId1: 'cinnamon',
        mutId2: 'ino',
        recombinationRate: GeneticsConstants.cinnamonInoRecombination,
        father: father,
        mother: mother,
      );
      if (linkedResults.isNotEmpty) {
        perLocusResults['linked:cinnamon_ino'] = linkedResults;
        independentIds.remove('cinnamon');
        allelicGroups.remove(GeneticsConstants.locusIno);
      }
    }

    // 1b. Opaline-Cinnamon linkage (~34 cM)
    //     Only if cinnamon wasn't consumed by Cin-Ino linkage above.
    final cinConsumed = perLocusResults.containsKey('linked:cinnamon_ino');
    final fatherHasBothOpCinAsHet =
        hasOpaline &&
        hasCinnamon &&
        !cinConsumed &&
        fatherIsHeterozygousAt('opaline') &&
        fatherIsHeterozygousAt('cinnamon');

    if (fatherHasBothOpCinAsHet) {
      final linkedResults = _calculateGenericLinkedPair(
        mutId1: 'opaline',
        mutId2: 'cinnamon',
        recombinationRate: GeneticsConstants.opalineCinnamonRecombination,
        father: father,
        mother: mother,
      );
      if (linkedResults.isNotEmpty) {
        perLocusResults['linked:opaline_cinnamon'] = linkedResults;
        independentIds.remove('opaline');
        independentIds.remove('cinnamon');
      }
    }

    // 1c. Opaline-Ino linkage (~30 cM)
    //     Only if neither opaline nor ino was consumed by steps above.
    final opConsumed = perLocusResults.containsKey('linked:opaline_cinnamon');
    final inoConsumed = cinConsumed;
    final fatherHasBothOpInoAsHet =
        hasOpaline &&
        hasInoAllele &&
        !opConsumed &&
        !inoConsumed &&
        fatherIsHeterozygousAt('opaline') &&
        fatherIsHeterozygousAt('ino');

    if (fatherHasBothOpInoAsHet) {
      final linkedResults = _calculateGenericLinkedPair(
        mutId1: 'opaline',
        mutId2: 'ino',
        recombinationRate: GeneticsConstants.opalineInoRecombination,
        father: father,
        mother: mother,
      );
      if (linkedResults.isNotEmpty) {
        perLocusResults['linked:opaline_ino'] = linkedResults;
        independentIds.remove('opaline');
        allelicGroups.remove(GeneticsConstants.locusIno);
      }
    }

    // 2. Allelic series loci
    for (final entry in allelicGroups.entries) {
      final locusId = entry.key;
      final mutIds = entry.value;
      processedLocusIds.add(locusId);

      // Detect if locus is sex-linked
      final sampleRecord = MutationDatabase.getById(mutIds.first);
      final isSexLinked = sampleRecord?.isSexLinked ?? false;

      if (isSexLinked) {
        final fatherAlleles = _getAllelesAtLocus(locusId, mutIds, father);
        final motherAlleles = _getSexLinkedMotherAllelesAtLocus(
          locusId,
          mutIds,
          mother,
        );
        final results = _calculateSexLinkedAllelicSeriesLocus(
          locusId,
          fatherAlleles,
          motherAlleles,
        );
        if (results.isNotEmpty) {
          perLocusResults['locus:$locusId'] = results;
        }
      } else {
        final fatherAlleles = _getAllelesAtLocus(locusId, mutIds, father);
        final motherAlleles = _getAllelesAtLocus(locusId, mutIds, mother);
        final results = _calculateAllelicSeriesLocus(
          locusId,
          fatherAlleles,
          motherAlleles,
        );
        if (results.isNotEmpty) {
          perLocusResults['locus:$locusId'] = results;
        }
      }
    }

    // 3. Independent mutations
    for (final mutationId in independentIds) {
      final record = MutationDatabase.getById(mutationId);
      if (record == null) continue;

      final fatherState = father.getState(mutationId);
      final motherState = mother.getState(mutationId);

      final List<_RawResult> locusResults;
      if (record.isSexLinked) {
        locusResults = _calculateSexLinkedGenotype(
          record,
          fatherState,
          motherState,
        );
      } else {
        locusResults = _calculateAutosomalGenotype(
          record,
          fatherState,
          motherState,
        );
      }

      if (locusResults.isNotEmpty) {
        perLocusResults[mutationId] = locusResults;
      }
    }

    if (perLocusResults.isEmpty) return [];

    // If only one locus, return simple results
    if (perLocusResults.length == 1) {
      return _combineResults(perLocusResults.values.first);
    }

    // Multi-locus combination: multiply probabilities across loci
    return _combineMultiLocus(perLocusResults);
  }

  /// Builds Punnett square from genotype data for a specific mutation.
  PunnettSquareData? buildPunnettSquareFromGenotypes({
    required ParentGenotype father,
    required ParentGenotype mother,
    String? mutationId,
  }) {
    final allIds = {...father.allMutationIds, ...mother.allMutationIds};
    if (allIds.isEmpty) return null;

    final targetId = mutationId ?? allIds.first;

    // Check if targetId is a locusId (allelic series Punnett)
    final allelicLocusIds = MutationDatabase.getAllelicLocusIds();
    if (allelicLocusIds.contains(targetId)) {
      return _buildAllelicSeriesPunnett(targetId, father, mother);
    }

    final record = MutationDatabase.getById(targetId);
    if (record == null) return null;

    final fatherState = father.getState(targetId);
    final motherState = mother.getState(targetId);
    final sym = record.alleleSymbol;

    if (record.isSexLinked) {
      return _buildSexLinkedPunnettFromGenotype(
        record,
        sym,
        fatherState,
        motherState,
      );
    }

    return _buildAutosomalPunnettFromGenotype(
      record,
      sym,
      fatherState,
      motherState,
    );
  }

  /// Returns Punnett square data for a single mutation locus.
  ///
  /// Returns a map with 'headers' (father/mother alleles) and 'cells'.
  @Deprecated('Use buildPunnettSquareFromGenotypes instead')
  PunnettSquareData? buildPunnettSquare({
    required Set<String> fatherMutations,
    required Set<String> motherMutations,
  }) {
    return _buildPunnettSquareSimple(
      fatherMutations: fatherMutations,
      motherMutations: motherMutations,
    );
  }

  /// Builds a dihybrid (4×4) Punnett square for two independent loci.
  ///
  /// Each locus is resolved to its single-locus allele pair, then the gametes
  /// are combined (A1B1, A1B2, A2B1, A2B2) for both parents to produce
  /// a 4×4 grid showing all possible genotype combinations.
  PunnettSquareData? buildDihybridPunnettSquare({
    required ParentGenotype father,
    required ParentGenotype mother,
    required String locusId1,
    required String locusId2,
  }) {
    return _buildDihybridPunnett(
      father: father,
      mother: mother,
      locusId1: locusId1,
      locusId2: locusId2,
    );
  }
}
