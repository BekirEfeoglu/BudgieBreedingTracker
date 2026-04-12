part of 'mendelian_calculator.dart';

/// Punnett square builder methods for [MendelianCalculator].
extension MendelianCalculatorPunnett on MendelianCalculator {
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

  /// Builds a dihybrid (4x4) Punnett square for two independent loci.
  ///
  /// Each locus is resolved to its single-locus allele pair, then the gametes
  /// are combined (A1B1, A1B2, A2B1, A2B2) for both parents to produce
  /// a 4x4 grid showing all possible genotype combinations.
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
