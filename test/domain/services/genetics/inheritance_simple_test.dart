import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Simple inheritance flow (set-based API)', () {
    test('ignores unknown mutation ids and returns empty output', () {
      final results = calculator.calculateOffspring(
        fatherMutations: {'unknown_mutation'},
        motherMutations: {'another_unknown'},
      );

      expect(results, isEmpty);
    });

    test(
      'incomplete dominant single-parent case yields 50 single, 50 normal',
      () {
        final results = calculator.calculateOffspring(
          fatherMutations: {'dark_factor'},
          motherMutations: {},
        );

        final single = results.firstWhere(
          (r) => r.phenotype == 'Dark Factor (single)',
        );
        final normal = results.firstWhere((r) => r.phenotype == 'Normal');

        expect(single.probability, closeTo(0.5, 0.0001));
        expect(normal.probability, closeTo(0.5, 0.0001));
      },
    );

    test(
      'sex-linked father-only case yields carrier males and visual females',
      () {
        final results = calculator.calculateOffspring(
          fatherMutations: {'opaline'},
          motherMutations: {},
        );

        final maleCarrier = results.firstWhere(
          (r) => r.sex == OffspringSex.male && r.isCarrier,
        );
        final femaleVisual = results.firstWhere(
          (r) => r.sex == OffspringSex.female && r.phenotype == 'Opaline',
        );

        expect(maleCarrier.phenotype, 'Opaline (carrier)');
        expect(maleCarrier.probability, closeTo(0.5, 0.0001));
        expect(femaleVisual.probability, closeTo(0.5, 0.0001));
      },
    );
  });
}
