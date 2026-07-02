import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

OffspringResult _offspring({
  required String phenotype,
  required double probability,
  List<String> visualMutations = const [],
  String? compoundPhenotype,
  Set<String> doubleFactorIds = const {},
}) {
  return OffspringResult(
    phenotype: phenotype,
    probability: probability,
    visualMutations: visualMutations,
    compoundPhenotype: compoundPhenotype,
    doubleFactorIds: doubleFactorIds,
  );
}

void main() {
  group('LethalSeverity.labelKey', () {
    test('maps each severity to the expected localization key', () {
      expect(LethalSeverity.lethal.labelKey, 'genetics.lethal_severity_lethal');
      expect(
        LethalSeverity.semiLethal.labelKey,
        'genetics.lethal_severity_semi_lethal',
      );
      expect(
        LethalSeverity.subVital.labelKey,
        'genetics.lethal_severity_sub_vital',
      );
    });
  });

  group('LethalCombinationDatabase.getById', () {
    test('returns known combinations and null for unknown id', () {
      final crested = LethalCombinationDatabase.getById('df_crested');
      final spangle = LethalCombinationDatabase.getById('df_spangle');
      final unknown = LethalCombinationDatabase.getById('missing');

      expect(crested, isNotNull);
      expect(crested!.severity, LethalSeverity.lethal);
      expect(spangle, isNotNull);
      expect(spangle!.severity, LethalSeverity.subVital);
      expect(unknown, isNull);
    });
  });

  group('ViabilityAnalyzer.analyze', () {
    late ViabilityAnalyzer analyzer;

    setUp(() {
      analyzer = const ViabilityAnalyzer();
    });

    test(
      'returns an empty analysis when no lethal combinations are matched',
      () {
        final analysis = analyzer.analyze(
          fatherMutations: const {},
          motherMutations: const {},
          offspringResults: [
            _offspring(
              phenotype: 'Blue',
              probability: 1.0,
              visualMutations: const ['blue'],
            ),
          ],
        );

        expect(analysis.hasWarnings, isFalse);
        expect(analysis.warnings, isEmpty);
        expect(analysis.highestSeverity, isNull);
        expect(analysis.totalAffectedProbability, 0.0);
      },
    );

    test(
      'flags ino x ino for every offspring when both parents are visual ino',
      () {
        final analysis = analyzer.analyze(
          fatherMutations: const {'ino'},
          motherMutations: const {'ino'},
          offspringResults: [
            _offspring(phenotype: 'Ino', probability: 0.6),
            _offspring(phenotype: 'Ino', probability: 0.4),
          ],
        );

        expect(analysis.warnings, hasLength(2));
        expect(
          analysis.warnings.every((w) => w.combination.id == 'ino_x_ino'),
          isTrue,
        );
        expect(analysis.highestSeverity, LethalSeverity.subVital);
        expect(analysis.totalAffectedProbability, closeTo(1.0, 0.0001));
      },
    );

    test('does not flag ino x ino when only one parent is visual ino', () {
      final analysis = analyzer.analyze(
        fatherMutations: const {},
        motherMutations: const {'ino'},
        offspringResults: [
          _offspring(phenotype: 'Ino', probability: 0.5),
          _offspring(phenotype: 'Normal', probability: 0.5),
        ],
      );

      expect(
        analysis.warnings.where((w) => w.combination.id == 'ino_x_ino'),
        isEmpty,
      );
    });

    test(
      'flags only the double-factor crested offspring, not the single factor',
      () {
        final analysis = analyzer.analyze(
          fatherMutations: const {'crested_tufted'},
          motherMutations: const {'crested_full_circular'},
          offspringResults: [
            _offspring(
              phenotype: 'DF Crested',
              probability: 0.25,
              visualMutations: const ['crested_tufted'],
              doubleFactorIds: const {'crested_tufted', 'crested_full_circular'},
            ),
            _offspring(phenotype: 'Crested', probability: 0.75),
          ],
        );

        expect(analysis.warnings, hasLength(1));
        expect(analysis.warnings.single.combination.id, 'df_crested');
        expect(analysis.highestSeverity, LethalSeverity.lethal);
        expect(analysis.totalAffectedProbability, closeTo(0.25, 0.0001));
      },
    );

    test(
      'sums across combinations and clamps total affected probability to 1.0',
      () {
        final analysis = analyzer.analyze(
          fatherMutations: const {'spangle', 'ino'},
          motherMutations: const {'spangle', 'ino'},
          offspringResults: [
            _offspring(
              phenotype: 'Normal',
              probability: 0.25,
              compoundPhenotype: 'Double Factor Spangle',
              visualMutations: const ['spangle'],
              doubleFactorIds: const {'spangle'},
            ),
            _offspring(
              phenotype: 'Ino',
              probability: 0.75,
              visualMutations: const ['ino'],
            ),
          ],
        );

        expect(
          analysis.warnings.where((w) => w.combination.id == 'ino_x_ino'),
          hasLength(2),
        );
        expect(
          analysis.warnings.where((w) => w.combination.id == 'df_spangle'),
          hasLength(1),
        );
        expect(analysis.highestSeverity, LethalSeverity.subVital);
        expect(analysis.totalAffectedProbability, 1.0);
      },
    );

    test(
      'reports lethal as highest severity when lethal and sub-vital coexist',
      () {
        final analysis = analyzer.analyze(
          fatherMutations: const {'crested_tufted', 'ino'},
          motherMutations: const {'crested_half_circular', 'ino'},
          offspringResults: [
            _offspring(
              phenotype: 'DF Crested',
              probability: 0.25,
              visualMutations: const ['crested_tufted', 'ino'],
              doubleFactorIds: const {'crested_tufted', 'crested_half_circular'},
            ),
            _offspring(phenotype: 'Ino', probability: 0.75),
          ],
        );

        // Only the DF crested offspring triggers df_crested; ino_x_ino is a
        // parent-level check so it flags every offspring.
        expect(
          analysis.warnings.where((w) => w.combination.id == 'df_crested'),
          hasLength(1),
        );
        expect(
          analysis.warnings.where((w) => w.combination.id == 'ino_x_ino'),
          hasLength(2),
        );
        expect(analysis.highestSeverity, LethalSeverity.lethal);
        expect(analysis.totalAffectedProbability, 1.0);
      },
    );
  });
}
