import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';

/// Verify total probability sums to ~1.0.
void expectNormalizedProbabilities(List<OffspringResult> results) {
  final total = results.fold<double>(0, (s, r) => s + r.probability);
  expect(total, closeTo(1.0, 0.01), reason: 'Probabilities must sum to 1.0');
}

/// Find result by phenotype substring and optional sex.
OffspringResult? findResult(
  List<OffspringResult> results,
  String phenotypeSubstring, {
  OffspringSex? sex,
}) {
  return results.cast<OffspringResult?>().firstWhere(
    (r) =>
        r!.phenotype.contains(phenotypeSubstring) &&
        (sex == null || r.sex == sex),
    orElse: () => null,
  );
}

/// Sum probabilities for results matching a phenotype substring.
double sumProbability(
  List<OffspringResult> results,
  String phenotypeSubstring, {
  OffspringSex? sex,
}) {
  return results
      .where(
        (r) =>
            r.phenotype.contains(phenotypeSubstring) &&
            (sex == null || r.sex == sex),
      )
      .fold<double>(0, (s, r) => s + r.probability);
}
