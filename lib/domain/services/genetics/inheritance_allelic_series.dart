part of 'mendelian_calculator.dart';

// ---------------------------------------------------------------------------
// Allelic series locus calculations
// ---------------------------------------------------------------------------

/// Calculates offspring for an allelic series locus using a 2x2 Punnett square.
///
/// Each allele is either 'wildtype' or a mutation ID.
/// The dominance hierarchy determines the phenotype for each combination.
List<_RawResult> _calculateAllelicSeriesLocus(
  String locusId,
  List<String> fatherAlleles,
  List<String> motherAlleles,
) {
  final outcomes = <String, double>{};

  // 2x2 Punnett cross
  for (final fa in fatherAlleles) {
    for (final ma in motherAlleles) {
      // Canonical key: sort alleles for consistent grouping
      final key = _sortAllelicPair(fa, ma);
      outcomes[key] = (outcomes[key] ?? 0) + 0.25;
    }
  }

  final results = <_RawResult>[];
  for (final entry in outcomes.entries) {
    final pair = entry.key.split('|');
    final allele1 = pair[0];
    final allele2 = pair[1];
    final prob = entry.value;

    final resolved = _resolveAllelicPhenotype(locusId, allele1, allele2);
    results.add(
      _RawResult(
        phenotype: resolved.phenotype,
        probability: prob,
        isCarrier: resolved.isCarrier,
        genotype: resolved.genotype,
        expressedMutationIds: resolved.expressedIds,
        carriedMutationIds: resolved.carriedIds,
      ),
    );
  }

  return results;
}

/// Calculates offspring for a sex-linked allelic series locus.
///
/// Father (ZZ): two Z alleles from [_getAllelesAtLocus].
/// Mother (ZW): one Z allele + 'W' from [_getSexLinkedMotherAllelesAtLocus].
///
/// Male offspring get Z from father + Z from mother.
/// Female offspring get Z from father + W from mother (hemizygous).
List<_RawResult> _calculateSexLinkedAllelicSeriesLocus(
  String locusId,
  List<String> fatherAlleles,
  List<String> motherAlleles,
) {
  final outcomes = <String, double>{};

  for (final fa in fatherAlleles) {
    for (final ma in motherAlleles) {
      final key = '$fa|$ma';
      outcomes[key] = (outcomes[key] ?? 0) + 0.25;
    }
  }

  final results = <_RawResult>[];
  for (final entry in outcomes.entries) {
    final pair = entry.key.split('|');
    final fatherAllele = pair[0];
    final motherAllele = pair[1];
    final prob = entry.value;

    if (motherAllele == 'W') {
      // Female offspring (Z from father / W)
      // Hemizygous: father's Z allele determines phenotype
      if (fatherAllele == 'wildtype') {
        results.add(
          _RawResult(
            phenotype: 'Normal',
            probability: prob,
            sex: OffspringSex.female,
            genotype: 'Z+/W',
          ),
        );
      } else {
        final record = MutationDatabase.getById(fatherAllele);
        final name = record?.name ?? fatherAllele;
        final sym = record?.alleleSymbol ?? fatherAllele;
        results.add(
          _RawResult(
            phenotype: name,
            probability: prob,
            sex: OffspringSex.female,
            genotype: 'Z$sym/W',
            expressedMutationIds: [fatherAllele],
          ),
        );
      }
    } else {
      // Male offspring (Z from father / Z from mother)
      // Use allelic phenotype resolution (dominance hierarchy)
      final resolved = _resolveAllelicPhenotype(
        locusId,
        fatherAllele,
        motherAllele,
      );

      // Build Z-notation genotype for sex-linked
      final sym1 = fatherAllele == 'wildtype'
          ? '+'
          : (MutationDatabase.getById(fatherAllele)?.alleleSymbol ??
                fatherAllele);
      final sym2 = motherAllele == 'wildtype'
          ? '+'
          : (MutationDatabase.getById(motherAllele)?.alleleSymbol ??
                motherAllele);

      results.add(
        _RawResult(
          phenotype: resolved.phenotype,
          probability: prob,
          sex: OffspringSex.male,
          isCarrier: resolved.isCarrier,
          genotype: 'Z$sym1/Z$sym2',
          expressedMutationIds: resolved.expressedIds,
          carriedMutationIds: resolved.carriedIds,
        ),
      );
    }
  }

  return results;
}
