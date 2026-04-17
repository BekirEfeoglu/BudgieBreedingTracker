import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_calculator_screen.dart';

import '../../../helpers/mocks.dart';

class _FakeGeneticsHistory extends Fake implements GeneticsHistory {}

void main() {
  late MockGeneticsHistoryDao mockHistoryDao;

  setUpAll(() {
    registerFallbackValue(_FakeGeneticsHistory());
  });

  setUp(() {
    mockHistoryDao = MockGeneticsHistoryDao();
    when(
      () => mockHistoryDao.watchAll(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(() => mockHistoryDao.insertItem(any())).thenAnswer((_) async {});
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/genetics',
      routes: [
        GoRoute(
          path: '/genetics',
          builder: (_, __) => const GeneticsCalculatorScreen(),
          routes: [
            GoRoute(
              path: 'history',
              builder: (_, __) => const Scaffold(body: Text('History Screen')),
            ),
          ],
        ),
      ],
    );
  }

  final fatherWithMutation = ParentGenotype(
    gender: BirdGender.male,
    mutations: const {'blue': AlleleState.visual},
  );
  final motherWithMutation = ParentGenotype(
    gender: BirdGender.female,
    mutations: const {'blue': AlleleState.visual},
  );

  const results = [OffspringResult(phenotype: 'Blue', probability: 1.0)];

  Widget buildSubject({bool onResultsStep = true}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        currentUserProvider.overrideWith((_) => null),
        geneticsHistoryDaoProvider.overrideWithValue(mockHistoryDao),
        if (onResultsStep) ...[
          fatherGenotypeProvider.overrideWith(() {
            final n = FatherGenotypeNotifier();
            return n;
          }),
          motherGenotypeProvider.overrideWith(() {
            final n = MotherGenotypeNotifier();
            return n;
          }),
          wizardStepProvider.overrideWith(() {
            final n = WizardStepNotifier();
            return n;
          }),
          offspringResultsProvider.overrideWithValue(const AsyncData(results)),
        ],
      ],
      child: MaterialApp.router(routerConfig: buildRouter()),
    );
  }

  group('Save Calculation Dialog', () {
    testWidgets('shows note dialog when save button is tapped', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Navigate to results step and set genotype
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GeneticsCalculatorScreen)),
      );
      container.read(fatherGenotypeProvider.notifier).state =
          fatherWithMutation;
      container.read(motherGenotypeProvider.notifier).state =
          motherWithMutation;
      container.read(wizardStepProvider.notifier).state = 2;
      await tester.pumpAndSettle();

      // Find and tap save button
      final saveButton = find.text(l10n('genetics.save_calculation'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify note dialog appeared
      expect(find.text(l10n('genetics.save_note_title')), findsOneWidget);
      expect(find.text(l10n('genetics.save_note_hint')), findsOneWidget);
      expect(find.text(l10n('common.cancel')), findsOneWidget);
      expect(find.text(l10n('common.save')), findsOneWidget);
    });

    testWidgets('cancel button dismisses note dialog without saving', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GeneticsCalculatorScreen)),
      );
      container.read(fatherGenotypeProvider.notifier).state =
          fatherWithMutation;
      container.read(motherGenotypeProvider.notifier).state =
          motherWithMutation;
      container.read(wizardStepProvider.notifier).state = 2;
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('genetics.save_calculation')));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text(l10n('common.cancel')));
      await tester.pumpAndSettle();

      // Dialog dismissed, no snackbar shown
      expect(find.text(l10n('genetics.save_note_title')), findsNothing);
      expect(find.text(l10n('genetics.calculation_saved')), findsNothing);
    });

    testWidgets('save button triggers save and shows success snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GeneticsCalculatorScreen)),
      );
      container.read(fatherGenotypeProvider.notifier).state =
          fatherWithMutation;
      container.read(motherGenotypeProvider.notifier).state =
          motherWithMutation;
      container.read(wizardStepProvider.notifier).state = 2;
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('genetics.save_calculation')));
      await tester.pumpAndSettle();

      // Tap save in dialog
      await tester.tap(find.text(l10n('common.save')));
      await tester.pumpAndSettle();

      // Verify success snackbar with history action
      expect(find.text(l10n('genetics.calculation_saved')), findsOneWidget);
      expect(find.text(l10n('genetics.history')), findsAtLeastNWidgets(1));
    });

    testWidgets('note text is passed to the text field in dialog', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GeneticsCalculatorScreen)),
      );
      container.read(fatherGenotypeProvider.notifier).state =
          fatherWithMutation;
      container.read(motherGenotypeProvider.notifier).state =
          motherWithMutation;
      container.read(wizardStepProvider.notifier).state = 2;
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('genetics.save_calculation')));
      await tester.pumpAndSettle();

      // Enter a note
      await tester.enterText(find.byType(TextField), 'Test note');
      await tester.pumpAndSettle();

      // Verify the text was entered
      expect(find.text('Test note'), findsOneWidget);

      // Tap save
      await tester.tap(find.text(l10n('common.save')));
      await tester.pumpAndSettle();

      // Verify save was called
      verify(() => mockHistoryDao.insertItem(any())).called(1);
    });
  });
}
