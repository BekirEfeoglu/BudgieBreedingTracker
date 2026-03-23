part of 'mendelian_calculator.dart';

// ---------------------------------------------------------------------------
// Dihybrid (two-locus) Punnett square
// ---------------------------------------------------------------------------

/// Resolves the two alleles for a parent at a given locus/mutation.
///
/// Returns display-ready allele strings (e.g., ['Sp+', 'Sp'] or ['Z_ino', 'Z+']).
List<String> _resolveLocusAlleles(String locusOrMutId, ParentGenotype parent) {
  final allelicLocusIds = MutationDatabase.getAllelicLocusIds();

  if (allelicLocusIds.contains(locusOrMutId)) {
    // Allelic series locus
    final mutIds = MutationDatabase.getByLocusId(
      locusOrMutId,
    ).map((r) => r.id).toSet();
    final sampleRecord = MutationDatabase.getByLocusId(
      locusOrMutId,
    ).firstOrNull;
    final isSexLinked = sampleRecord?.isSexLinked ?? false;

    List<String> raw;
    if (isSexLinked && parent.gender == BirdGender.female) {
      raw = _getSexLinkedMotherAllelesAtLocus(locusOrMutId, mutIds, parent);
    } else {
      raw = _getAllelesAtLocus(locusOrMutId, mutIds, parent);
    }

    return raw.map((a) {
      if (a == _kWChromosome) return _kWChromosome;
      final display = _alleleDisplayName(a);
      return isSexLinked ? 'Z$display' : display;
    }).toList();
  }

  // Independent mutation
  final record = MutationDatabase.getById(locusOrMutId);
  if (record == null) return ['+', '+'];
  final sym = record.alleleSymbol;
  final state = parent.getState(locusOrMutId);

  if (record.isSexLinked) {
    if (parent.gender == BirdGender.female) {
      return switch (state) {
        AlleleState.visual => ['Z$sym', _kWChromosome],
        AlleleState.carrier => ['Z$sym', _kWChromosome],
        AlleleState.split => ['Z$sym', _kWChromosome],
        null => ['Z+', _kWChromosome],
      };
    }
    return switch (state) {
      AlleleState.visual => ['Z$sym', 'Z$sym'],
      AlleleState.carrier => ['Z$sym', 'Z+'],
      AlleleState.split => ['Z$sym', 'Z+'],
      null => ['Z+', 'Z+'],
    };
  }

  // Autosomal
  switch (record.inheritanceType) {
    case InheritanceType.autosomalRecessive:
      return switch (state) {
        AlleleState.visual => [sym, sym],
        AlleleState.carrier => ['$sym+', sym],
        AlleleState.split => ['$sym+', sym],
        null => ['$sym+', '$sym+'],
      };
    case InheritanceType.autosomalDominant:
      return switch (state) {
        AlleleState.visual => [sym, sym],
        AlleleState.carrier => ['$sym+', sym],
        AlleleState.split => ['$sym+', sym],
        null => ['$sym+', '$sym+'],
      };
    case InheritanceType.autosomalIncompleteDominant:
      return switch (state) {
        AlleleState.visual => [sym, sym],
        AlleleState.carrier => ['$sym+', sym],
        AlleleState.split => ['$sym+', sym],
        null => ['$sym+', '$sym+'],
      };
    case InheritanceType.sexLinkedRecessive:
    case InheritanceType.sexLinkedCodominant:
      return ['$sym+', '$sym+'];
  }
}

/// Display name for a locus or mutation ID.
String _locusDisplayName(String id) {
  final allelicLocusIds = MutationDatabase.getAllelicLocusIds();
  if (allelicLocusIds.contains(id)) {
    return switch (id) {
      'dilution' => 'Dilution',
      'blue_series' => 'Blue Series',
      'ino_locus' => 'Ino Locus',
      'crested' => 'Crested',
      _ => id,
    };
  }
  final record = MutationDatabase.getById(id);
  return record?.name ?? id;
}

/// Builds a dihybrid Punnett square for two independent loci.
///
/// Creates combined gametes from two loci and produces a 4x4 grid.
PunnettSquareData? _buildDihybridPunnett({
  required ParentGenotype father,
  required ParentGenotype mother,
  required String locusId1,
  required String locusId2,
}) {
  final fatherA = _resolveLocusAlleles(locusId1, father);
  final fatherB = _resolveLocusAlleles(locusId2, father);
  final motherA = _resolveLocusAlleles(locusId1, mother);
  final motherB = _resolveLocusAlleles(locusId2, mother);

  // Build combined gametes: each gamete is one allele from each locus
  final fatherGametes = <String>[];
  for (final a in fatherA) {
    for (final b in fatherB) {
      fatherGametes.add('$a; $b');
    }
  }

  final motherGametes = <String>[];
  for (final a in motherA) {
    for (final b in motherB) {
      motherGametes.add('$a; $b');
    }
  }

  // Build 4x4 cells
  final cells = <List<String>>[];
  for (final fg in fatherGametes) {
    final row = <String>[];
    for (final mg in motherGametes) {
      // Parse gamete components and recombine
      final fParts = fg.split('; ');
      final mParts = mg.split('; ');
      final cell = '${fParts[0]}/${mParts[0]}, ${fParts[1]}/${mParts[1]}';
      row.add(cell);
    }
    cells.add(row);
  }

  final name1 = _locusDisplayName(locusId1);
  final name2 = _locusDisplayName(locusId2);

  // Either locus might be sex-linked
  final isSL1 =
      MutationDatabase.getByLocusId(locusId1).firstOrNull?.isSexLinked ??
      (MutationDatabase.getById(locusId1)?.isSexLinked ?? false);
  final isSL2 =
      MutationDatabase.getByLocusId(locusId2).firstOrNull?.isSexLinked ??
      (MutationDatabase.getById(locusId2)?.isSexLinked ?? false);

  return PunnettSquareData(
    mutationName: '$name1 \u00d7 $name2',
    fatherAlleles: fatherGametes,
    motherAlleles: motherGametes,
    cells: cells,
    isSexLinked: isSL1 || isSL2,
  );
}
