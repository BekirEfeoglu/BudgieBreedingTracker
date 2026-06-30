import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/screens/breeding_form_screen.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/breeding/form',
      routes: [
        GoRoute(
          path: '/breeding',
          builder: (_, __) => const Scaffold(body: Text('Breeding')),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, state) => BreedingFormScreen(
                editPairId: state.uri.queryParameters['editId'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/birds/form',
          builder: (_, __) => const Scaffold(body: Text('Bird Form')),
        ),
        GoRoute(
          path: '/premium',
          builder: (_, __) => const Scaffold(body: Text('Premium')),
        ),
      ],
    );
  });

  Widget createSubject({
    required Stream<List<Bird>> birdsStream,
    List<Bird> maleBirds = const <Bird>[],
    List<Bird> femaleBirds = const <Bird>[],
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        birdsStreamProvider('test-user').overrideWith((_) => birdsStream),
        maleBirdsProvider('test-user').overrideWith((_) => maleBirds),
        femaleBirdsProvider('test-user').overrideWith((_) => femaleBirds),
        breedingFormStateProvider.overrideWith(() => BreedingFormNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('BreedingFormScreen', () {
    testWidgets('shows loading state while birds are loading', (tester) async {
      final controller = StreamController<List<Bird>>();

      await tester.pumpWidget(createSubject(birdsStream: controller.stream));

      expect(find.byType(LoadingState), findsOneWidget);

      controller.close();
    });

    testWidgets('shows empty state when no birds exist', (tester) async {
      await tester.pumpWidget(createSubject(birdsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(l10n('breeding.no_birds_to_pair')), findsOneWidget);
    });

    testWidgets('shows AppBar with new breeding title', (tester) async {
      final controller = StreamController<List<Bird>>();

      await tester.pumpWidget(createSubject(birdsStream: controller.stream));

      expect(find.text(l10n('breeding.new_breeding')), findsOneWidget);

      controller.close();
    });

    testWidgets('shows form when birds are available', (tester) async {
      // Provide some birds so the form is shown
      final List<Bird> birds = [
        Bird(
          id: 'bird-1',
          userId: 'test-user',
          name: 'Kuş 1',
          gender: BirdGender.unknown,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        Bird(
          id: 'bird-2',
          userId: 'test-user',
          name: 'Kuş 2',
          gender: BirdGender.unknown,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createSubject(birdsStream: Stream.value(birds)));

      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('shows save button when form is rendered', (tester) async {
      final List<Bird> birds = [
        Bird(
          id: 'bird-1',
          userId: 'test-user',
          name: 'TestKuş',
          gender: BirdGender.male,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createSubject(birdsStream: Stream.value(birds)));
      await tester.pumpAndSettle();

      // PrimaryButton wraps a FilledButton
      expect(
        find.byWidgetPredicate((w) => w is FilledButton || w is ElevatedButton),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows text form fields for cage and notes', (tester) async {
      final List<Bird> birds = [
        Bird(
          id: 'bird-1',
          userId: 'test-user',
          name: 'TestKuş',
          gender: BirdGender.male,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createSubject(birdsStream: Stream.value(birds)));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('hint in empty state leads to add bird route', (tester) async {
      await tester.pumpWidget(createSubject(birdsStream: Stream.value([])));
      await tester.pumpAndSettle();

      // The empty state action button label
      expect(find.text(l10n('birds.add_bird')), findsOneWidget);
    });

    testWidgets('shows error message on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(birdsStream: Stream.error('Connection lost')),
      );
      await tester.pumpAndSettle();

      // When error occurs a Center(child: Text) is shown in the body.
      // The text includes the key 'common.error' and the error message.
      expect(find.byType(Center), findsAtLeastNWidgets(1));
    });

    testWidgets('shows inbreeding warning for related selected birds', (
      tester,
    ) async {
      final father = createTestBird(
        id: 'father',
        userId: 'test-user',
        name: 'Baba',
        gender: BirdGender.male,
      );
      final daughter = createTestBird(
        id: 'daughter',
        userId: 'test-user',
        name: 'Yavru',
        gender: BirdGender.female,
        fatherId: father.id,
      );
      final birds = [father, daughter];

      await tester.pumpWidget(
        createSubject(
          birdsStream: Stream.value(birds),
          maleBirds: [father],
          femaleBirds: [daughter],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Baba').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yavru').last);
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('breeding.inbreeding_warning_title')),
        findsOneWidget,
      );
      // Match the percentage badge specifically so this assertion isn't tripped
      // by date strings like "25.05.YYYY" that would also contain "25.0".
      expect(find.textContaining('25.0%'), findsOneWidget);
    });

    testWidgets(
      'disables Save while the inbreeding confirmation dialog is pending',
      (tester) async {
        final father = createTestBird(
          id: 'father',
          userId: 'test-user',
          name: 'Baba',
          gender: BirdGender.male,
        );
        final daughter = createTestBird(
          id: 'daughter',
          userId: 'test-user',
          name: 'Yavru',
          gender: BirdGender.female,
          fatherId: father.id,
        );
        final birds = [father, daughter];

        await tester.pumpWidget(
          createSubject(
            birdsStream: Stream.value(birds),
            maleBirds: [father],
            femaleBirds: [daughter],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Baba').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<String>).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yavru').last);
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(PrimaryButton, l10n('common.save')),
        );
        // One frame: enough for _submit() to run synchronously up to the
        // awaited inbreeding-confirmation dialog, but not enough to resolve
        // it — this is exactly the window the double-submit guard covers.
        await tester.pump();

        expect(
          find.text(l10n('breeding.inbreeding_confirm_title')),
          findsOneWidget,
        );
        // isLoading swaps the button's child for a spinner, so the label
        // text is gone — find by type instead (the Save button is the only
        // PrimaryButton on this screen).
        final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
        expect(button.isLoading, isTrue);

        // Resolve the dialog via Cancel so the test doesn't proceed into
        // notifier.createBreeding (no repository overrides in this subject).
        await tester.tap(find.text(l10n('common.cancel')).last);
        await tester.pumpAndSettle();

        final resetButton = tester.widget<PrimaryButton>(
          find.byType(PrimaryButton),
        );
        expect(resetButton.isLoading, isFalse);
      },
    );
  });
}
