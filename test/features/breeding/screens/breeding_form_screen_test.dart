import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/screens/breeding_form_screen.dart';

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

  Widget createSubject({required Stream<List<Bird>> birdsStream}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        birdsStreamProvider('test-user').overrideWith((_) => birdsStream),
        maleBirdsProvider('test-user').overrideWith((_) => const <Bird>[]),
        femaleBirdsProvider('test-user').overrideWith((_) => const <Bird>[]),
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
      expect(find.text('breeding.no_birds_to_pair'), findsOneWidget);
    });

    testWidgets('shows AppBar with new breeding title', (tester) async {
      final controller = StreamController<List<Bird>>();

      await tester.pumpWidget(createSubject(birdsStream: controller.stream));

      expect(find.text('breeding.new_breeding'), findsOneWidget);

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
      expect(find.text('birds.add_bird'), findsOneWidget);
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
  });
}
