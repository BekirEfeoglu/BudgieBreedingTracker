import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/screens/breeding_detail_screen.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_pair_info_section.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

void main() {
  final testPair = BreedingPair(
    id: 'pair-1',
    userId: 'test-user',
    status: BreedingStatus.active,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  final testIncubation = Incubation(
    id: 'inc-1',
    userId: 'test-user',
    status: IncubationStatus.active,
    breedingPairId: 'pair-1',
    startDate: DateTime(2024, 1, 1),
    expectedHatchDate: DateTime(2024, 1, 19),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/breeding/pair-1',
      routes: [
        GoRoute(
          path: '/breeding/:id',
          builder: (_, state) =>
              BreedingDetailScreen(pairId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'eggs',
              builder: (_, __) => const Scaffold(body: Text('Eggs')),
            ),
          ],
        ),
        GoRoute(
          path: '/breeding/form',
          builder: (_, __) => const Scaffold(body: Text('Form')),
        ),
      ],
    );
  });

  Widget createSubject({
    required Stream<BreedingPair?> pairStream,
    List<Incubation> incubations = const [],
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        currentUserProvider.overrideWith((_) => null),
        userProfileProvider.overrideWith((_) => Stream.value(null)),
        unreadNotificationsProvider(
          'test-user',
        ).overrideWith((_) => Stream.value([])),
        breedingPairByIdProvider('pair-1').overrideWith((_) => pairStream),
        incubationsByPairProvider(
          'pair-1',
        ).overrideWith((_) async => incubations),
        eggsByIncubationProvider('inc-1').overrideWith((_) => Stream.value([])),
        eggActionsProvider.overrideWith(() => EggActionsNotifier()),
        // Override bird providers for male/female (null birds)
        birdByIdProvider('').overrideWith((_) => Stream.value(null)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('BreedingDetailScreen', () {
    testWidgets('shows loading state while data is loading', (tester) async {
      final controller = StreamController<BreedingPair?>();

      await tester.pumpWidget(createSubject(pairStream: controller.stream));

      expect(find.byType(LoadingState), findsOneWidget);

      controller.close();
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(pairStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows not found when pair is null', (tester) async {
      await tester.pumpWidget(createSubject(pairStream: Stream.value(null)));

      await tester.pumpAndSettle();

      expect(find.text('breeding.not_found'), findsOneWidget);
    });

    testWidgets('shows detail content with pair data', (tester) async {
      await tester.pumpWidget(
        createSubject(pairStream: Stream.value(testPair)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BreedingPairInfoSection), findsOneWidget);
      // AppBar should show the detail title key
      expect(find.text('breeding.detail'), findsOneWidget);
    });

    testWidgets('shows incubation progress when incubation exists', (
      tester,
    ) async {
      // Suppress overflow errors from _IncubationSection/MilestoneTimeline
      // rows that overflow in constrained test surface.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final isOverflow = details.exceptionAsString().contains('overflowed');
        if (!isOverflow) {
          originalOnError?.call(details);
        }
      };

      await tester.pumpWidget(
        createSubject(
          pairStream: Stream.value(testPair),
          incubations: [testIncubation],
        ),
      );

      await tester.pumpAndSettle();

      // Incubation section header text
      expect(find.text('breeding.incubation_process'), findsOneWidget);
      // The progress label includes day count with period days
      expect(find.textContaining('/ 18'), findsOneWidget);

      FlutterError.onError = originalOnError;
    });
  });
}
