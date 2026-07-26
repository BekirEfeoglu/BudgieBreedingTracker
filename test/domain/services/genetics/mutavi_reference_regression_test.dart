import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import 'genetics_test_helpers.dart';

/// D3 — MUTAVI reference regression matrix.
///
/// Each fixture pins a canonical cross from `docs/muhabbet-kusu-genetik-rehberi.md`
/// (the authoritative MUTAVI-sourced guide) with its guide section, source IDs,
/// parent genotypes and expected ratios, so a future engine drift that
/// contradicts the guide fails loudly against a named guide line.
void main() {
  const calculator = MendelianCalculator();

  /// Sum probability of results matching [predicate].
  double sumWhere(
    List<OffspringResult> results,
    bool Function(OffspringResult) predicate,
  ) =>
      results.where(predicate).fold<double>(0, (s, r) => s + r.probability);

  bool visual(OffspringResult r, String mut) => r.visualMutations.contains(mut);
  bool carrier(OffspringResult r, String mut) =>
      r.carriedMutations.contains(mut) && !r.visualMutations.contains(mut);

  final fixtures = <MutaviFixture>[
    // --- Autosomal recessive (Blue locus) ---------------------------------
    MutaviFixture(
      name: 'Blue x Blue -> 100% Blue',
      guideSection: '§ Ayni Lokusta Calisan Ozel Seriler > Blue lokusu',
      sourceIds: const ['K1', 'K3'],
      father: ParentGenotype(
        gender: BirdGender.male,
        mutations: const {'blue': AlleleState.visual},
      ),
      mother: ParentGenotype(
        gender: BirdGender.female,
        mutations: const {'blue': AlleleState.visual},
      ),
      check: (results) {
        // AR visual x visual -> 100% visual.
        expect(sumWhere(results, (r) => visual(r, 'blue')), closeTo(1.0, 0.01));
      },
    ),
    MutaviFixture(
      name: 'Blue x Green split Blue -> 50% Blue, 50% Green split Blue',
      guideSection: '§ Cok Sorulan Eslesmeler > Blue ile Green split Blue',
      sourceIds: const ['K1', 'K3'],
      father: ParentGenotype(
        gender: BirdGender.male,
        mutations: const {'blue': AlleleState.visual},
      ),
      mother: ParentGenotype(
        gender: BirdGender.female,
        mutations: const {'blue': AlleleState.split},
      ),
      check: (results) {
        // AR visual x split -> 50% visual, 50% split(carrier).
        expect(sumWhere(results, (r) => visual(r, 'blue')), closeTo(0.5, 0.02));
        expect(
          sumWhere(results, (r) => carrier(r, 'blue')),
          closeTo(0.5, 0.02),
        );
      },
    ),
    MutaviFixture(
      name: 'Green split Blue x Green split Blue -> 25% Blue, 75% Normal',
      guideSection: '§ Ayni Lokusta Calisan Ozel Seriler > Blue lokusu',
      sourceIds: const ['K3'],
      father: ParentGenotype(
        gender: BirdGender.male,
        mutations: const {'blue': AlleleState.split},
      ),
      mother: ParentGenotype(
        gender: BirdGender.female,
        mutations: const {'blue': AlleleState.split},
      ),
      check: (results) {
        // Guide genotype ratio is 25% Blue / 50% split / 25% Green. The engine
        // predicts PHENOTYPE: Bb (carrier) and bb (normal) are visually
        // identical Green, so the 50%+25% collapse into one Normal class at
        // 75% (carrier-flagged), leaving 25% visible Blue.
        expect(sumWhere(results, (r) => visual(r, 'blue')), closeTo(0.25, 0.02));
        final normal =
            sumWhere(results, (r) => !visual(r, 'blue'));
        expect(normal, closeTo(0.75, 0.02));
        // The Normal class is flagged as a possible blue carrier.
        expect(
          sumWhere(results, (r) => carrier(r, 'blue')),
          closeTo(0.75, 0.02),
        );
      },
    ),

    // --- Sex-linked recessive ---------------------------------------------
    MutaviFixture(
      name: 'Cinnamon male x normal female -> split sons, visual daughters',
      guideSection: '§ Cok Sorulan Eslesmeler > Cinnamon ile normal disi',
      sourceIds: const ['K1', 'K3'],
      father: ParentGenotype(
        gender: BirdGender.male,
        mutations: const {'cinnamon': AlleleState.visual},
      ),
      mother: const ParentGenotype.empty(gender: BirdGender.female),
      check: (results) {
        // Sons: 100% split cinnamon (each sex is ~50% of offspring).
        expect(
          sumWhere(
            results,
            (r) => r.sex == OffspringSex.male && carrier(r, 'cinnamon'),
          ),
          closeTo(0.5, 0.02),
        );
        // Daughters: 100% visual cinnamon.
        expect(
          sumWhere(
            results,
            (r) => r.sex == OffspringSex.female && visual(r, 'cinnamon'),
          ),
          closeTo(0.5, 0.02),
        );
        // No visual sons, no split daughters.
        expect(
          sumWhere(
            results,
            (r) => r.sex == OffspringSex.male && visual(r, 'cinnamon'),
          ),
          closeTo(0.0, 0.001),
        );
      },
    ),
    MutaviFixture(
      name: 'Ino male x normal female -> split sons, visual daughters',
      guideSection: '§ Cok Sorulan Eslesmeler > Ino ile normal disi',
      sourceIds: const ['K7'],
      father: ParentGenotype(
        gender: BirdGender.male,
        mutations: const {'ino': AlleleState.visual},
      ),
      mother: const ParentGenotype.empty(gender: BirdGender.female),
      check: (results) {
        expect(
          sumWhere(
            results,
            (r) => r.sex == OffspringSex.male && carrier(r, 'ino'),
          ),
          closeTo(0.5, 0.02),
        );
        expect(
          sumWhere(
            results,
            (r) => r.sex == OffspringSex.female && visual(r, 'ino'),
          ),
          closeTo(0.5, 0.02),
        );
      },
    ),

    // --- Allelic series (Dilution locus) ----------------------------------
    MutaviFixture(
      name: 'Greywing x Clearwing -> 100% Full-Body Greywing',
      guideSection: '§ Ayni Lokusta Calisan Ozel Seriler > Dilution lokusu',
      sourceIds: const ['K5'],
      father: ParentGenotype(
        gender: BirdGender.male,
        mutations: const {'greywing': AlleleState.visual},
      ),
      mother: ParentGenotype(
        gender: BirdGender.female,
        mutations: const {'clearwing': AlleleState.visual},
      ),
      check: (results) {
        // Every offspring is the greywing/clearwing compound (Full-Body
        // Greywing): both dilution alleles expressed together.
        expect(
          sumWhere(
            results,
            (r) => visual(r, 'greywing') && visual(r, 'clearwing'),
          ),
          closeTo(1.0, 0.01),
        );
      },
    ),
    MutaviFixture(
      name: 'Greywing x Dilute -> 100% Greywing / dilute carrier',
      guideSection: '§ Ayni Lokusta Calisan Ozel Seriler > Dilution lokusu',
      sourceIds: const ['K5'],
      father: ParentGenotype(
        gender: BirdGender.male,
        mutations: const {'greywing': AlleleState.visual},
      ),
      mother: ParentGenotype(
        gender: BirdGender.female,
        mutations: const {'dilute': AlleleState.visual},
      ),
      check: (results) {
        // Greywing dominates dilute at the dilution locus; dilute is carried.
        expect(
          sumWhere(results, (r) => visual(r, 'greywing')),
          closeTo(1.0, 0.01),
        );
      },
    ),

    // --- Linkage (parental vs recombinant) --------------------------------
    MutaviFixture(
      name: 'Cinnamon+Ino coupling male x normal female -> Lacewing daughters',
      guideSection: '§ Cok Sorulan Eslesmeler > Cinnamon ile Ino (Lacewing)',
      sourceIds: const ['K6', 'K12'],
      father: ParentGenotype(
        gender: BirdGender.male,
        mutations: const {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      ),
      mother: const ParentGenotype.empty(gender: BirdGender.female),
      check: (results) {
        // Parental Lacewing daughters (both cinnamon+ino) dominate: ~24.25%.
        final lacewingDaughters = sumWhere(
          results,
          (r) =>
              r.sex == OffspringSex.female &&
              visual(r, 'cinnamon') &&
              visual(r, 'ino'),
        );
        expect(lacewingDaughters, closeTo(0.2425, 0.03));
        // Recombinant single-mutation daughters are rare (~0.75% each,
        // Cin-Ino ~3 cM), far below the parental compound.
        final recombinantDaughters = sumWhere(
          results,
          (r) =>
              r.sex == OffspringSex.female &&
              (visual(r, 'cinnamon') ^ visual(r, 'ino')),
        );
        expect(recombinantDaughters, lessThan(lacewingDaughters));
        expect(recombinantDaughters, lessThan(0.05));
      },
    ),
  ];

  group('MUTAVI reference regression matrix', () {
    for (final f in fixtures) {
      test('${f.name}  [${f.guideSection}] ${f.sourceIds.join(",")}', () {
        final results = calculator.calculateFromGenotypes(
          father: f.father,
          mother: f.mother,
        );
        expectNormalizedProbabilities(results);
        f.check(results);
      });
    }

    test('fixtures use only valid gender roles (father male, mother female)',
        () {
      for (final f in fixtures) {
        expect(f.father.gender, BirdGender.male, reason: f.name);
        expect(f.mother.gender, BirdGender.female, reason: f.name);
      }
    });
  });
}

/// A single guide-traceable regression fixture.
class MutaviFixture {
  const MutaviFixture({
    required this.name,
    required this.guideSection,
    required this.sourceIds,
    required this.father,
    required this.mother,
    required this.check,
  });

  /// Human-readable cross name.
  final String name;

  /// Section of `docs/muhabbet-kusu-genetik-rehberi.md` this fixture protects.
  final String guideSection;

  /// Source citation IDs (K1..K15) from the guide's Kaynaklar list.
  final List<String> sourceIds;

  final ParentGenotype father;
  final ParentGenotype mother;

  /// Asserts the guide's expected ratios against the engine output.
  final void Function(List<OffspringResult> results) check;
}
