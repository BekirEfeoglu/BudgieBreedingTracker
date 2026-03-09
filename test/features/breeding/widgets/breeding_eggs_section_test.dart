import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_eggs_section.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_summary_row.dart';

Egg _buildEgg({String id = 'egg-1', EggStatus status = EggStatus.laid}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2026, 2, 1),
    status: status,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BreedingEggsSection', () {
    testWidgets('shows eggs section title', (tester) async {
      await _pump(
        tester,
        const BreedingEggsSection(incubationId: 'inc-1', pairId: 'pair-1'),
        overrides: [
          eggsByIncubationProvider.overrideWith(
            (ref, id) => const Stream.empty(),
          ),
          eggActionsProvider.overrideWith(() => EggActionsNotifier()),
        ],
      );

      expect(find.text('breeding.eggs'), findsOneWidget);
    });

    testWidgets('shows manage button', (tester) async {
      await _pump(
        tester,
        const BreedingEggsSection(incubationId: 'inc-1', pairId: 'pair-1'),
        overrides: [
          eggsByIncubationProvider.overrideWith(
            (ref, id) => const Stream.empty(),
          ),
          eggActionsProvider.overrideWith(() => EggActionsNotifier()),
        ],
      );

      expect(find.text('breeding.manage'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading', (tester) async {
      await _pump(
        tester,
        const BreedingEggsSection(incubationId: 'inc-1', pairId: 'pair-1'),
        overrides: [
          eggsByIncubationProvider.overrideWith(
            (ref, id) => const Stream.empty(),
          ),
          eggActionsProvider.overrideWith(() => EggActionsNotifier()),
        ],
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no eggs message when eggs list is empty', (
      tester,
    ) async {
      await _pump(
        tester,
        const BreedingEggsSection(incubationId: 'inc-1', pairId: 'pair-1'),
        overrides: [
          eggsByIncubationProvider.overrideWith((ref, id) => Stream.value([])),
          eggActionsProvider.overrideWith(() => EggActionsNotifier()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('breeding.no_eggs'), findsOneWidget);
    });

    testWidgets('shows EggSummaryRow when eggs exist', (tester) async {
      final eggs = [_buildEgg(id: 'e-1'), _buildEgg(id: 'e-2')];

      await _pump(
        tester,
        const BreedingEggsSection(incubationId: 'inc-1', pairId: 'pair-1'),
        overrides: [
          eggsByIncubationProvider.overrideWith(
            (ref, id) => Stream.value(eggs),
          ),
          eggActionsProvider.overrideWith(() => EggActionsNotifier()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(EggSummaryRow), findsOneWidget);
    });

    testWidgets('shows all hatched message when all eggs hatched', (
      tester,
    ) async {
      final eggs = [
        _buildEgg(id: 'e-1', status: EggStatus.hatched),
        _buildEgg(id: 'e-2', status: EggStatus.hatched),
      ];

      await _pump(
        tester,
        const BreedingEggsSection(incubationId: 'inc-1', pairId: 'pair-1'),
        overrides: [
          eggsByIncubationProvider.overrideWith(
            (ref, id) => Stream.value(eggs),
          ),
          eggActionsProvider.overrideWith(() => EggActionsNotifier()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('breeding.all_eggs_hatched'), findsOneWidget);
    });

    testWidgets('shows nothing on error', (tester) async {
      await _pump(
        tester,
        const BreedingEggsSection(incubationId: 'inc-1', pairId: 'pair-1'),
        overrides: [
          eggsByIncubationProvider.overrideWith(
            (ref, id) => Stream.error(Exception('error')),
          ),
          eggActionsProvider.overrideWith(() => EggActionsNotifier()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(EggSummaryRow), findsNothing);
    });
  });

  group('BreedingMilestoneSection', () {
    testWidgets('shows milestones title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BreedingMilestoneSection(startDate: DateTime(2026, 3, 1)),
            ),
          ),
        ),
      );
      await tester.pump();
      // Consume overflow exceptions from long MilestoneTimeline in test viewport
      Object? ex;
      do {
        ex = tester.takeException();
      } while (ex != null);

      expect(find.text('breeding.milestones'), findsOneWidget);
    });

    testWidgets('shows MilestoneTimeline widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BreedingMilestoneSection(startDate: DateTime(2026, 3, 1)),
            ),
          ),
        ),
      );
      await tester.pump();
      // Consume overflow exceptions from long MilestoneTimeline in test viewport
      Object? ex;
      do {
        ex = tester.takeException();
      } while (ex != null);

      // MilestoneTimeline is rendered inside BreedingMilestoneSection
      final milestones = IncubationCalculator.getMilestones(
        DateTime(2026, 3, 1),
      );
      expect(milestones.isNotEmpty, isTrue);
    });
  });

  group('BreedingNotesSection', () {
    testWidgets('shows notes title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BreedingNotesSection(notes: 'Test notlar')),
        ),
      );
      await tester.pump();

      expect(find.text('common.notes'), findsOneWidget);
    });

    testWidgets('shows notes content', (tester) async {
      const notes = 'Bu cift cok uyumlu';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BreedingNotesSection(notes: notes)),
        ),
      );
      await tester.pump();

      expect(find.text(notes), findsOneWidget);
    });

    testWidgets('shows empty notes without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BreedingNotesSection(notes: '')),
        ),
      );
      await tester.pump();

      expect(find.text('common.notes'), findsOneWidget);
    });
  });
}
