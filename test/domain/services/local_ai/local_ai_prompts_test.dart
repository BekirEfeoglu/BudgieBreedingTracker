import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_prompts.dart';

ParentGenotype _genotype({
  BirdGender gender = BirdGender.male,
  Map<String, AlleleState> mutations = const {},
}) => ParentGenotype(mutations: mutations, gender: gender);

OffspringResult _result({
  required String phenotype,
  required double probability,
  OffspringSex sex = OffspringSex.both,
  List<String> visualMutations = const [],
  List<String> carriedMutations = const [],
}) => OffspringResult(
      phenotype: phenotype,
      probability: probability,
      sex: sex,
      visualMutations: visualMutations,
      carriedMutations: carriedMutations,
    );

void main() {
  group('LocalAiPrompts.formatGenotype', () {
    test('returns "none selected" when no mutations are present', () {
      expect(LocalAiPrompts.formatGenotype(_genotype()), 'none selected');
    });

    test('formats single mutation with allele state', () {
      final genotype = _genotype(
        mutations: const {'blue': AlleleState.visual},
      );
      expect(LocalAiPrompts.formatGenotype(genotype), 'blue:visual');
    });

    test('sorts mutations alphabetically for deterministic prompts', () {
      // Insertion order intentionally non-alphabetical
      final genotype = _genotype(
        mutations: const {
          'dilute': AlleleState.visual,
          'blue': AlleleState.carrier,
          'clearwing': AlleleState.visual,
        },
      );
      final formatted = LocalAiPrompts.formatGenotype(genotype);
      expect(
        formatted,
        'blue:carrier, clearwing:visual, dilute:visual',
      );
    });
  });

  group('LocalAiPrompts.buildGeneticsPrompt', () {
    test('includes father and mother names when provided', () {
      final prompt = LocalAiPrompts.buildGeneticsPrompt(
        father: _genotype(gender: BirdGender.male),
        mother: _genotype(gender: BirdGender.female),
        calculatorResults: const [],
        allowedGenetics: const [],
        fatherName: 'Çakır',
        motherName: 'Sarı',
      );
      expect(prompt, contains('Father(Çakır):'));
      expect(prompt, contains('Mother(Sarı):'));
    });

    test('falls back to "Unknown" when names are null or blank', () {
      final prompt = LocalAiPrompts.buildGeneticsPrompt(
        father: _genotype(),
        mother: _genotype(),
        calculatorResults: const [],
        allowedGenetics: const [],
        fatherName: '   ',
        motherName: null,
      );
      expect(prompt, contains('Father(Unknown):'));
      expect(prompt, contains('Mother(Unknown):'));
    });

    test('emits "none" when calculator results are empty', () {
      final prompt = LocalAiPrompts.buildGeneticsPrompt(
        father: _genotype(),
        mother: _genotype(),
        calculatorResults: const [],
        allowedGenetics: const [],
      );
      expect(prompt, contains('Calculator: none'));
      expect(prompt, contains('Allowed IDs: none'));
    });

    test('formats calculator results as "phenotype prob% sex" and caps at 8 entries', () {
      final results = List<OffspringResult>.generate(
        10,
        (i) => _result(
          phenotype: 'pheno_$i',
          probability: 0.1 * (i + 1),
          sex: i.isEven ? OffspringSex.male : OffspringSex.female,
        ),
      );
      final prompt = LocalAiPrompts.buildGeneticsPrompt(
        father: _genotype(),
        mother: _genotype(),
        calculatorResults: results,
        allowedGenetics: const [],
      );
      // First entry present
      expect(prompt, contains('pheno_0 10% male'));
      // 8th entry present
      expect(prompt, contains('pheno_7 80% female'));
      // 9th and 10th entries truncated
      expect(prompt, isNot(contains('pheno_8')));
      expect(prompt, isNot(contains('pheno_9')));
    });

    test('joins allowed genetics as "id(name)" tokens', () {
      final blue = MutationDatabase.getById('blue')!;
      final dilute = MutationDatabase.getById('dilute')!;
      final prompt = LocalAiPrompts.buildGeneticsPrompt(
        father: _genotype(),
        mother: _genotype(),
        calculatorResults: const [],
        allowedGenetics: [blue, dilute],
      );
      expect(prompt, contains('blue(${blue.name})'));
      expect(prompt, contains('dilute(${dilute.name})'));
    });
  });

  group('LocalAiPrompts.collectAllowedGenetics', () {
    test('returns empty list when no genetics referenced', () {
      final collected = LocalAiPrompts.collectAllowedGenetics(
        father: _genotype(),
        mother: _genotype(),
        calculatorResults: const [],
      );
      expect(collected, isEmpty);
    });

    test('collects mutation records from parents and calculator results', () {
      final father = _genotype(
        mutations: const {'blue': AlleleState.visual},
      );
      final mother = _genotype(
        gender: BirdGender.female,
        mutations: const {'dilute': AlleleState.carrier},
      );
      final results = [
        _result(
          phenotype: 'compound',
          probability: 0.25,
          visualMutations: const ['clearwing'],
          carriedMutations: const ['greywing'],
        ),
      ];

      final ids = LocalAiPrompts.collectAllowedGenetics(
        father: father,
        mother: mother,
        calculatorResults: results,
      ).map((r) => r.id).toSet();

      expect(ids, containsAll(<String>{'blue', 'dilute', 'clearwing', 'greywing'}));
    });

    test('deduplicates mutation IDs referenced in multiple places', () {
      final genotype = _genotype(
        mutations: const {'blue': AlleleState.visual},
      );
      final results = [
        _result(
          phenotype: 'blue',
          probability: 0.5,
          visualMutations: const ['blue'],
        ),
      ];
      final collected = LocalAiPrompts.collectAllowedGenetics(
        father: genotype,
        mother: genotype,
        calculatorResults: results,
      );
      expect(collected.where((r) => r.id == 'blue').length, 1);
    });

    test('returns records sorted alphabetically by name', () {
      final father = _genotype(
        mutations: const {
          'dilute': AlleleState.visual,
          'blue': AlleleState.carrier,
          'clearwing': AlleleState.visual,
        },
      );
      final mother = _genotype(gender: BirdGender.female);
      final collected = LocalAiPrompts.collectAllowedGenetics(
        father: father,
        mother: mother,
        calculatorResults: const [],
      );
      final names = collected.map((r) => r.name).toList();
      final sorted = List<String>.from(names)..sort();
      expect(names, sorted);
    });

    test('skips unknown mutation IDs (returns only valid records)', () {
      final father = _genotype(
        mutations: const {
          'blue': AlleleState.visual,
          'this_mutation_does_not_exist': AlleleState.visual,
        },
      );
      final collected = LocalAiPrompts.collectAllowedGenetics(
        father: father,
        mother: _genotype(gender: BirdGender.female),
        calculatorResults: const [],
      );
      expect(collected.map((r) => r.id), ['blue']);
    });
  });

  group('LocalAiPrompts static system prompts', () {
    test('all four system prompts mandate JSON-only Turkish output', () {
      final prompts = [
        LocalAiPrompts.systemGenetics,
        LocalAiPrompts.systemSex,
        LocalAiPrompts.systemSexWithImage,
        LocalAiPrompts.systemMutationImage,
      ];
      for (final p in prompts) {
        expect(p, isNotEmpty);
        // Each prompt must specify JSON output and Turkish language to
        // preserve UI consistency (downstream parsers + l10n contract).
        final hasJsonHint = p.contains('JSON');
        final hasTurkishHint =
            p.contains('Turkish') || p.contains('Türkçe');
        expect(hasJsonHint, isTrue, reason: 'prompt missing JSON directive');
        expect(hasTurkishHint, isTrue, reason: 'prompt missing Turkish directive');
      }
    });
  });
}
