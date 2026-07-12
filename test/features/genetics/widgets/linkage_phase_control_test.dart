import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_phase.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/linkage_phase_control.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('LinkagePhaseControl', () {
    testWidgets('hidden when father has no eligible linked pair', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Default father state is empty -> no active pair.

      await pumpLocalizedApp(
        tester,
        _wrap(container, const LinkagePhaseControl()),
      );

      expect(find.byType(SegmentedButton<LinkagePhase>), findsNothing);
    });

    testWidgets(
      'hidden when father has only a single heterozygous linked locus',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(fatherGenotypeProvider.notifier).state =
            ParentGenotype(
              gender: BirdGender.male,
              mutations: {'cinnamon': AlleleState.carrier},
            );

        await pumpLocalizedApp(
          tester,
          _wrap(container, const LinkagePhaseControl()),
        );

        expect(find.byType(SegmentedButton<LinkagePhase>), findsNothing);
      },
    );

    testWidgets('visible with 3 options when male het at a linked pair', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      );

      await pumpLocalizedApp(
        tester,
        _wrap(container, const LinkagePhaseControl()),
      );

      final segmented = tester.widget<SegmentedButton<LinkagePhase>>(
        find.byType(SegmentedButton<LinkagePhase>),
      );
      expect(segmented.segments, hasLength(3));
      expect(
        segmented.segments.map((s) => s.value).toSet(),
        LinkagePhase.values.toSet(),
      );
      // Defaults to auto (no override set yet).
      expect(segmented.selected, {LinkagePhase.auto});
    });

    testWidgets('selecting an option calls setPhaseOverride', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      );

      await pumpLocalizedApp(
        tester,
        _wrap(container, const LinkagePhaseControl()),
      );

      // Invoke the segmented button's selection callback directly (structural
      // wiring check) rather than tapping via rendered/translated text.
      final segmented = tester.widget<SegmentedButton<LinkagePhase>>(
        find.byType(SegmentedButton<LinkagePhase>),
      );
      segmented.onSelectionChanged!({LinkagePhase.coupling});

      final father = container.read(fatherGenotypeProvider);
      expect(father.phaseFor('cinnamon', 'ino'), LinkagePhase.coupling);
    });

    testWidgets('reflects an existing override as the selected segment', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      ).withPhaseOverride('cinnamon', 'ino', LinkagePhase.repulsion);

      await pumpLocalizedApp(
        tester,
        _wrap(container, const LinkagePhaseControl()),
      );

      final segmented = tester.widget<SegmentedButton<LinkagePhase>>(
        find.byType(SegmentedButton<LinkagePhase>),
      );
      expect(segmented.selected, {LinkagePhase.repulsion});
    });

    testWidgets(
      'renders as an empty box (not null) when father is at default state',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        // Father remains empty/default (male, no mutations) -> hidden.

        await pumpLocalizedApp(
          tester,
          _wrap(container, const LinkagePhaseControl()),
        );

        expect(find.byType(LinkagePhaseControl), findsOneWidget);
        expect(find.byType(SegmentedButton<LinkagePhase>), findsNothing);
      },
    );
  });
}
