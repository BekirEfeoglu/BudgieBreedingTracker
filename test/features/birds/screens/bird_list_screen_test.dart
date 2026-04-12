import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/screens/bird_list_screen.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_card.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('BirdListScreen', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/birds',
        routes: [
          GoRoute(
            path: '/birds',
            builder: (_, __) => const BirdListScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (_, __) => const Scaffold(body: Text('Form')),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => Scaffold(
                  body: Text('Detail: ${state.pathParameters['id']}'),
                ),
              ),
            ],
          ),
        ],
      );
    });

    Widget createSubject({required Stream<List<Bird>> birdsStream}) {
      return ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          currentUserProvider.overrideWith((_) => null),
          userProfileProvider.overrideWith((_) => Stream.value(null)),
          unreadNotificationsProvider(
            'test-user',
          ).overrideWith((_) => Stream.value([])),
          birdsStreamProvider('test-user').overrideWith((_) => birdsStream),
          adServiceProvider.overrideWithValue(MockAdService()),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      // Use a StreamController to control when data arrives
      final controller = StreamController<List<Bird>>();
      addTearDown(controller.close);

      await tester.pumpWidget(createSubject(birdsStream: controller.stream));

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no birds', (tester) async {
      await tester.pumpWidget(createSubject(birdsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows bird cards when data is available', (tester) async {
      final birds = [
        createTestBird(id: 'b1', name: 'Mavi', gender: BirdGender.male),
        createTestBird(id: 'b2', name: 'Sari', gender: BirdGender.female),
      ];

      await tester.pumpWidget(createSubject(birdsStream: Stream.value(birds)));

      await tester.pumpAndSettle();

      expect(find.byType(BirdCard), findsNWidgets(2));
      expect(find.text('Mavi'), findsOneWidget);
      expect(find.text('Sari'), findsOneWidget);
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(birdsStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('has floating action button', (tester) async {
      await tester.pumpWidget(createSubject(birdsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
