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
part 'punnett_square_dihybrid.dart';
part 'inheritance_allelic_series.dart';
part 'inheritance_linked_pair.dart';
part 'inheritance_genotype.dart';
part 'inheritance_genotype_sex_linked.dart';
part 'inheritance_simple.dart';
part 'inheritance_combiner.dart';
part 'inheritance_combiner_helpers.dart';
part 'mendelian_calculator_punnett.dart';

/// Mendelian genetics calculator for budgie color mutations.
///
/// Uses [MutationDatabase] records to determine inheritance patterns
/// and calculates offspring phenotype probabilities from parent mutations.
class MendelianCalculator {
  const MendelianCalculator();

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
  /// Ino-Slate (~2 cM est.), Cin-Ino (~3 cM), Cin-Slate (~5 cM),
  /// Op-Ino (~30 cM est.), Op-Cin (~32 cM), Op-Slate (~40.5 cM).
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
    //    Gene order on Z: Opaline — Cinnamon — Ino/Pallid/Pearly/TCB — Slate.
    //    All alleles at ino_locus (ino, pallid, pearly, texas_clearbody) share
    //    the same chromosomal position, so their linkage distance to cinnamon,
    //    slate, and opaline is approximately the same as the canonical ino
    //    distances.
    //    Priority (tightest linkage first):
    //    Ino-Slate (2 cM) → Cin-Ino (3 cM) → Cin-Slate (5 cM) →
    //    Op-Ino (30 cM) → Op-Cin (34 cM) → Op-Slate (40 cM).
    //    Each mutation consumed once paired; remainder stay independent.
    final hasCinnamon = allIds.contains(GeneticsConstants.mutCinnamon);
    final hasOpaline = allIds.contains(GeneticsConstants.mutOpaline);
    final hasSlate = allIds.contains(GeneticsConstants.mutSlate);

    // Resolve the single heterozygous ino_locus allele the father carries so
    // pallid/pearly/texas_clearbody also trigger the same linkage model as
    // literal ino. When the father carries two different ino_locus alleles
    // (compound heterozygote), linkage is skipped and the allelic series
    // calculator handles it instead.
    String? inoLocusHetAllele;
    for (final id in allIds) {
      final record = MutationDatabase.getById(id);
      if (record?.locusId != GeneticsConstants.locusIno) continue;
      if (!fatherIsHeterozygousAt(id)) continue;
      if (inoLocusHetAllele != null) {
        inoLocusHetAllele = null;
        break;
      }
      inoLocusHetAllele = id;
    }

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
      // Remove consumed mutations from their allelic series group. Only drop
      // the group when it becomes empty so other alleles at the same locus
      // (e.g. pallid when ino was paired) remain part of the allelic series
      // calculation.
      void removeFromAllelicGroup(String mutationId) {
        final record = MutationDatabase.getById(mutationId);
        final locusId = record?.locusId;
        if (locusId == null) return;
        final group = allelicGroups[locusId];
        if (group == null) return;
        group.remove(mutationId);
        if (group.isEmpty) allelicGroups.remove(locusId);
      }

      removeFromAllelicGroup(id1);
      removeFromAllelicGroup(id2);
    }

    // Ordered by recombination rate (tightest first).
    if (inoLocusHetAllele != null && hasSlate) {
      tryLinkPair(
        inoLocusHetAllele,
        GeneticsConstants.mutSlate,
        GeneticsConstants.inoSlateRecombination,
      );
    }
    if (hasCinnamon && inoLocusHetAllele != null) {
      tryLinkPair(
        GeneticsConstants.mutCinnamon,
        inoLocusHetAllele,
        GeneticsConstants.cinnamonInoRecombination,
      );
    }
    if (hasCinnamon && hasSlate) {
      tryLinkPair(
        GeneticsConstants.mutCinnamon,
        GeneticsConstants.mutSlate,
        GeneticsConstants.cinnamonSlateRecombination,
      );
    }
    if (hasOpaline && inoLocusHetAllele != null) {
      tryLinkPair(
        GeneticsConstants.mutOpaline,
        inoLocusHetAllele,
        GeneticsConstants.opalineInoRecombination,
      );
    }
    if (hasOpaline && hasCinnamon) {
      tryLinkPair(
        GeneticsConstants.mutOpaline,
        GeneticsConstants.mutCinnamon,
        GeneticsConstants.opalineCinnamonRecombination,
      );
    }
    if (hasOpaline && hasSlate) {
      tryLinkPair(
        GeneticsConstants.mutOpaline,
        GeneticsConstants.mutSlate,
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

}
