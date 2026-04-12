part of 'mendelian_calculator.dart';

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
      motherChrom = ['Z$sym', _kWChromosome]; // Hemizygous visual
    case AlleleState.carrier:
      // Females cannot be carriers for sex-linked, treat as visual
      motherChrom = ['Z$sym', _kWChromosome];
    case AlleleState.split:
      motherChrom = ['Z$sym', _kWChromosome];
    case null:
      motherChrom = ['Z+', _kWChromosome]; // Wild type
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

    if (second == _kWChromosome) {
      // Female offspring (Z/W)
      if (first.contains(sym)) {
        results.add(
          _RawResult(
            phenotype: name,
            probability: prob,
            sex: OffspringSex.female,
            genotype: '${first}W',
            expressedMutationIds: [record.id],
          ),
        );
      } else {
        results.add(
          _RawResult(
            phenotype: 'Normal',
            probability: prob,
            sex: OffspringSex.female,
            genotype: 'Z+W',
          ),
        );
      }
    } else {
      // Male offspring (Z/Z)
      final hasFirst = first.contains(sym);
      final hasSecond = second.contains(sym);

      if (hasFirst && hasSecond) {
        // Homozygous visual male
        results.add(
          _RawResult(
            phenotype: name,
            probability: prob,
            sex: OffspringSex.male,
            genotype: 'Z${sym}Z$sym',
            expressedMutationIds: [record.id],
          ),
        );
      } else if (hasFirst || hasSecond) {
        // Heterozygous carrier male
        results.add(
          _RawResult(
            phenotype: '$name (carrier)',
            probability: prob,
            sex: OffspringSex.male,
            isCarrier: true,
            genotype: 'Z${sym}Z+',
            carriedMutationIds: [record.id],
          ),
        );
      } else {
        // Normal male
        results.add(
          _RawResult(
            phenotype: 'Normal',
            probability: prob,
            sex: OffspringSex.male,
            genotype: 'Z+Z+',
          ),
        );
      }
    }
  }

  return results;
}
