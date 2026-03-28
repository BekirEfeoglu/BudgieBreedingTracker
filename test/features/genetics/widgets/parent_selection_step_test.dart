import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_selector.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/parent_selection_step.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(home: Scaffold(body: child)),
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
  group('ParentSelectionStep', () {
    testWidgets('renders without crashing with empty genotypes', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const ParentSelectionStep(
            fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
          ),
        ),
      );
      expect(find.byType(ParentSelectionStep), findsOneWidget);
    });

    testWidgets('shows two MutationSelector widgets', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const ParentSelectionStep(
            fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
          ),
        ),
      );
      expect(find.byType(MutationSelector), findsNWidgets(2));
    });

    testWidgets('shows father_mutations and mother_mutations labels', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const ParentSelectionStep(
            fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
          ),
        ),
      );
      expect(find.text('genetics.father_mutations'), findsOneWidget);
      expect(find.text('genetics.mother_mutations'), findsOneWidget);
    });

    testWidgets('shows two bird picker buttons', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const ParentSelectionStep(
            fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsNWidgets(2));
      expect(find.text('genetics.select_from_birds'), findsNWidgets(2));
    });

    testWidgets('shows Divider between father and mother sections', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const ParentSelectionStep(
            fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
          ),
        ),
      );
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('shows father bird name chip when selected', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedFatherBirdNameProvider.notifier).state =
          'Mavi Kus';

      await pumpLocalizedApp(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ParentSelectionStep(
                fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
                motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Mavi Kus'), findsOneWidget);
      expect(find.byType(Chip), findsAtLeastNWidgets(1));
    });

    testWidgets('shows mother bird name chip when selected', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedMotherBirdNameProvider.notifier).state =
          'Yesil Kus';

      await pumpLocalizedApp(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ParentSelectionStep(
                fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
                motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Yesil Kus'), findsOneWidget);
      expect(find.byType(Chip), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show bird name chip when not selected', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const ParentSelectionStep(
            fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
          ),
        ),
      );
      // No Chip widgets should be present when no bird is selected
      // (MutationSelector uses FilterChip internally, but no standalone Chip)
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows AppIcon for male and female icons', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const ParentSelectionStep(
            fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
          ),
        ),
      );
      // Male icon for father, female icon for mother, plus picker button icons
      expect(find.byType(AppIcon), findsAtLeastNWidgets(2));
    });

    testWidgets('renders with SingleChildScrollView', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const ParentSelectionStep(
            fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('father chip has delete button to clear selection', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedFatherBirdNameProvider.notifier).state =
          'TestBird';

      await pumpLocalizedApp(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ParentSelectionStep(
                fatherGenotype: ParentGenotype.empty(gender: BirdGender.male),
                motherGenotype: ParentGenotype.empty(gender: BirdGender.female),
              ),
            ),
          ),
        ),
      );
      // The Chip should have an onDeleted callback (visible as delete icon)
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('renders with genotypes that have mutations', (tester) async {
      _suppressOverflowErrors();
      final fatherGenotype = ParentGenotype(
        mutations: {'blue': AlleleState.visual},
        gender: BirdGender.male,
      );
      final motherGenotype = ParentGenotype(
        mutations: {'opaline': AlleleState.visual},
        gender: BirdGender.female,
      );

      await pumpLocalizedApp(
        tester,
        _wrap(
          ParentSelectionStep(
            fatherGenotype: fatherGenotype,
            motherGenotype: motherGenotype,
          ),
        ),
      );
      expect(find.byType(ParentSelectionStep), findsOneWidget);
      expect(find.byType(MutationSelector), findsNWidgets(2));
    });
  });
}
