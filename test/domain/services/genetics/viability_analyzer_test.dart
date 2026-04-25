import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

OffspringResult _offspring({
  required String phenotype,
  required double probability,
  OffspringSex sex = OffspringSex.both,
  List<String> visualMutations = const [],
  Set<String> doubleFactorIds = const {},
}) {
  return OffspringResult(
    phenotype: phenotype,
    probability: probability,
    sex: sex,
    visualMutations: visualMutations,
    doubleFactorIds: doubleFactorIds,
  );
}

void main() {
  late ViabilityAnalyzer analyzer;

  setUp(() {
    analyzer = const ViabilityAnalyzer();
  });

  group('no warnings', () {
    test('returns empty result for normal parents and normal offspring', () {
      final result = analyzer.analyze(
        fatherMutations: {'blue'},
        motherMutations: {'blue'},
        offspringResults: [
          _offspring(
            phenotype: 'Blue',
            probability: 1.0,
            visualMutations: ['blue'],
          ),
        ],
      );

      expect(result.hasWarnings, isFalse);
      expect(result.warnings, isEmpty);
      expect(result.highestSeverity, isNull);
      expect(result.totalAffectedProbability, 0.0);
    });

    test('returns empty result for empty parent mutations', () {
      final result = analyzer.analyze(
        fatherMutations: const {},
        motherMutations: const {},
        offspringResults: [
          _offspring(phenotype: 'Normal', probability: 1.0),
        ],
      );

      expect(result.hasWarnings, isFalse);
    });
  });

  group('hasWarnings', () {
    test('is false when warnings list is empty', () {
      final result = analyzer.analyze(
        fatherMutations: const {},
        motherMutations: const {},
        offspringResults: [
          _offspring(phenotype: 'Normal', probability: 1.0),
        ],
      );

      expect(result.warnings, isEmpty);
      expect(result.hasWarnings, isFalse);
    });

    test('is true when warnings exist', () {
      final result = analyzer.analyze(
        fatherMutations: {'ino'},
        motherMutations: {'ino'},
        offspringResults: [
          _offspring(phenotype: 'Ino', probability: 1.0),
        ],
      );

      expect(result.warnings, isNotEmpty);
      expect(result.hasWarnings, isTrue);
    });
  });

  group('offspring-level lethal detection', () {
    test('detects DF Spangle when offspring has homozygous spangle', () {
      final result = analyzer.analyze(
        fatherMutations: {'spangle'},
        motherMutations: {'spangle'},
        offspringResults: [
          _offspring(
            phenotype: 'DF Spangle',
            probability: 0.25,
            visualMutations: ['spangle'],
            doubleFactorIds: {'spangle'},
          ),
          _offspring(
            phenotype: 'SF Spangle',
            probability: 0.50,
            visualMutations: ['spangle'],
          ),
          _offspring(phenotype: 'Normal', probability: 0.25),
        ],
      );

      final spangleWarnings =
          result.warnings.where((w) => w.combination.id == 'df_spangle');
      expect(spangleWarnings, hasLength(1));
      expect(
        spangleWarnings.first.offspring.phenotype,
        'DF Spangle',
      );
    });

    test('does not flag SF Spangle offspring as DF Spangle', () {
      final result = analyzer.analyze(
        fatherMutations: {'spangle'},
        motherMutations: {'spangle'},
        offspringResults: [
          _offspring(
            phenotype: 'SF Spangle',
            probability: 0.50,
            visualMutations: ['spangle'],
          ),
        ],
      );

      final spangleWarnings =
          result.warnings.where((w) => w.combination.id == 'df_spangle');
      expect(spangleWarnings, isEmpty);
    });
  });

  group('parent-level checks', () {
    test('ino x ino flags all offspring when both parents are visual ino', () {
      final result = analyzer.analyze(
        fatherMutations: {'ino'},
        motherMutations: {'ino'},
        offspringResults: [
          _offspring(phenotype: 'Lutino', probability: 0.5),
          _offspring(phenotype: 'Albino', probability: 0.5),
        ],
      );

      final inoWarnings =
          result.warnings.where((w) => w.combination.id == 'ino_x_ino');
      expect(inoWarnings, hasLength(2));
    });

    test('ino x ino does not trigger when only father has ino', () {
      final result = analyzer.analyze(
        fatherMutations: {'ino'},
        motherMutations: {'blue'},
        offspringResults: [
          _offspring(phenotype: 'Ino', probability: 0.5),
        ],
      );

      final inoWarnings =
          result.warnings.where((w) => w.combination.id == 'ino_x_ino');
      expect(inoWarnings, isEmpty);
    });

    test('crested x crested flags all offspring', () {
      final result = analyzer.analyze(
        fatherMutations: {'crested_tufted'},
        motherMutations: {'crested_full_circular'},
        offspringResults: [
          _offspring(phenotype: 'Crested', probability: 0.5),
          _offspring(phenotype: 'Normal', probability: 0.5),
        ],
      );

      final crestedWarnings =
          result.warnings.where((w) => w.combination.id == 'df_crested');
      expect(crestedWarnings, hasLength(2));
    });
  });

  group('severity calculation', () {
    test('highest severity is lethal when both lethal and semi exist', () {
      final result = analyzer.analyze(
        fatherMutations: {'crested_tufted', 'ino'},
        motherMutations: {'crested_half_circular', 'ino'},
        offspringResults: [
          _offspring(phenotype: 'Ino Crested', probability: 1.0),
        ],
      );

      // lethal (df_crested) beats subVital (ino_x_ino)
      expect(result.highestSeverity, LethalSeverity.lethal);
    });

    test('severity is lethal when only crested pairing is detected', () {
      final result = analyzer.analyze(
        fatherMutations: {'crested_tufted'},
        motherMutations: {'crested_half_circular'},
        offspringResults: [
          _offspring(phenotype: 'Crested', probability: 1.0),
        ],
      );

      expect(result.highestSeverity, LethalSeverity.lethal);
    });
  });

  group('affected probability', () {
    test('sums affected rates across warnings', () {
      // Spangle x Spangle: only DF offspring triggers df_spangle (rate=1.0)
      final result = analyzer.analyze(
        fatherMutations: {'spangle'},
        motherMutations: {'spangle'},
        offspringResults: [
          _offspring(
            phenotype: 'DF Spangle',
            probability: 0.25,
            visualMutations: ['spangle'],
            doubleFactorIds: {'spangle'},
          ),
          _offspring(
            phenotype: 'Normal',
            probability: 0.75,
          ),
        ],
      );

      // 0.25 * 1.0 = 0.25
      expect(result.totalAffectedProbability, closeTo(0.25, 0.0001));
    });

    test('clamps total affected probability to 1.0', () {
      // ino x ino (rate=1.0) + crested x crested (rate=0.25) on same offspring
      final result = analyzer.analyze(
        fatherMutations: {'ino', 'crested_tufted'},
        motherMutations: {'ino', 'crested_half_circular'},
        offspringResults: [
          _offspring(phenotype: 'Ino Crested', probability: 0.5),
          _offspring(phenotype: 'Ino Normal', probability: 0.5),
        ],
      );

      expect(result.totalAffectedProbability, 1.0);
    });
  });

  group('empty offspring list', () {
    test('only parent checks run with no offspring', () {
      final result = analyzer.analyze(
        fatherMutations: {'ino'},
        motherMutations: {'ino'},
        offspringResults: const [],
      );

      // ino_x_ino triggers but no offspring to attach warnings to
      expect(result.hasWarnings, isFalse);
      expect(result.totalAffectedProbability, 0.0);
    });

    test('no warnings for normal parents with empty offspring', () {
      final result = analyzer.analyze(
        fatherMutations: {'blue'},
        motherMutations: {'green'},
        offspringResults: const [],
      );

      expect(result.hasWarnings, isFalse);
    });
  });

  group('multiple offspring matching same combo', () {
    test('probability sums correctly for DF Spangle across results', () {
      final result = analyzer.analyze(
        fatherMutations: {'spangle'},
        motherMutations: {'spangle'},
        offspringResults: [
          _offspring(
            phenotype: 'DF Spangle Male',
            probability: 0.125,
            sex: OffspringSex.male,
            visualMutations: ['spangle'],
            doubleFactorIds: {'spangle'},
          ),
          _offspring(
            phenotype: 'DF Spangle Female',
            probability: 0.125,
            sex: OffspringSex.female,
            visualMutations: ['spangle'],
            doubleFactorIds: {'spangle'},
          ),
        ],
      );

      final spangleWarnings =
          result.warnings.where((w) => w.combination.id == 'df_spangle');
      expect(spangleWarnings, hasLength(2));
      // (0.125 * 1.0) + (0.125 * 1.0) = 0.25
      expect(result.totalAffectedProbability, closeTo(0.25, 0.0001));
    });
  });

  group('ino-locus sub-vital pairings', () {
    test('pallid x pallid flags all offspring with subVital severity', () {
      final result = analyzer.analyze(
        fatherMutations: {'pallid'},
        motherMutations: {'pallid'},
        offspringResults: [
          _offspring(
            phenotype: 'Pallid',
            probability: 0.5,
            visualMutations: ['pallid'],
          ),
          _offspring(
            phenotype: 'Pallid carrier',
            probability: 0.5,
          ),
        ],
      );

      final pallidWarnings =
          result.warnings.where((w) => w.combination.id == 'pallid_x_pallid');
      expect(pallidWarnings, hasLength(2));
      expect(pallidWarnings.first.combination.severity,
          LethalSeverity.subVital);
    });

    test('texas_clearbody x texas_clearbody flags all offspring', () {
      final result = analyzer.analyze(
        fatherMutations: {'texas_clearbody'},
        motherMutations: {'texas_clearbody'},
        offspringResults: [
          _offspring(
            phenotype: 'Texas Clearbody',
            probability: 1.0,
            visualMutations: ['texas_clearbody'],
          ),
        ],
      );

      final tcbWarnings = result.warnings
          .where((w) => w.combination.id == 'texas_clearbody_x_texas_clearbody');
      expect(tcbWarnings, hasLength(1));
    });

    test('pallid x normal does not trigger pallid_x_pallid warning', () {
      final result = analyzer.analyze(
        fatherMutations: {'pallid'},
        motherMutations: {'blue'},
        offspringResults: [
          _offspring(phenotype: 'Pallid', probability: 0.5),
        ],
      );
      final pallidWarnings =
          result.warnings.where((w) => w.combination.id == 'pallid_x_pallid');
      expect(pallidWarnings, isEmpty);
    });
  });

  group('double-counting guard', () {
    test(
      'offspring hit by multiple warnings contributes only its highest impact',
      () {
        // Both Ino × Ino (rate=1.0) and DF Spangle (rate=1.0) would flag the
        // same DF Spangle + Ino offspring. Without deduplication, the combined
        // impact would double-count. The analyzer now keeps only the highest
        // per-offspring impact.
        final dfSpangleIno = _offspring(
          phenotype: 'DF Spangle Ino',
          probability: 0.10,
          visualMutations: ['spangle', 'ino'],
          doubleFactorIds: {'spangle'},
        );
        final plainIno = _offspring(
          phenotype: 'Ino',
          probability: 0.20,
          visualMutations: ['ino'],
        );
        final result = analyzer.analyze(
          fatherMutations: {'ino', 'spangle'},
          motherMutations: {'ino', 'spangle'},
          offspringResults: [dfSpangleIno, plainIno],
        );

        // Two distinct warning rows may exist for dfSpangleIno (ino_x_ino,
        // df_spangle) but totalAffectedProbability must reflect it once.
        final inoWarnings =
            result.warnings.where((w) => w.combination.id == 'ino_x_ino');
        final dfSpangleWarnings =
            result.warnings.where((w) => w.combination.id == 'df_spangle');
        expect(inoWarnings, isNotEmpty);
        expect(dfSpangleWarnings, isNotEmpty);

        // Expected: max(0.10*1.0, 0.10*1.0) + 0.20*1.0 = 0.30 — not 0.40.
        expect(result.totalAffectedProbability, closeTo(0.30, 0.0001));
      },
    );
  });
}
