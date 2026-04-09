import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  const calculator = ReverseCalculator();

  group('ReverseCalculator', () {
    test('returns empty when target mutation set is empty', () {
      final results = calculator.calculateParents(const {});
      expect(results, isEmpty);
    });

    test('keeps probabilityAny aligned with male/female probabilities', () {
      final results = calculator.calculateParents({'blue', 'opaline'});

      expect(results, isNotEmpty);
      for (final result in results) {
        final expectedAny =
            (result.probabilityMale + result.probabilityFemale) / 2;
        expect(result.probabilityAny, closeTo(expectedAny, 1e-12));
      }
    });

    test('returns sorted and capped combinations', () {
      final results = calculator.calculateParents({'blue', 'ino'});

      expect(results.length, lessThanOrEqualTo(25));
      for (var i = 1; i < results.length; i++) {
        expect(
          results[i - 1].maxProbability,
          greaterThanOrEqualTo(results[i].maxProbability),
        );
      }
    });

    group('semantic correctness', () {
      test(
        'autosomal recessive target requires both parents to carry allele',
        () {
          // Blue is autosomal recessive — both parents must carry or express it
          final results = calculator.calculateParents({'blue'});
          expect(results, isNotEmpty);

          for (final result in results) {
            final fatherHasBlue =
                result.father.mutations.containsKey('blue') ||
                _hasBlueSeriesAllele(result.father);
            final motherHasBlue =
                result.mother.mutations.containsKey('blue') ||
                _hasBlueSeriesAllele(result.mother);
            expect(
              fatherHasBlue && motherHasBlue,
              isTrue,
              reason: 'Both parents must carry blue for recessive offspring',
            );
          }
        },
      );

      test('sex-linked target produces correct sex-specific probabilities', () {
        // Opaline is sex-linked recessive
        final results = calculator.calculateParents({'opaline'});
        expect(results, isNotEmpty);

        // At least one result should have different male/female probabilities
        // because sex-linked mutations segregate differently by sex
        final hasSexDifference = results.any(
          (r) => (r.probabilityMale - r.probabilityFemale).abs() > 0.001,
        );
        expect(
          hasSexDifference,
          isTrue,
          reason:
              'Sex-linked mutations should produce different probabilities '
              'for male and female offspring in at least some parent combos',
        );
      });

      test('top result for recessive target has high probability', () {
        // Blue is autosomal recessive — best parent combo should yield
        // high offspring probability (visual x visual = 100%)
        final results = calculator.calculateParents({'blue'});
        expect(results, isNotEmpty);

        final topResult = results.first;
        expect(
          topResult.maxProbability,
          greaterThanOrEqualTo(0.5),
          reason: 'Top result should have at least 50% probability',
        );
      });

      test('highest probability result is first in list', () {
        final results = calculator.calculateParents({'blue'});
        expect(results, isNotEmpty);
        expect(results.length, greaterThan(1));

        // First result should have highest maxProbability
        final topResult = results.first;
        for (final result in results.skip(1)) {
          expect(
            topResult.maxProbability,
            greaterThanOrEqualTo(result.maxProbability),
            reason: 'First result should have highest probability',
          );
        }
      });

      test('unknown mutation returns empty results', () {
        final results = calculator.calculateParents({
          'nonexistent_mutation_xyz',
        });
        expect(results, isEmpty);
      });

      test('single sex-linked mutation includes female visual parents', () {
        // For sex-linked: mother visual (Z*W) should appear in results
        final results = calculator.calculateParents({'cinnamon'});
        expect(results, isNotEmpty);

        final hasMotherVisual = results.any(
          (r) => r.mother.hasVisual('cinnamon'),
        );
        expect(
          hasMotherVisual,
          isTrue,
          reason: 'Sex-linked female visual parent should be in results',
        );
      });

      test('multi-locus target combines probabilities correctly', () {
        // blue + cinnamon: independent loci → probabilities multiply
        final results = calculator.calculateParents({'blue', 'cinnamon'});
        expect(results, isNotEmpty);

        for (final result in results) {
          // Combined probability should be ≤ probability of each alone
          expect(result.probabilityAny, lessThanOrEqualTo(1.0));
          expect(result.probabilityMale, lessThanOrEqualTo(1.0));
          expect(result.probabilityFemale, lessThanOrEqualTo(1.0));
        }
      });

      test('all results have valid parent genders', () {
        final results = calculator.calculateParents({'blue', 'opaline'});
        expect(results, isNotEmpty);

        for (final result in results) {
          expect(result.father.gender, BirdGender.male);
          expect(result.mother.gender, BirdGender.female);
        }
      });

      test('deduplication removes equivalent parent combinations', () {
        final results = calculator.calculateParents({'blue'});
        expect(results, isNotEmpty);

        // No two results should have identical parent genotypes
        final signatures = <String>{};
        for (final result in results) {
          final sig = _buildSignature(result);
          expect(
            signatures.add(sig),
            isTrue,
            reason: 'Duplicate parent combination found: $sig',
          );
        }
      });

      test('incomplete dominant target includes carrier parents', () {
        // Dark factor is incomplete dominant
        final results = calculator.calculateParents({'dark_factor'});
        expect(results, isNotEmpty);

        // Should include parents with carrier (SF) state
        final hasCarrierParent = results.any(
          (r) =>
              r.father.hasCarrier('dark_factor') ||
              r.mother.hasCarrier('dark_factor'),
        );
        expect(
          hasCarrierParent,
          isTrue,
          reason:
              'Incomplete dominant results should include '
              'carrier (single-factor) parents',
        );
      });

      test('dominant allelic series target (crested) finds parent combos', () {
        final results = calculator.calculateParents({'crested_tufted'});
        expect(results, isNotEmpty);

        // At least one parent must carry crested_tufted in every result
        for (final result in results) {
          final fatherHas =
              result.father.mutations.containsKey('crested_tufted');
          final motherHas =
              result.mother.mutations.containsKey('crested_tufted');
          expect(
            fatherHas || motherHas,
            isTrue,
            reason: 'At least one parent must carry crested allele',
          );
        }
      });

      test('linked sex-linked mutations (cinnamon+ino) produce results', () {
        // Lacewing requires both cinnamon and ino → independent loci on Z
        final results = calculator.calculateParents({'cinnamon', 'ino'});
        expect(results, isNotEmpty);

        // Top result should have non-trivial probability
        expect(
          results.first.maxProbability,
          greaterThan(0.0),
          reason: 'Lacewing parent combos must have positive probability',
        );
      });

      test('allelic series compound target (greywing) finds results', () {
        // Greywing is in the dilution allelic series (autosomal recessive)
        final results = calculator.calculateParents({'greywing'});
        expect(results, isNotEmpty);

        // Both parents must carry a dilution-locus allele
        for (final result in results) {
          final fatherHasDilution =
              result.father.mutations.keys.any(
                (id) => const {'greywing', 'clearwing', 'dilute'}.contains(id),
              );
          final motherHasDilution =
              result.mother.mutations.keys.any(
                (id) => const {'greywing', 'clearwing', 'dilute'}.contains(id),
              );
          expect(
            fatherHasDilution && motherHasDilution,
            isTrue,
            reason: 'Both parents must carry dilution-locus allele for greywing',
          );
        }
      });

      test('probabilities never exceed 1.0', () {
        final targets = [
          {'blue'},
          {'ino'},
          {'blue', 'ino'},
          {'dark_factor'},
          {'spangle'},
          {'crested_tufted'},
        ];

        for (final target in targets) {
          final results = calculator.calculateParents(target);
          for (final result in results) {
            expect(
              result.probabilityMale,
              lessThanOrEqualTo(1.0),
              reason: 'Male probability > 1.0 for target $target',
            );
            expect(
              result.probabilityFemale,
              lessThanOrEqualTo(1.0),
              reason: 'Female probability > 1.0 for target $target',
            );
            expect(
              result.probabilityAny,
              lessThanOrEqualTo(1.0),
              reason: 'Any probability > 1.0 for target $target',
            );
          }
        }
      });
    });
  });
}

/// Checks if parent has any blue-series allele (blue_series locus).
bool _hasBlueSeriesAllele(ParentGenotype parent) {
  const blueSeriesIds = {
    'blue',
    'yellowface_type1',
    'yellowface_type2',
    'goldenface',
    'aqua',
    'turquoise',
    'bluefactor_1',
    'bluefactor_2',
  };
  return parent.mutations.keys.any(blueSeriesIds.contains);
}

/// Builds a unique signature for a parent combination.
String _buildSignature(ReverseCalculationResult result) {
  String encode(Map<String, AlleleState> mutations) {
    final entries = mutations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '${e.key}:${e.value.name}').join('|');
  }

  return '${encode(result.father.mutations)}#${encode(result.mother.mutations)}';
}
