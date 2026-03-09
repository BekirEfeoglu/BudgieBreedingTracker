import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/selection_summary.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('SelectionSummary', () {
    testWidgets('renders without crashing with empty male genotype', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SelectionSummary(
            label: 'test.male.label',
            icon: const Icon(Icons.person),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SelectionSummary), findsOneWidget);
    });

    testWidgets('shows no_mutations_selected when genotype is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SelectionSummary(
            label: 'test.label',
            icon: const Icon(Icons.person),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('genetics.no_mutations_selected'), findsOneWidget);
    });

    testWidgets('shows label text when genotype is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SelectionSummary(
            label: 'test.my.label',
            icon: const Icon(Icons.person),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('test.my.label'), findsOneWidget);
    });

    testWidgets('renders Row layout when genotype is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SelectionSummary(
            label: 'test.label',
            icon: const Icon(Icons.person),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'does not show no_mutations_selected when genotype has mutations',
      (tester) async {
        final genotype = ParentGenotype(
          mutations: {'nonexistent_mutation_id': AlleleState.visual},
          gender: BirdGender.male,
        );
        await tester.pumpWidget(
          _wrap(
            SelectionSummary(
              label: 'test.label',
              icon: const Icon(Icons.person),
              genotype: genotype,
              onGenotypeChanged: (_) {},
            ),
          ),
        );
        await tester.pump();

        expect(find.text('genetics.no_mutations_selected'), findsNothing);
      },
    );

    testWidgets('shows Column layout when genotype has mutations', (
      tester,
    ) async {
      final genotype = ParentGenotype(
        mutations: {'nonexistent_mutation_id': AlleleState.carrier},
        gender: BirdGender.male,
      );
      await tester.pumpWidget(
        _wrap(
          SelectionSummary(
            label: 'test.label',
            icon: const Icon(Icons.person),
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('works with female gender empty genotype', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SelectionSummary(
            label: 'test.female.label',
            icon: const Icon(Icons.person_outline),
            genotype: const ParentGenotype.empty(gender: BirdGender.female),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SelectionSummary), findsOneWidget);
      expect(find.text('genetics.no_mutations_selected'), findsOneWidget);
    });

    testWidgets('shows label text when genotype has mutations', (tester) async {
      final genotype = ParentGenotype(
        mutations: {'nonexistent_id': AlleleState.visual},
        gender: BirdGender.female,
      );
      await tester.pumpWidget(
        _wrap(
          SelectionSummary(
            label: 'test.female.selected.label',
            icon: const Icon(Icons.person_outline),
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('test.female.selected.label'), findsOneWidget);
    });
  });
}
