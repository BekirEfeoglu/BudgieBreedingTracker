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
        record,
        fatherState,
        motherState,
      );
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
      results.add(
        _RawResult(
          phenotype: name,
          probability: prob,
          genotype: '$sym/$sym',
          expressedMutationIds: [record.id],
        ),
      );
    } else if (geno == 'Aa') {
      // Carrier (heterozygous — _sortAlleles always puts uppercase first)
      results.add(
        _RawResult(
          phenotype: '$name (carrier)',
          probability: prob,
          isCarrier: true,
          genotype: '$sym+/$sym',
          carriedMutationIds: [record.id],
        ),
      );
    } else {
      // Normal (AA)
      results.add(
        _RawResult(
          phenotype: 'Normal',
          probability: prob,
          genotype: '$sym+/$sym+',
        ),
      );
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
      results.add(
        _RawResult(
          phenotype: '$name (homozygous)',
          probability: prob,
          genotype: '$sym/$sym',
          expressedMutationIds: [record.id],
        ),
      );
    } else if (geno == 'Aa') {
      results.add(
        _RawResult(
          phenotype: name,
          probability: prob,
          genotype: '$sym+/$sym',
          expressedMutationIds: [record.id],
        ),
      );
    } else {
      results.add(
        _RawResult(
          phenotype: 'Normal',
          probability: prob,
          genotype: '$sym+/$sym+',
        ),
      );
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
      results.add(
        _RawResult(
          phenotype: '$name (double)',
          probability: prob,
          genotype: '$sym/$sym',
          expressedMutationIds: [record.id],
        ),
      );
    } else if (geno == 'Aa') {
      results.add(
        _RawResult(
          phenotype: '$name (single)',
          probability: prob,
          genotype: '$sym+/$sym',
          expressedMutationIds: [record.id],
        ),
      );
    } else {
      results.add(
        _RawResult(
          phenotype: 'Normal',
          probability: prob,
          genotype: '$sym+/$sym+',
        ),
      );
    }
  }

  return results;
}

