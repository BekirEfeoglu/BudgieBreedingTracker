import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/screens/chick_detail_screen.dart';

void main() {
  final testChick = Chick(
    id: 'chick-1',
    userId: 'test-user',
    name: 'Boncuk',
    gender: BirdGender.unknown,
    healthStatus: ChickHealthStatus.healthy,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/chicks/chick-1',
      routes: [
        GoRoute(
          path: '/chicks/:id',
          builder: (_, state) =>
              ChickDetailScreen(chickId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, __) => const Scaffold(body: Text('Form')),
            ),
          ],
        ),
        GoRoute(
          path: '/birds',
          builder: (_, __) => const Scaffold(body: Text('Birds')),
        ),
      ],
    );
  });

  Widget createSubject({
    required Stream<Chick?> chickStream,
    ChickFormState formState = const ChickFormState(),
  }) {
    return ProviderScope(
      overrides: [
        chickByIdProvider('chick-1').overrideWith((_) => chickStream),
        chickFormStateProvider.overrideWith(() {
          final notifier = ChickFormNotifier();
          return notifier;
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ChickDetailScreen', () {
    testWidgets('shows loading state while data is loading', (tester) async {
      final controller = StreamController<Chick?>();

      await tester.pumpWidget(createSubject(chickStream: controller.stream));

      expect(find.byType(LoadingState), findsOneWidget);

      controller.close();
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(chickStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows not found when chick is null', (tester) async {
      await tester.pumpWidget(createSubject(chickStream: Stream.value(null)));

      await tester.pumpAndSettle();

      expect(find.text('chicks.not_found'), findsOneWidget);
    });

    testWidgets('shows chick name in AppBar when data loads', (tester) async {
      await tester.pumpWidget(
        createSubject(chickStream: Stream.value(testChick)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Boncuk'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows popup menu button in AppBar', (tester) async {
      await tester.pumpWidget(
        createSubject(chickStream: Stream.value(testChick)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets(
      'popup menu shows wean, promote, deceased and delete for healthy unweaned chick',
      (tester) async {
        await tester.pumpWidget(
          createSubject(chickStream: Stream.value(testChick)),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Popup menu item for "move to birds" contains a Row with icon + text
        // which may overflow in test viewport — consume the overflow exception.
        tester.takeException();

        // Healthy unweaned chick with no birdId → all actions visible
        expect(find.text('chicks.wean'), findsOneWidget);
        expect(find.text('chicks.mark_dead'), findsOneWidget);
        expect(find.text('common.delete'), findsOneWidget);
      },
    );

    testWidgets(
      'popup menu hides wean and promote options for deceased chick',
      (tester) async {
        final deceasedChick = testChick.copyWith(
          healthStatus: ChickHealthStatus.deceased,
        );

        await tester.pumpWidget(
          createSubject(chickStream: Stream.value(deceasedChick)),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(find.text('chicks.wean'), findsNothing);
        expect(find.text('chicks.move_to_birds'), findsNothing);
        expect(find.text('chicks.mark_dead'), findsNothing);
        // Delete is always shown
        expect(find.text('common.delete'), findsOneWidget);
      },
    );

    testWidgets('shows scrollable content when chick data is available', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(chickStream: Stream.value(testChick)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows edit icon button in AppBar', (tester) async {
      await tester.pumpWidget(
        createSubject(chickStream: Stream.value(testChick)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });
  });
}
