import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/limit_approaching_banner.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

void main() {
  const testUserId = 'test-user-id';

  Widget createSubject({required int birdCount, bool isPremium = false}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: Scaffold(body: LimitApproachingBanner(userId: testUserId)),
          ),
        ),
        GoRoute(
          path: '/premium',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: Scaffold(body: Text('Premium'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        isPremiumProvider.overrideWithValue(isPremium),
        birdCountProvider(
          testUserId,
        ).overrideWith((_) => Stream.value(birdCount)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('LimitApproachingBanner', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject(birdCount: 10));
      await tester.pumpAndSettle();

      expect(find.byType(LimitApproachingBanner), findsOneWidget);
    });

    testWidgets('hides banner when bird count is below 66% of limit', (
      tester,
    ) async {
      // 15 * 0.66 = 9.9, so 9 birds should hide the banner
      await tester.pumpWidget(createSubject(birdCount: 9));
      await tester.pumpAndSettle();

      expect(find.text('premium.limit_approaching'), findsNothing);
      expect(find.text('premium.try_free_trial'), findsNothing);
    });

    testWidgets('hides banner when bird count is 0', (tester) async {
      await tester.pumpWidget(createSubject(birdCount: 0));
      await tester.pumpAndSettle();

      expect(find.text('premium.limit_approaching'), findsNothing);
    });

    testWidgets('shows banner when bird count is at 66% of limit', (
      tester,
    ) async {
      // 10/15 = 0.666... >= 0.66
      await tester.pumpWidget(createSubject(birdCount: 10));
      await tester.pumpAndSettle();

      expect(find.text('premium.limit_approaching'), findsOneWidget);
    });

    testWidgets('shows banner when bird count is at 93% of limit', (
      tester,
    ) async {
      // 14/15 = 0.933... >= 0.93
      await tester.pumpWidget(createSubject(birdCount: 14));
      await tester.pumpAndSettle();

      expect(find.text('premium.limit_approaching'), findsOneWidget);
    });

    testWidgets('shows remaining birds info text', (tester) async {
      await tester.pumpWidget(createSubject(birdCount: 12));
      await tester.pumpAndSettle();

      // 15 - 12 = 3 remaining, .tr(args:) returns key in test context
      expect(find.text('premium.limit_approaching_birds'), findsOneWidget);
    });

    testWidgets('shows try free trial button', (tester) async {
      await tester.pumpWidget(createSubject(birdCount: 10));
      await tester.pumpAndSettle();

      expect(find.text('premium.try_free_trial'), findsOneWidget);
    });

    testWidgets('hides banner for premium users', (tester) async {
      await tester.pumpWidget(createSubject(birdCount: 14, isPremium: true));
      await tester.pumpAndSettle();

      expect(find.text('premium.limit_approaching'), findsNothing);
      expect(find.text('premium.try_free_trial'), findsNothing);
    });

    testWidgets('hides banner for premium users even at limit', (tester) async {
      await tester.pumpWidget(createSubject(birdCount: 15, isPremium: true));
      await tester.pumpAndSettle();

      expect(find.text('premium.limit_approaching'), findsNothing);
    });

    testWidgets('tapping try free trial navigates to premium screen', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(birdCount: 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('premium.try_free_trial'));
      await tester.pumpAndSettle();

      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('shows info icon in banner', (tester) async {
      await tester.pumpWidget(createSubject(birdCount: 10));
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Container with decoration when visible', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(birdCount: 12));
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });
}
