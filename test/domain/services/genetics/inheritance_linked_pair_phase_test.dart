import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_phase.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import 'genetics_test_helpers.dart';

/// Tests for explicit linkage phase override consultation in
/// [MendelianCalculator] via `_calculateGenericLinkedPair`.
///
/// Fixtures mirror `genetics_linkage_test.dart`'s Cinnamon-Ino group
/// (3 cM linkage) so expected coupling/repulsion distributions are
/// reused verbatim from that suite.
void main() {
  const calculator = MendelianCalculator();

  group('Explicit linkage phase override (Cinnamon-Ino, 3 cM)', () {
    test(
      'override=coupling on a split (auto=repulsion) father matches '
      'coupling distribution',
      () {
        // Auto inference for split+split is repulsion; override forces
        // coupling instead — offspring distribution must match the
        // coupling fixture (carrier+carrier, auto) from
        // genetics_linkage_test.dart, not the repulsion one.
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'cinnamon': AlleleState.split,
            'ino': AlleleState.split,
          },
        ).withPhaseOverride('cinnamon', 'ino', LinkagePhase.coupling);
        final mother = ParentGenotype(gender: BirdGender.female, mutations: {});

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expectNormalizedProbabilities(results);

        // Coupling: parental Lacewing daughters common (~24.25%).
        final lacewingFemale = findResult(
          results,
          'Lacewing',
          sex: OffspringSex.female,
        );
        expect(lacewingFemale, isNotNull);
        expect(lacewingFemale!.probability, closeTo(0.2425, 0.02));

        // Coupling: recombinant Cinnamon-only/Ino-only daughters rare (~0.75%).
        final cinOnlyFemale = findResult(
          results,
          'Cinnamon',
          sex: OffspringSex.female,
        );
        if (cinOnlyFemale != null) {
          expect(cinOnlyFemale.probability, closeTo(0.0075, 0.005));
        }

        final normalFemale = sumProbability(
          results,
          'Normal',
          sex: OffspringSex.female,
        );
        expect(normalFemale, closeTo(0.2425, 0.02));
      },
    );

    test(
      'override=repulsion on a carrier (auto=coupling) father matches '
      'repulsion distribution',
      () {
        // Auto inference for carrier+carrier is coupling; override forces
        // repulsion instead — offspring distribution must match the
        // repulsion fixture (split+split, auto) from
        // genetics_linkage_test.dart, not the coupling one.
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'cinnamon': AlleleState.carrier,
            'ino': AlleleState.carrier,
          },
        ).withPhaseOverride('cinnamon', 'ino', LinkagePhase.repulsion);
        final mother = ParentGenotype(gender: BirdGender.female, mutations: {});

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expectNormalizedProbabilities(results);

        // Repulsion: recombinant Lacewing daughters rare (~0.75%).
        final lacewingFemale = findResult(
          results,
          'Lacewing',
          sex: OffspringSex.female,
        );
        if (lacewingFemale != null) {
          expect(lacewingFemale.probability, closeTo(0.0075, 0.005));
        }

        // Repulsion: parental Cinnamon-only daughters common (~24.25%).
        final cinFemale = sumProbability(
          results,
          'Cinnamon',
          sex: OffspringSex.female,
        );
        expect(cinFemale, closeTo(0.2425, 0.02));

        // Repulsion: parental Ino-only daughters common (~24.25%).
        final inoFemaleProb = results
            .where(
              (r) =>
                  r.sex == OffspringSex.female &&
                  r.phenotype == 'Ino' &&
                  !r.visualMutations.contains('cinnamon'),
            )
            .fold<double>(0, (s, r) => s + r.probability);
        expect(inoFemaleProb, closeTo(0.2425, 0.02));
      },
    );

    test(
      'phaseFor id order does not matter (linkagePairKey is order-independent)',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'cinnamon': AlleleState.split,
            'ino': AlleleState.split,
          },
          // Override with args reversed relative to the mutation ids used
          // internally ('cinnamon' is mutId1, 'ino' is mutId2 in the linked
          // pair calc) — phaseFor must still resolve it.
        ).withPhaseOverride('ino', 'cinnamon', LinkagePhase.coupling);

        expect(father.phaseFor('cinnamon', 'ino'), LinkagePhase.coupling);
        expect(father.phaseFor('ino', 'cinnamon'), LinkagePhase.coupling);

        final mother = ParentGenotype(gender: BirdGender.female, mutations: {});
        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );
        expectNormalizedProbabilities(results);

        final lacewingFemale = findResult(
          results,
          'Lacewing',
          sex: OffspringSex.female,
        );
        expect(lacewingFemale, isNotNull);
        expect(lacewingFemale!.probability, closeTo(0.2425, 0.02));
      },
    );

    test(
      'explicit auto override is equivalent to no override at all',
      () {
        final mother = ParentGenotype(gender: BirdGender.female, mutations: {});

        final plainFather = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'cinnamon': AlleleState.carrier,
            'ino': AlleleState.carrier,
          },
        );
        // Setting auto explicitly must remove any prior override (a no-op
        // here since none was set) and fall through to the same inference.
        final explicitAutoFather = plainFather.withPhaseOverride(
          'cinnamon',
          'ino',
          LinkagePhase.auto,
        );

        expect(explicitAutoFather.phaseFor('cinnamon', 'ino'), LinkagePhase.auto);

        final plainResults = calculator.calculateFromGenotypes(
          father: plainFather,
          mother: mother,
        );
        final autoResults = calculator.calculateFromGenotypes(
          father: explicitAutoFather,
          mother: mother,
        );

        expectNormalizedProbabilities(plainResults);
        expectNormalizedProbabilities(autoResults);

        expect(autoResults.length, plainResults.length);
        for (final plain in plainResults) {
          final matching = autoResults.firstWhere(
            (r) => r.phenotype == plain.phenotype && r.sex == plain.sex,
          );
          expect(matching.probability, closeTo(plain.probability, 1e-9));
        }
      },
    );

    test(
      'setting auto after an explicit override removes it (round trip)',
      () {
        final overridden = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'cinnamon': AlleleState.carrier,
            'ino': AlleleState.carrier,
          },
        ).withPhaseOverride('cinnamon', 'ino', LinkagePhase.repulsion);
        expect(overridden.phaseFor('cinnamon', 'ino'), LinkagePhase.repulsion);

        final revertedToAuto = overridden.withPhaseOverride(
          'cinnamon',
          'ino',
          LinkagePhase.auto,
        );
        expect(revertedToAuto.phaseFor('cinnamon', 'ino'), LinkagePhase.auto);
        expect(revertedToAuto.phaseOverrides, isEmpty);
      },
    );
  });
}
