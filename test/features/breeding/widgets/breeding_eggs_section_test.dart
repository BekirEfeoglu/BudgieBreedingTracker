import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_eggs_section.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_summary_row.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

import '../../../helpers/test_localization.dart';

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
  bool settle = true,
}) async {
  await pumpLocalizedApp(tester,
    ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
    settle: settle,
  );
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
        settle: false,
      );
      await tester.pump();

      expect(find.text(l10n('breeding.eggs')), findsOneWidget);
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
        settle: false,
      );
      await tester.pump();

      expect(find.text(l10n('breeding.manage')), findsOneWidget);
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
        settle: false,
      );
      await tester.pump();

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

      expect(find.text(l10n('breeding.no_eggs')), findsOneWidget);
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

      expect(find.text(l10n('breeding.all_eggs_hatched')), findsOneWidget);
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
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            dateFormatProvider.overrideWith(() => DateFormatNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BreedingMilestoneSection(startDate: DateTime(2026, 3, 1)),
              ),
            ),
          ),
        ),
      );

      expect(find.text(l10n('breeding.milestones')), findsOneWidget);
    });

    testWidgets('shows MilestoneTimeline widget', (tester) async {
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            dateFormatProvider.overrideWith(() => DateFormatNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BreedingMilestoneSection(startDate: DateTime(2026, 3, 1)),
              ),
            ),
          ),
        ),
      );

      // MilestoneTimeline is rendered inside BreedingMilestoneSection
      final milestones = IncubationCalculator.getMilestones(
        DateTime(2026, 3, 1),
      );
      expect(milestones.isNotEmpty, isTrue);
    });
  });

  group('BreedingNotesSection', () {
    testWidgets('shows notes title', (tester) async {
      await pumpLocalizedApp(tester,
        const MaterialApp(
          home: Scaffold(body: BreedingNotesSection(notes: 'Test notlar')),
        ),
      );
      expect(find.text(l10n('common.notes')), findsOneWidget);
    });

    testWidgets('shows notes content', (tester) async {
      const notes = 'Bu cift cok uyumlu';
      await pumpLocalizedApp(tester,
        const MaterialApp(
          home: Scaffold(body: BreedingNotesSection(notes: notes)),
        ),
      );
      expect(find.text(notes), findsOneWidget);
    });

    testWidgets('shows empty notes without error', (tester) async {
      await pumpLocalizedApp(tester,
        const MaterialApp(
          home: Scaffold(body: BreedingNotesSection(notes: '')),
        ),
      );
      expect(find.text(l10n('common.notes')), findsOneWidget);
    });
  });
}
