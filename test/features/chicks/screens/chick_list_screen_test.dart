import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/screens/chick_list_screen.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_card.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

/// Stub [AdService] that never calls Google Mobile Ads.
class _FakeAdService extends AdService {
  @override
  Future<void> loadAd() async {}

  @override
  Future<void> showInterstitialAd({required VoidCallback onAdClosed}) async {
    onAdClosed();
  }
}

Chick _createTestChick({
  required String id,
  String name = 'Baby',
  String userId = 'test-user',
}) {
  return Chick(
    id: id,
    userId: userId,
    gender: BirdGender.unknown,
    healthStatus: ChickHealthStatus.healthy,
    name: name,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('ChickListScreen', () {
    late GoRouter router;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      router = GoRouter(
        initialLocation: '/chicks',
        routes: [
          GoRoute(
            path: '/more',
            builder: (_, __) => const Scaffold(body: Text('More')),
          ),
          GoRoute(
            path: '/chicks',
            builder: (_, __) => const ChickListScreen(),
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

    Widget createSubject({required Stream<List<Chick>> chicksStream}) {
      return ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          currentUserProvider.overrideWith((_) => null),
          userProfileProvider.overrideWith((_) => Stream.value(null)),
          unreadNotificationsProvider(
            'test-user',
          ).overrideWith((_) => Stream.value([])),
          chicksStreamProvider('test-user').overrideWith((_) => chicksStream),
          chickParentsByEggProvider('test-user').overrideWith((_) async => {}),
          adServiceProvider.overrideWithValue(_FakeAdService()),
          isPremiumProvider.overrideWithValue(true),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      final controller = StreamController<List<Chick>>();

      await tester.pumpWidget(createSubject(chicksStream: controller.stream));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.close();
    });

    testWidgets('shows empty state when no chicks', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows chick cards when data is available', (tester) async {
      final chicks = [
        _createTestChick(id: 'c1', name: 'Baby'),
        _createTestChick(id: 'c2', name: 'Tweety'),
      ];

      await tester.pumpWidget(
        createSubject(chicksStream: Stream.value(chicks)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ChickCard), findsNWidgets(2));
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(chicksStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('has floating action button', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows search text field', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('shows sort icon button', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(
        find.byIcon(LucideIcons.arrowUpDown),
        findsOneWidget,
      );
    });

    testWidgets('shows back button and navigates to more', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();

      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('shows chick filter bar', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      // ChickFilterBar is always rendered in the screen column
      expect(find.byType(ChickFilterBar), findsOneWidget);
    });

    testWidgets('shows no results state when search yields nothing', (
      tester,
    ) async {
      final chick = _createTestChick(id: 'c1', name: 'Lemon');

      await tester.pumpWidget(
        createSubject(chicksStream: Stream.value([chick])),
      );
      await tester.pumpAndSettle();

      // Type a query that matches nothing
      await tester.enterText(find.byType(TextField).first, 'ZZZNOTFOUND');
      await tester.pumpAndSettle();

      // Should show no results empty state
      expect(find.byType(EmptyState), findsAtLeastNWidgets(1));
    });
  });
}
