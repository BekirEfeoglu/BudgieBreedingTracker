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

