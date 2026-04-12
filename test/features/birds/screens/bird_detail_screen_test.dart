import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/screens/bird_detail_screen.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

void main() {
  final testBird = Bird(
    id: 'bird-1',
    name: 'Mavi',
    userId: 'test-user',
    gender: BirdGender.male,
    status: BirdStatus.alive,
    species: Species.budgie,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/birds/bird-1',
      routes: [
        GoRoute(
          path: '/birds/:id',
          builder: (_, state) =>
              BirdDetailScreen(birdId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, __) => const Scaffold(body: Text('Form')),
            ),
          ],
        ),
        GoRoute(
          path: '/genealogy',
          builder: (_, __) => const Scaffold(body: Text('Genealogy')),
        ),
      ],
    );
  });

  Widget createSubject({
    required Stream<Bird?> birdStream,
    Stream<List<Bird>> birdsStream = const Stream.empty(),
    Stream<List<String>> photosStream = const Stream.empty(),
    BirdFormState formState = const BirdFormState(),
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        currentUserProvider.overrideWith((_) => null),
        userProfileProvider.overrideWith((_) => Stream.value(null)),
        unreadNotificationsProvider(
          'test-user',
        ).overrideWith((_) => Stream.value([])),
        birdByIdProvider('bird-1').overrideWith((_) => birdStream),
        birdsStreamProvider.overrideWith((_, __) => birdsStream),
        birdPhotosProvider.overrideWith((_, __) => photosStream),
        healthRecordsByBirdProvider.overrideWith((_, __) => Stream.value([])),
        birdFormStateProvider.overrideWith(() {
          final notifier = BirdFormNotifier();
          return notifier;
        }),
        selectedEntityForTreeProvider.overrideWith(
          () => SelectedEntityForTreeNotifier(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('BirdDetailScreen', () {
    testWidgets('shows loading state while data is loading', (tester) async {
      final controller = StreamController<Bird?>();

      await tester.pumpWidget(createSubject(birdStream: controller.stream));

      expect(find.byType(LoadingState), findsOneWidget);

      controller.close();
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(birdStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows not found when bird is null', (tester) async {
      await tester.pumpWidget(createSubject(birdStream: Stream.value(null)));

      await tester.pumpAndSettle();

      // "birds.not_found" key should be rendered (untranslated in tests)
      expect(find.text(l10n('birds.not_found')), findsOneWidget);
    });

    testWidgets('shows bird name in AppBar when data loads', (tester) async {
      await tester.pumpWidget(
        createSubject(birdStream: Stream.value(testBird)),
      );

      await tester.pumpAndSettle();

      // Bird name may appear in AppBar and in body content
      expect(find.text('Mavi'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows edit icon button in AppBar', (tester) async {
      await tester.pumpWidget(
        createSubject(birdStream: Stream.value(testBird)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('shows popup menu with dead and sold options for alive bird', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(birdStream: Stream.value(testBird)),
      );

      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.mark_dead')), findsOneWidget);
      expect(find.text(l10n('birds.sold')), findsOneWidget);
      expect(find.text(l10n('common.delete')), findsOneWidget);
    });

    testWidgets('popup menu hides dead/sold options for non-alive bird', (
      tester,
    ) async {
      final deadBird = testBird.copyWith(status: BirdStatus.dead);
      await tester.pumpWidget(
        createSubject(birdStream: Stream.value(deadBird)),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.mark_dead')), findsNothing);
      expect(find.text(l10n('birds.sold')), findsNothing);
      expect(find.text(l10n('common.delete')), findsOneWidget);
    });

    testWidgets('shows scrollable content when bird data is available', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(birdStream: Stream.value(testBird)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
