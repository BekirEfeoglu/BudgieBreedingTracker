part of 'mendelian_calculator.dart';

PunnettSquareData _buildAllelicSeriesPunnett(
  String locusId,
  ParentGenotype father,
  ParentGenotype mother,
) {
  final mutIds = MutationDatabase.getByLocusId(
    locusId,
  ).map((r) => r.id).toSet();

  // Detect if this locus is sex-linked
  final sampleRecord = MutationDatabase.getByLocusId(locusId).firstOrNull;
  final isSexLinked = sampleRecord?.isSexLinked ?? false;

  final fatherAlleles = _getAllelesAtLocus(locusId, mutIds, father);
  final List<String> motherAlleles;
  if (isSexLinked) {
    motherAlleles = _getSexLinkedMotherAllelesAtLocus(locusId, mutIds, mother);
  } else {
    motherAlleles = _getAllelesAtLocus(locusId, mutIds, mother);
  }

  // Build human-readable allele names with Z notation for sex-linked
  final fatherNames = fatherAlleles.map((a) {
    final display = _alleleDisplayName(a);
    return isSexLinked ? 'Z$display' : display;
  }).toList();
  final motherNames = motherAlleles.map((a) {
    if (a == 'W') return 'W';
    final display = _alleleDisplayName(a);
    return isSexLinked ? 'Z$display' : display;
  }).toList();

  // Build cells: allele1/allele2 format
  final cells = <List<String>>[];
  for (final fa in fatherNames) {
    final row = <String>[];
    for (final ma in motherNames) {
      row.add('$fa/$ma');
    }
    cells.add(row);
  }

  final locusName = _locusDisplayName(locusId);

  return PunnettSquareData(
    mutationName: locusName,
    fatherAlleles: fatherNames,
    motherAlleles: motherNames,
    cells: cells,
    isSexLinked: isSexLinked,
  );
}

PunnettSquareData _buildAutosomalPunnettFromGenotype(
  BudgieMutationRecord record,
  String sym,
  AlleleState? fatherState,
  AlleleState? motherState,
) {
  final List<String> fatherAlleles;
  final List<String> motherAlleles;

  switch (record.inheritanceType) {
    case InheritanceType.autosomalRecessive:
      fatherAlleles = switch (fatherState) {
        AlleleState.visual => [sym, sym],
        AlleleState.carrier => ['$sym+', sym],
        AlleleState.split => ['$sym+', sym],
        null => ['$sym+', '$sym+'],
      };
      motherAlleles = switch (motherState) {
        AlleleState.visual => [sym, sym],
        AlleleState.carrier => ['$sym+', sym],
        AlleleState.split => ['$sym+', sym],
        null => ['$sym+', '$sym+'],
      };
    case InheritanceType.autosomalDominant:
      fatherAlleles = switch (fatherState) {
        AlleleState.visual => [sym, sym], // Homozygous (DF)
        AlleleState.carrier => ['$sym+', sym], // Heterozygous (SF)
        AlleleState.split => ['$sym+', sym],
        null => ['$sym+', '$sym+'],
      };
      motherAlleles = switch (motherState) {
        AlleleState.visual => [sym, sym], // Homozygous (DF)
        AlleleState.carrier => ['$sym+', sym], // Heterozygous (SF)
        AlleleState.split => ['$sym+', sym],
        null => ['$sym+', '$sym+'],
      };
    case InheritanceType.autosomalIncompleteDominant:
      fatherAlleles = switch (fatherState) {
        AlleleState.visual => [sym, sym], // DF (homozygous)
        AlleleState.carrier => ['$sym+', sym], // SF (heterozygous)
        AlleleState.split => ['$sym+', sym],
        null => ['$sym+', '$sym+'],
      };
      motherAlleles = switch (motherState) {
        AlleleState.visual => [sym, sym], // DF (homozygous)
        AlleleState.carrier => ['$sym+', sym], // SF (heterozygous)
        AlleleState.split => ['$sym+', sym],
        null => ['$sym+', '$sym+'],
      };
    case InheritanceType.sexLinkedRecessive:
    case InheritanceType.sexLinkedCodominant:
      fatherAlleles = ['$sym+', '$sym+'];
      motherAlleles = ['$sym+', '$sym+'];
  }

  final cells = <List<String>>[];
  for (final fa in fatherAlleles) {
    final row = <String>[];
    for (final ma in motherAlleles) {
      row.add('$fa/$ma');
    }
    cells.add(row);
  }

  return PunnettSquareData(
    mutationName: record.name,
    fatherAlleles: fatherAlleles,
    motherAlleles: motherAlleles,
    cells: cells,
    isSexLinked: false,
  );
}

