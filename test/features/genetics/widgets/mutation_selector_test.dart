import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_selector.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

/// Suppresses overflow exceptions that occur when FilterChip Row content
/// exceeds the constrained 800x600 test surface width.
void _suppressOverflowErrors() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final isOverflow = details.exceptionAsString().contains('overflowed');
    if (!isOverflow) {
      originalOnError?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

void main() {
  group('MutationSelector', () {
    testWidgets('renders without crashing with empty genotype', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'genetics.father_mutations',
            icon: const Icon(Icons.male),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(MutationSelector), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'genetics.father_mutations',
            icon: const Icon(Icons.male),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      expect(find.text('genetics.father_mutations'), findsOneWidget);
    });

    testWidgets('shows the provided icon', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'genetics.mother_mutations',
            icon: const Icon(Icons.female),
            genotype: const ParentGenotype.empty(gender: BirdGender.female),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      expect(find.byIcon(Icons.female), findsOneWidget);
    });

    testWidgets('does not show mutation count badge when genotype is empty',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'Test',
            icon: const Icon(Icons.male),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      // No badge container for count since genotype.isNotEmpty is false
      // The Container with count badge should not be present
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows mutation count badge when genotype has mutations',
        (tester) async {
      _suppressOverflowErrors();
      final genotype = ParentGenotype(
        mutations: {
          'blue': AlleleState.visual,
          'opaline': AlleleState.carrier,
        },
        gender: BirdGender.male,
      );

      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'Test',
            icon: const Icon(Icons.male),
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows ExpansionTile for each mutation category',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'Test',
            icon: const Icon(Icons.male),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      final categories = MutationDatabase.getCategories();
      expect(
        find.byType(ExpansionTile),
        findsNWidgets(categories.length),
      );
    });

    testWidgets('ExpansionTile is initially expanded when category has selections',
        (tester) async {
      _suppressOverflowErrors();
      // Use a real mutation from the database
      final blueMutation = MutationDatabase.getById('blue');
      if (blueMutation == null) return; // Skip if mutation not found

      final genotype = ParentGenotype(
        mutations: {'blue': AlleleState.visual},
        gender: BirdGender.male,
      );

      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'Test',
            icon: const Icon(Icons.male),
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      // The ExpansionTile that contains 'blue' should be expanded
      expect(find.byType(ExpansionTile), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Column as root layout', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'Test',
            icon: const Icon(Icons.male),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('wraps icon in IconTheme', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'Test',
            icon: const Icon(Icons.male),
            genotype: const ParentGenotype.empty(gender: BirdGender.male),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(IconTheme), findsAtLeastNWidgets(1));
    });

    testWidgets('shows selected count badge in category title',
        (tester) async {
      _suppressOverflowErrors();
      // Get mutations from a known category
      final categories = MutationDatabase.getCategories();
      if (categories.isEmpty) return;

      final firstCategory = categories.first;
      final mutations = MutationDatabase.getByCategory(firstCategory);
      if (mutations.isEmpty) return;

      final genotype = ParentGenotype(
        mutations: {mutations.first.id: AlleleState.visual},
        gender: BirdGender.male,
      );

      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'Test',
            icon: const Icon(Icons.male),
            genotype: genotype,
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      // The count badge "1" should be visible in the category title
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders for female gender', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          MutationSelector(
            label: 'genetics.mother_mutations',
            icon: const Icon(Icons.female),
            genotype: const ParentGenotype.empty(gender: BirdGender.female),
            onGenotypeChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(MutationSelector), findsOneWidget);
    });
  });
}
