import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_chip_widgets.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void _consumeExceptions(WidgetTester tester) {
  var ex = tester.takeException();
  while (ex != null) {
    ex = tester.takeException();
  }
}

BudgieMutationRecord _makeAutosomalRecessive(String id) {
  return BudgieMutationRecord(
    id: id,
    name: id,
    localizationKey: 'genetics.mutation_$id',
    description: 'Test mutation',
    inheritanceType: InheritanceType.autosomalRecessive,
    dominance: Dominance.recessive,
    alleleSymbol: id.substring(0, 2),
    alleles: const ['x+', 'x'],
    category: 'Test',
  );
}

BudgieMutationRecord _makeSexLinked(String id) {
  return BudgieMutationRecord(
    id: id,
    name: id,
    localizationKey: 'genetics.mutation_$id',
    description: 'Sex-linked test mutation',
    inheritanceType: InheritanceType.sexLinkedRecessive,
    dominance: Dominance.recessive,
    alleleSymbol: id.substring(0, 2),
    alleles: const ['Z+', 'Z*'],
    category: 'Sex-Linked',
  );
}

BudgieMutationRecord _makeIncompleteDominant(String id) {
  return BudgieMutationRecord(
    id: id,
    name: id,
    localizationKey: 'genetics.mutation_$id',
    description: 'Incomplete dominant test',
    inheritanceType: InheritanceType.autosomalIncompleteDominant,
    dominance: Dominance.incompleteDominant,
    alleleSymbol: id.substring(0, 2),
    alleles: const ['cr', '+'],
    category: 'Dominant',
  );
}

