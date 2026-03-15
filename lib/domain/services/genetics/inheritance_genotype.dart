part of 'mendelian_calculator.dart';

// ---------------------------------------------------------------------------
// Genotype-based inheritance (explicit allele states)
// ---------------------------------------------------------------------------

/// Autosomal inheritance with explicit allele states.
List<_RawResult> _calculateAutosomalGenotype(
  BudgieMutationRecord record,
  AlleleState? fatherState,
  AlleleState? motherState,
) {
  switch (record.inheritanceType) {
    case InheritanceType.autosomalRecessive:
      return _autosomalRecessiveGenotype(record, fatherState, motherState);
    case InheritanceType.autosomalDominant:
      return _autosomalDominantGenotype(record, fatherState, motherState);
    case InheritanceType.autosomalIncompleteDominant:
      return _autosomalIncompleteDominantGenotype(
          record, fatherState, motherState);
    case InheritanceType.sexLinkedRecessive:
    case InheritanceType.sexLinkedCodominant:
      return const []; // Handled separately
  }
}

/// Autosomal recessive with genotype states.
/// visual=aa, carrier=Aa, null=AA
List<_RawResult> _autosomalRecessiveGenotype(
  BudgieMutationRecord record,
  AlleleState? fatherState,
  AlleleState? motherState,
) {
  final name = record.name;
  final sym = record.alleleSymbol;
  // Determine allele pairs: visual=aa, carrier=Aa, absent=AA
  final fatherAa = _getAllelePair(fatherState);
  final motherAa = _getAllelePair(motherState);

  // Cross: each parent contributes one allele
  final outcomes = <String, double>{};
  for (final fa in fatherAa) {
    for (final ma in motherAa) {
      final genotype = _sortAlleles(fa, ma);
      outcomes[genotype] = (outcomes[genotype] ?? 0) + 0.25;
    }
  }

  final results = <_RawResult>[];
  for (final entry in outcomes.entries) {
    final geno = entry.key;
    final prob = entry.value;

    if (geno == 'aa') {
      // Visual
      results.add(_RawResult(
        phenotype: name,
        probability: prob,
        genotype: '$sym/$sym',
        expressedMutationIds: [record.id],
      ));
    } else if (geno == 'Aa') {
      // Carrier (heterozygous — _sortAlleles always puts uppercase first)
      results.add(_RawResult(
        phenotype: '$name (carrier)',
        probability: prob,
        isCarrier: true,
        genotype: '$sym+/$sym',
        carriedMutationIds: [record.id],
      ));
    } else {
      // Normal (AA)
      results.add(_RawResult(
        phenotype: 'Normal',
        probability: prob,
        genotype: '$sym+/$sym+',
      ));
    }
  }

  return results;
}

/// Autosomal dominant with genotype states.
List<_RawResult> _autosomalDominantGenotype(
  BudgieMutationRecord record,
  AlleleState? fatherState,
  AlleleState? motherState,
) {
  final name = record.name;
  final sym = record.alleleSymbol;

  // For dominant: visual could be AA or Aa, carrier=Aa, absent=aa
  final fatherAa = _getDominantAllelePair(fatherState);
  final motherAa = _getDominantAllelePair(motherState);

  final outcomes = <String, double>{};
  for (final fa in fatherAa) {
    for (final ma in motherAa) {
      final genotype = _sortAlleles(fa, ma);
      outcomes[genotype] = (outcomes[genotype] ?? 0) + 0.25;
    }
  }

  final results = <_RawResult>[];
  for (final entry in outcomes.entries) {
    final geno = entry.key;
    final prob = entry.value;

    if (geno == 'AA') {
      results.add(_RawResult(
        phenotype: '$name (homozygous)',
        probability: prob,
        genotype: '$sym/$sym',
        expressedMutationIds: [record.id],
      ));
    } else if (geno == 'Aa') {
      results.add(_RawResult(
        phenotype: name,
        probability: prob,
        genotype: '$sym+/$sym',
        expressedMutationIds: [record.id],
      ));
    } else {
      results.add(_RawResult(
        phenotype: 'Normal',
        probability: prob,
        genotype: '$sym+/$sym+',
      ));
    }
  }

  return results;
}

