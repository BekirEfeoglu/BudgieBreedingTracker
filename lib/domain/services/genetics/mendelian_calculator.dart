import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

part 'offspring_result.dart';
part 'allele_resolver.dart';
part 'allele_resolver_compounds.dart';
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
  @Deprecated(
    'Use calculateFromGenotypes instead for explicit allele state support',
  )
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
  /// Sex-linked linkage on Z chromosome (gene order: O — C — I — Slate):
  /// Ino-Slate (~2 cM), Cin-Ino (~3 cM), Cin-Slate (~5 cM),
  /// Op-Ino (~30 cM), Op-Cin (~34 cM), Op-Slate (~40 cM).
  /// When the father carries two linked mutations as heterozygous, they
  /// are calculated as a linked pair (tightest linkage prioritised).
  /// Both linkage phases are supported: coupling (carrier) and
  /// repulsion (split).
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
    //    Gene order on Z: Opaline — Cinnamon — Ino — Slate.
    //    Priority (tightest linkage first):
    //    Ino-Slate (2 cM) → Cin-Ino (3 cM) → Cin-Slate (5 cM) →
    //    Op-Ino (30 cM) → Op-Cin (34 cM) → Op-Slate (40 cM).
    //    Each mutation consumed once paired; remainder stay independent.
    final hasCinnamon = allIds.contains('cinnamon');
    final hasInoAllele = allIds.contains('ino');
    final hasOpaline = allIds.contains('opaline');
    final hasSlate = allIds.contains('slate');

    final consumedSexLinked = <String>{};

    void tryLinkPair(String id1, String id2, double rate) {
      if (consumedSexLinked.contains(id1) || consumedSexLinked.contains(id2)) {
        return;
      }
      if (!fatherIsHeterozygousAt(id1) || !fatherIsHeterozygousAt(id2)) {
        return;
      }
      final linkedResults = _calculateGenericLinkedPair(
        mutId1: id1,
        mutId2: id2,
        recombinationRate: rate,
        father: father,
        mother: mother,
      );
      if (linkedResults.isEmpty) return;

      perLocusResults['linked:${id1}_$id2'] = linkedResults;
      consumedSexLinked.addAll([id1, id2]);
      independentIds.remove(id1);
      independentIds.remove(id2);
      // Remove allelic series groups for consumed mutations (e.g. ino_locus).
      final r1 = MutationDatabase.getById(id1);
      final r2 = MutationDatabase.getById(id2);
      if (r1?.locusId != null) allelicGroups.remove(r1!.locusId);
      if (r2?.locusId != null) allelicGroups.remove(r2!.locusId);
    }

    // Ordered by recombination rate (tightest first).
    if (hasInoAllele && hasSlate) {
      tryLinkPair('ino', 'slate', GeneticsConstants.inoSlateRecombination);
    }
    if (hasCinnamon && hasInoAllele) {
      tryLinkPair(
        'cinnamon',
        'ino',
        GeneticsConstants.cinnamonInoRecombination,
      );
    }
    if (hasCinnamon && hasSlate) {
      tryLinkPair(
        'cinnamon',
        'slate',
        GeneticsConstants.cinnamonSlateRecombination,
      );
    }
    if (hasOpaline && hasInoAllele) {
      tryLinkPair('opaline', 'ino', GeneticsConstants.opalineInoRecombination);
    }
    if (hasOpaline && hasCinnamon) {
      tryLinkPair(
        'opaline',
        'cinnamon',
        GeneticsConstants.opalineCinnamonRecombination,
      );
    }
    if (hasOpaline && hasSlate) {
      tryLinkPair(
        'opaline',
        'slate',
        GeneticsConstants.opalineSlateRecombination,
      );
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