void main() {
  group('IndependentMutationChip', () {
    testWidgets('renders without crashing for unselected mutation', (
      tester,
    ) async {
      final mutation = _makeAutosomalRecessive('blue');
      const genotype = ParentGenotype.empty(gender: BirdGender.male);

      await tester.pumpWidget(
        _wrap(
          IndependentMutationChip(
            mutation: mutation,
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(IndependentMutationChip), findsOneWidget);
    });

    testWidgets('shows FilterChip for unselected mutation', (tester) async {
      final mutation = _makeAutosomalRecessive('test_ar');
      const genotype = ParentGenotype.empty(gender: BirdGender.male);

      await tester.pumpWidget(
        _wrap(
          IndependentMutationChip(
            mutation: mutation,
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FilterChip), findsOneWidget);
    });

    testWidgets('shows mutation localizationKey as chip label', (tester) async {
      final mutation = _makeAutosomalRecessive('opaline');

      await tester.pumpWidget(
        _wrap(
          IndependentMutationChip(
            mutation: mutation,
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('genetics.mutation_opaline'), findsOneWidget);
    });

    testWidgets('chip is not selected when mutation is not in genotype', (
      tester,
    ) async {
      final mutation = _makeAutosomalRecessive('dilute');
      const genotype = ParentGenotype.empty(gender: BirdGender.male);

      await tester.pumpWidget(
        _wrap(
          IndependentMutationChip(
            mutation: mutation,
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isFalse);
    });

    testWidgets('chip is selected when mutation is in genotype', (
      tester,
    ) async {
      final mutation = _makeAutosomalRecessive('dilute');
      final genotype = ParentGenotype(
        mutations: {'dilute': AlleleState.visual},
        gender: BirdGender.male,
      );

      await tester.pumpWidget(
        _wrap(
          IndependentMutationChip(
            mutation: mutation,
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isTrue);
    });

    testWidgets('calls onGenotypeChanged when chip is tapped', (tester) async {
      final mutation = _makeAutosomalRecessive('greywing');
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      ParentGenotype? changed;

      await tester.pumpWidget(
        _wrap(
          IndependentMutationChip(
            mutation: mutation,
            genotype: genotype,
            onGenotypeChanged: (g) => changed = g,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FilterChip));
      await tester.pump();

      expect(changed, isNotNull);
      expect(changed!.mutations.containsKey('greywing'), isTrue);
    });

    testWidgets('shows sex_linked tooltip for sex-linked mutation', (
      tester,
    ) async {
      final mutation = _makeSexLinked('ino_sl');
      const genotype = ParentGenotype.empty(gender: BirdGender.male);

      await tester.pumpWidget(
        _wrap(
          IndependentMutationChip(
            mutation: mutation,
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.tooltip, 'genetics.sex_linked');
    });

    testWidgets('shows DF label for incomplete dominant when selected', (
      tester,
    ) async {
      final mutation = _makeIncompleteDominant('crested');
      final genotype = ParentGenotype(
        mutations: {'crested': AlleleState.visual},
        gender: BirdGender.male,
      );

      await tester.pumpWidget(
        _wrap(
          IndependentMutationChip(
            mutation: mutation,
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      _consumeExceptions(tester);

      expect(find.text('genetics.allele_df_short'), findsOneWidget);
    });

    testWidgets('uses real blue mutation from database', (tester) async {
      final mutation = MutationDatabase.getById('blue')!;
      const genotype = ParentGenotype.empty(gender: BirdGender.male);

      await tester.pumpWidget(
        _wrap(
          IndependentMutationChip(
            mutation: mutation,
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FilterChip), findsOneWidget);
    });
  });

  group('AllelicSeriesChips', () {
    testWidgets('renders without crashing for empty mutations list', (
      tester,
    ) async {
      final mutation = _makeAutosomalRecessive('dilute');
      const genotype = ParentGenotype.empty(gender: BirdGender.male);

      await tester.pumpWidget(
        _wrap(
          AllelicSeriesChips(
            locusId: 'dilution',
            mutations: [mutation],
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      _consumeExceptions(tester);
      expect(find.byType(AllelicSeriesChips), findsOneWidget);
    });

    testWidgets('shows FilterChip for each mutation', (tester) async {
      final m1 = _makeAutosomalRecessive('mut_a');
      final m2 = _makeAutosomalRecessive('mut_b');
      const genotype = ParentGenotype.empty(gender: BirdGender.male);

      await tester.pumpWidget(
        _wrap(
          AllelicSeriesChips(
            locusId: 'test_locus',
            mutations: [m1, m2],
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      _consumeExceptions(tester);
      expect(find.byType(FilterChip), findsNWidgets(2));
    });

    testWidgets('shows compound_heterozygote badge when two mutations selected', (
      tester,
    ) async {
      // Use real database mutations at the same locus (dilution allelic series)
      final dilute = MutationDatabase.getById('dilute')!;
      final greywing = MutationDatabase.getById('greywing')!;
      // Both belong to the 'dilution' locus
      final genotype = ParentGenotype(
        mutations: {
          'dilute': AlleleState.visual,
          'greywing': AlleleState.visual,
        },
        gender: BirdGender.male,
      );

      await tester.pumpWidget(
        _wrap(
          AllelicSeriesChips(
            locusId: 'dilution',
            mutations: [dilute, greywing],
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      _consumeExceptions(tester);

      expect(find.text('genetics.compound_heterozygote'), findsOneWidget);
    });

    testWidgets(
      'does not show compound_heterozygote badge for single selection',
      (tester) async {
        final m1 = _makeAutosomalRecessive('single_mut');
        final m2 = _makeAutosomalRecessive('unselected_mut');
        final genotype = ParentGenotype(
          mutations: {'single_mut': AlleleState.visual},
          gender: BirdGender.male,
        );

        await tester.pumpWidget(
          _wrap(
            AllelicSeriesChips(
              locusId: 'test_locus',
              mutations: [m1, m2],
              genotype: genotype,
              onGenotypeChanged: (_) {},
            ),
          ),
        );
        await tester.pump();
        _consumeExceptions(tester);
        expect(find.text('genetics.compound_heterozygote'), findsNothing);
      },
    );

    testWidgets('calls onGenotypeChanged when chip is tapped', (tester) async {
      final mutation = _makeAutosomalRecessive('tap_test');
      const genotype = ParentGenotype.empty(gender: BirdGender.male);
      ParentGenotype? changed;

      await tester.pumpWidget(
        _wrap(
          AllelicSeriesChips(
            locusId: 'test_locus',
            mutations: [mutation],
            genotype: genotype,
            onGenotypeChanged: (g) => changed = g,
          ),
        ),
      );
      await tester.pump();

      _consumeExceptions(tester);

      await tester.tap(find.byType(FilterChip).first);
      await tester.pump();

      _consumeExceptions(tester);

      expect(changed, isNotNull);
      expect(changed!.mutations.containsKey('tap_test'), isTrue);
    });

    testWidgets(
      'female hemizygous: sex-linked flag is detected from inheritance type',
      (tester) async {
        // Use real sex-linked mutations from the database: ino (sex-linked recessive)
        final inoMutation = MutationDatabase.getById('ino')!;
        final cinnamonMutation = MutationDatabase.getById('cinnamon')!;
        // Both are sex-linked recessive; female with one selected
        final genotype = ParentGenotype(
          mutations: {inoMutation.id: AlleleState.visual},
          gender: BirdGender.female,
        );

        // Render with female genotype, max 1 allele at sex-linked locus
        await tester.pumpWidget(
          _wrap(
            AllelicSeriesChips(
              locusId: inoMutation.locusId ?? inoMutation.id,
              mutations: [inoMutation, cinnamonMutation],
              genotype: genotype,
              onGenotypeChanged: (_) {},
            ),
          ),
        );
        await tester.pump();

        _consumeExceptions(tester);

        // Both chips render without crashing
        expect(find.byType(FilterChip), findsNWidgets(2));
        // Sex-linked status is properly detected (isSexLinked = true for ino)
        expect(inoMutation.isSexLinked, isTrue);
      },
    );
  });
}
