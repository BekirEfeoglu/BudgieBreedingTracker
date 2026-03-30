import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/screens/breeding_list_screen.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

class _MockAdService extends Mock implements AdService {
  @override
  Future<void> ensureSdkInitialized() async {}
}

void main() {
  BreedingPair makePair({
    String id = 'pair-1',
    BreedingStatus status = BreedingStatus.active,
    String? cageNumber,
  }) {
    return BreedingPair(
      id: id,
      userId: 'test-user',
      status: status,
      cageNumber: cageNumber,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/breeding',
      routes: [
        GoRoute(
          path: '/breeding',
          builder: (_, __) => const BreedingListScreen(),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, __) => const Scaffold(body: Text('Form')),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  Scaffold(body: Text('Detail: ${state.pathParameters['id']}')),
            ),
          ],
        ),
      ],
    );
  });

  Widget createSubject({required Stream<List<BreedingPair>> pairsStream}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        currentUserProvider.overrideWith((_) => null),
        userProfileProvider.overrideWith((_) => Stream.value(null)),
        unreadNotificationsProvider(
          'test-user',
        ).overrideWith((_) => Stream.value([])),
        breedingPairsStreamProvider(
          'test-user',
        ).overrideWith((_) => pairsStream),
        allIncubationsStreamProvider(
          'test-user',
        ).overrideWith((_) => Stream.value([])),
        eggsStreamProvider('test-user').overrideWith((_) => Stream.value([])),
        adServiceProvider.overrideWithValue(_MockAdService()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('BreedingListScreen', () {
    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      final controller = StreamController<List<BreedingPair>>();

      await tester.pumpWidget(createSubject(pairsStream: controller.stream));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.close();
    });

    testWidgets('shows empty state when no pairs exist', (tester) async {
      await tester.pumpWidget(createSubject(pairsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(pairsStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows breeding cards when data is available', (tester) async {
      final pairs = [makePair(id: 'p1'), makePair(id: 'p2')];

      await tester.pumpWidget(createSubject(pairsStream: Stream.value(pairs)));

      await tester.pumpAndSettle();

      expect(find.byType(BreedingCard), findsNWidgets(2));
    });

    testWidgets('has search text field', (tester) async {
      await tester.pumpWidget(createSubject(pairsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('has floating action button', (tester) async {
      await tester.pumpWidget(createSubject(pairsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows AppBar with breeding title', (tester) async {
      await tester.pumpWidget(createSubject(pairsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.text(l10n('breeding.title')), findsOneWidget);
    });

    testWidgets('shows no results empty state when search has no matches', (
      tester,
    ) async {
      final pairs = [makePair(id: 'p1', cageNumber: 'Kafes-1')];

      await tester.pumpWidget(createSubject(pairsStream: Stream.value(pairs)));

      await tester.pumpAndSettle();

      // Type a query that won't match anything
      await tester.enterText(find.byType(TextField), 'zzznomatch');
      await tester.pumpAndSettle();

      // Should show "no results" empty state
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('clear button appears when search query is not empty', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(pairsStream: Stream.value([])));

      await tester.pumpAndSettle();

      // Initially no clear button
      expect(find.byType(IconButton), findsAtLeastNWidgets(0));

      await tester.enterText(find.byType(TextField), 'search term');
      await tester.pumpAndSettle();

      // After typing, a clear (X) button should appear in the text field
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });
  });
}
