part of 'mendelian_calculator.dart';

// ---------------------------------------------------------------------------
// Sex-linked linked pair calculations (linkage)
// ---------------------------------------------------------------------------

enum _LinkedPairPhase { coupling, repulsion }

bool _isLinkedPairHeterozygous(AlleleState? state) =>
    state == AlleleState.carrier || state == AlleleState.split;

List<bool> _expandFatherAllelesForLinkedPair(AlleleState? state) {
  return switch (state) {
    AlleleState.visual => [true, true],
    AlleleState.carrier || AlleleState.split => [true, false],
    null => [false, false],
  };
}

List<String> _mergeUniqueOrdered(List<String> base, List<String> add) {
  final merged = <String>[...base];
  for (final value in add) {
    if (!merged.contains(value)) merged.add(value);
  }
  return merged;
}

List<_LinkageGamete> _buildFatherLinkedGametes({
  required AlleleState? fatherState1,
  required AlleleState? fatherState2,
  required double recombinationRate,
  required _LinkedPairPhase phase,
}) {
  bool h1Mut1;
  bool h2Mut1;
  bool h1Mut2;
  bool h2Mut2;

  final isHet1 = _isLinkedPairHeterozygous(fatherState1);
  final isHet2 = _isLinkedPairHeterozygous(fatherState2);

  if (isHet1 && isHet2) {
    final isRepulsion = phase == _LinkedPairPhase.repulsion;
    // Coupling: [mut1+mut2] / [++]
    // Repulsion: [mut1+] / [+mut2]
    h1Mut1 = true;
    h2Mut1 = false;
    h1Mut2 = !isRepulsion;
    h2Mut2 = isRepulsion;
  } else {
    final alleles1 = _expandFatherAllelesForLinkedPair(fatherState1);
    final alleles2 = _expandFatherAllelesForLinkedPair(fatherState2);
    h1Mut1 = alleles1[0];
    h2Mut1 = alleles1[1];
    h1Mut2 = alleles2[0];
    h2Mut2 = alleles2[1];
  }

  final probabilityByGamete = <String, double>{};
  void addGamete(bool mut1, bool mut2, double probability) {
    final key = '${mut1 ? 1 : 0}|${mut2 ? 1 : 0}';
    probabilityByGamete[key] = (probabilityByGamete[key] ?? 0) + probability;
  }

  final parental = (1 - recombinationRate) / 2;
  final recombinant = recombinationRate / 2;

  // Two parental chromatids.
  addGamete(h1Mut1, h1Mut2, parental);
  addGamete(h2Mut1, h2Mut2, parental);
  // Two recombinant chromatids.
  addGamete(h1Mut1, h2Mut2, recombinant);
  addGamete(h2Mut1, h1Mut2, recombinant);

  return probabilityByGamete.entries.where((entry) => entry.value > 0).map((
    entry,
  ) {
    final parts = entry.key.split('|');
    return _LinkageGamete(
      mut1: parts[0] == '1',
      mut2: parts[1] == '1',
      prob: entry.value,
    );
  }).toList();
}

/// Calculates a sex-linked linked pair with the given recombination rate.
///
/// Supports both linkage phases for double-heterozygous males:
/// - coupling: [mut1+mut2]/[++]
/// - repulsion: [mut1+]/[+mut2]
List<_RawResult> _calculateGenericLinkedPair({
  required String mutId1,
  required String mutId2,
  required double recombinationRate,
  required ParentGenotype father,
  required ParentGenotype mother,
}) {
  final r = recombinationRate;
  final fatherState1 = father.getState(mutId1);
  final fatherState2 = father.getState(mutId2);
  final motherState1 = mother.getState(mutId1);
  final motherState2 = mother.getState(mutId2);

  final record1 = MutationDatabase.getById(mutId1);
  final record2 = MutationDatabase.getById(mutId2);
  final name1 = record1?.name ?? mutId1;
  final name2 = record2?.name ?? mutId2;

  final fatherPhase =
      fatherState1 == AlleleState.split && fatherState2 == AlleleState.split
      ? _LinkedPairPhase.repulsion
      : _LinkedPairPhase.coupling;
  final fatherGametes = _buildFatherLinkedGametes(
    fatherState1: fatherState1,
    fatherState2: fatherState2,
    recombinationRate: r,
    phase: fatherPhase,
  );

  // Mother Z alleles (hemizygous: any selected state means mutant allele on Z).
  final motherHasMut1 = motherState1 != null;
  final motherHasMut2 = motherState2 != null;

  final motherGametes = <_LinkageGamete>[
    _LinkageGamete(mut1: motherHasMut1, mut2: motherHasMut2, prob: 0.5),
    const _LinkageGamete(mut1: false, mut2: false, prob: 0.5, isW: true),
  ];

  final results = <String, _RawResult>{};

  for (final fg in fatherGametes) {
    for (final mg in motherGametes) {
      final prob = fg.prob * mg.prob;
      if (prob < 0.0001) continue;

      final sex = mg.isW ? OffspringSex.female : OffspringSex.male;

      final expressed = <String>[];
      final carriedIds = <String>[];
      final carriedNames = <String>[];
      bool isMut1Visual;
      bool isMut2Visual;

      if (sex == OffspringSex.female) {
        // Hemizygous: father's Z determines phenotype
        isMut1Visual = fg.mut1;
        isMut2Visual = fg.mut2;
      } else {
        // Male: both Z copies needed for visual (recessive)
        isMut1Visual = fg.mut1 && mg.mut1;
        isMut2Visual = fg.mut2 && mg.mut2;
        if (fg.mut1 != mg.mut1) {
          carriedIds.add(mutId1);
          carriedNames.add(name1);
        }
        if (fg.mut2 != mg.mut2) {
          carriedIds.add(mutId2);
          carriedNames.add(name2);
        }
      }

      if (isMut1Visual) expressed.add(mutId1);
      if (isMut2Visual) expressed.add(mutId2);

      // Build phenotype name
      String phenotype;
      if (isMut1Visual && isMut2Visual) {
        phenotype = _resolveLinkedCompoundName(mutId1, mutId2, name1, name2);
      } else if (isMut1Visual) {
        phenotype = name1;
      } else if (isMut2Visual) {
        phenotype = name2;
      } else {
        phenotype = 'Normal';
      }

      if (carriedNames.isNotEmpty) {
        phenotype = '$phenotype (${carriedNames.join(", ")} carrier)';
      }

      final key = '$phenotype|${sex.name}';
      if (results.containsKey(key)) {
        final existing = results[key]!;
        final mergedExpressed = _mergeUniqueOrdered(
          existing.expressedMutationIds,
          expressed,
        );
        final mergedCarried = _mergeUniqueOrdered(
          existing.carriedMutationIds,
          carriedIds,
        );
        results[key] = _RawResult(
          phenotype: phenotype,
          probability: existing.probability + prob,
          sex: sex,
          isCarrier: mergedCarried.isNotEmpty,
          expressedMutationIds: mergedExpressed,
          carriedMutationIds: mergedCarried,
        );
      } else {
        results[key] = _RawResult(
          phenotype: phenotype,
          probability: prob,
          sex: sex,
          isCarrier: carriedIds.isNotEmpty,
          expressedMutationIds: expressed,
          carriedMutationIds: carriedIds,
        );
      }
    }
  }

  return results.values.toList();
}