PunnettSquareData _buildSexLinkedPunnettFromGenotype(
  BudgieMutationRecord record,
  String sym,
  AlleleState? fatherState,
  AlleleState? motherState,
) {
  final List<String> fatherAlleles = switch (fatherState) {
    AlleleState.visual => ['Z$sym', 'Z$sym'],
    AlleleState.carrier => ['Z$sym', 'Z+'],
    AlleleState.split => ['Z$sym', 'Z+'],
    null => ['Z+', 'Z+'],
  };

  final List<String> motherAlleles = switch (motherState) {
    AlleleState.visual => ['Z$sym', 'W'],
    AlleleState.carrier => ['Z$sym', 'W'],
    AlleleState.split => ['Z$sym', 'W'],
    null => ['Z+', 'W'],
  };

  final cells = <List<String>>[];
  for (final fa in fatherAlleles) {
    final row = <String>[];
    for (final ma in motherAlleles) {
      row.add('$fa/$ma');
    }
    cells.add(row);
  }

  return PunnettSquareData(
    mutationName: record.name,
    fatherAlleles: fatherAlleles,
    motherAlleles: motherAlleles,
    cells: cells,
    isSexLinked: true,
  );
}

/// Builds Punnett square for a simple set-based mutation query.
PunnettSquareData? _buildPunnettSquareSimple({
  required Set<String> fatherMutations,
  required Set<String> motherMutations,
}) {
  final allIds = {...fatherMutations, ...motherMutations};
  if (allIds.isEmpty) return null;

  final mutationId = allIds.first;
  final record = MutationDatabase.getById(mutationId);
  if (record == null) return null;

  final inFather = fatherMutations.contains(mutationId);
  final inMother = motherMutations.contains(mutationId);

  final sym = record.alleleSymbol;

  if (record.isSexLinked) {
    return _buildSexLinkedPunnettSimple(record, inFather, inMother);
  }

  // Autosomal Punnett square
  final List<String> fatherAlleles;
  final List<String> motherAlleles;

  if (inFather && inMother) {
    // Both heterozygous (or both homozygous for recessive)
    if (record.inheritanceType == InheritanceType.autosomalRecessive) {
      fatherAlleles = [sym, sym];
      motherAlleles = [sym, sym];
    } else {
      fatherAlleles = ['$sym+', sym];
      motherAlleles = ['$sym+', sym];
    }
  } else {
    // One has it, other is normal
    final carrier = inFather ? 'father' : 'mother';
    if (record.inheritanceType == InheritanceType.autosomalRecessive) {
      // Carrier x Normal-carrier assumed
      if (carrier == 'father') {
        fatherAlleles = [sym, sym];
        motherAlleles = ['$sym+', sym];
      } else {
        fatherAlleles = ['$sym+', sym];
        motherAlleles = [sym, sym];
      }
    } else {
      if (carrier == 'father') {
        fatherAlleles = ['$sym+', sym];
        motherAlleles = ['$sym+', '$sym+'];
      } else {
        fatherAlleles = ['$sym+', '$sym+'];
        motherAlleles = ['$sym+', sym];
      }
    }
  }

  final cells = <List<String>>[];
  for (final fa in fatherAlleles) {
    final row = <String>[];
    for (final ma in motherAlleles) {
      row.add('$fa/$ma');
    }
    cells.add(row);
  }

  return PunnettSquareData(
    mutationName: record.name,
    fatherAlleles: fatherAlleles,
    motherAlleles: motherAlleles,
    cells: cells,
    isSexLinked: false,
  );
}

PunnettSquareData _buildSexLinkedPunnettSimple(
  BudgieMutationRecord record,
  bool inFather,
  bool inMother,
) {
  final sym = record.alleleSymbol;

  // Father (ZZ), Mother (ZW)
  final List<String> fatherAlleles;
  final List<String> motherAlleles;

  if (inFather && inMother) {
    fatherAlleles = ['Z$sym', 'Z$sym'];
    motherAlleles = ['Z$sym', 'W'];
  } else if (inFather) {
    fatherAlleles = ['Z$sym', 'Z$sym'];
    motherAlleles = ['Z+', 'W'];
  } else {
    fatherAlleles = ['Z+', 'Z+'];
    motherAlleles = ['Z$sym', 'W'];
  }

  final cells = <List<String>>[];
  for (final fa in fatherAlleles) {
    final row = <String>[];
    for (final ma in motherAlleles) {
      row.add('$fa/$ma');
    }
    cells.add(row);
  }

  return PunnettSquareData(
    mutationName: record.name,
    fatherAlleles: fatherAlleles,
    motherAlleles: motherAlleles,
    cells: cells,
    isSexLinked: true,
  );
}

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
      if (a == 'W') return 'W';
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
        AlleleState.visual => ['Z$sym', 'W'],
        AlleleState.carrier => ['Z$sym', 'W'],
        AlleleState.split => ['Z$sym', 'W'],
        null => ['Z+', 'W'],
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
/// Creates combined gametes from two loci and produces a 4×4 grid.
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

  // Build 4×4 cells
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
    mutationName: '$name1 × $name2',
    fatherAlleles: fatherGametes,
    motherAlleles: motherGametes,
    cells: cells,
    isSexLinked: isSL1 || isSL2,
  );
}