/// Autosomal incomplete dominant with genotype states.
/// visual = homozygous (AA/DF), carrier = heterozygous (Aa/SF), null = wild type (aa).
List<_RawResult> _autosomalIncompleteDominantGenotype(
  BudgieMutationRecord record,
  AlleleState? fatherState,
  AlleleState? motherState,
) {
  final name = record.name;
  final sym = record.alleleSymbol;

  final fatherAa = _getIncompleteDominantAllelePair(fatherState);
  final motherAa = _getIncompleteDominantAllelePair(motherState);

  final outcomes = <String, double>{};
  for (final fa in fatherAa) {
    for (final ma in motherAa) {
      final genotype = _sortAlleles(fa, ma);
      outcomes[genotype] = (outcomes[genotype] ?? 0) + 0.25;
    }
  }

  final results = <_RawResult>[];
  for (final entry in outcomes.entries) {
    final geno = entry.key;
    final prob = entry.value;

    if (geno == 'AA') {
      results.add(_RawResult(
        phenotype: '$name (double)',
        probability: prob,
        genotype: '$sym/$sym',
        expressedMutationIds: [record.id],
      ));
    } else if (geno == 'Aa') {
      results.add(_RawResult(
        phenotype: '$name (single)',
        probability: prob,
        genotype: '$sym+/$sym',
        expressedMutationIds: [record.id],
      ));
    } else {
      results.add(_RawResult(
        phenotype: 'Normal',
        probability: prob,
        genotype: '$sym+/$sym+',
      ));
    }
  }

  return results;
}

/// Sex-linked inheritance with genotype states.
/// Father (ZZ): visual=Z*Z*, carrier=Z*Z+, absent=Z+Z+
/// Mother (ZW): visual=Z*W, absent=Z+W (no carrier for hemizygous)
List<_RawResult> _calculateSexLinkedGenotype(
  BudgieMutationRecord record,
  AlleleState? fatherState,
  AlleleState? motherState,
) {
  final name = record.name;
  final sym = record.alleleSymbol;

  // Father Z chromosomes
  final List<String> fatherZ;
  switch (fatherState) {
    case AlleleState.visual:
      fatherZ = ['Z$sym', 'Z$sym']; // Homozygous
    case AlleleState.carrier:
      fatherZ = ['Z$sym', 'Z+']; // Heterozygous (split)
    case AlleleState.split:
      fatherZ = ['Z$sym', 'Z+']; // Same as carrier for single mutation
    case null:
      fatherZ = ['Z+', 'Z+']; // Wild type
  }

  // Mother Z/W chromosomes
  final List<String> motherChrom;
  switch (motherState) {
    case AlleleState.visual:
      motherChrom = ['Z$sym', 'W']; // Hemizygous visual
    case AlleleState.carrier:
      // Females cannot be carriers for sex-linked, treat as visual
      motherChrom = ['Z$sym', 'W'];
    case AlleleState.split:
      motherChrom = ['Z$sym', 'W'];
    case null:
      motherChrom = ['Z+', 'W']; // Wild type
  }

  // Cross: fatherZ x motherChrom
  final results = <_RawResult>[];
  final outcomes = <String, double>{};

  for (final fz in fatherZ) {
    for (final mc in motherChrom) {
      final key = '$fz/$mc';
      outcomes[key] = (outcomes[key] ?? 0) + 0.25;
    }
  }

  for (final entry in outcomes.entries) {
    final geno = entry.key;
    final prob = entry.value;
    final parts = geno.split('/');
    final first = parts[0];
    final second = parts[1];

    if (second == 'W') {
      // Female offspring (Z/W)
      if (first.contains(sym)) {
        results.add(_RawResult(
          phenotype: name,
          probability: prob,
          sex: OffspringSex.female,
          genotype: '${first}W',
          expressedMutationIds: [record.id],
        ));
      } else {
        results.add(_RawResult(
          phenotype: 'Normal',
          probability: prob,
          sex: OffspringSex.female,
          genotype: 'Z+W',
        ));
      }
    } else {
      // Male offspring (Z/Z)
      final hasFirst = first.contains(sym);
      final hasSecond = second.contains(sym);

      if (hasFirst && hasSecond) {
        // Homozygous visual male
        results.add(_RawResult(
          phenotype: name,
          probability: prob,
          sex: OffspringSex.male,
          genotype: 'Z${sym}Z$sym',
          expressedMutationIds: [record.id],
        ));
      } else if (hasFirst || hasSecond) {
        // Heterozygous carrier male
        results.add(_RawResult(
          phenotype: '$name (carrier)',
          probability: prob,
          sex: OffspringSex.male,
          isCarrier: true,
          genotype: 'Z${sym}Z+',
          carriedMutationIds: [record.id],
        ));
      } else {
        // Normal male
        results.add(_RawResult(
          phenotype: 'Normal',
          probability: prob,
          sex: OffspringSex.male,
          genotype: 'Z+Z+',
        ));
      }
    }
  }

  return results;
}
