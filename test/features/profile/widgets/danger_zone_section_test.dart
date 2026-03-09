import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/danger_zone_section.dart';

class MockAuthActions extends Mock implements AuthActions {}

Future<void> _pump(WidgetTester tester, {MockAuthActions? authActions}) async {
  final mockActions = authActions ?? MockAuthActions();

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: DangerZoneSection()),
      ),
      GoRoute(path: '/login', builder: (_, __) => const SizedBox()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authActionsProvider.overrideWithValue(mockActions)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DangerZoneSection', () {
    testWidgets('shows logout tile', (tester) async {
      await _pump(tester);

      expect(find.text('auth.logout'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows delete account tile', (tester) async {
      await _pump(tester);

      expect(find.text('profile.delete_account'), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog when logout tile tapped', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('auth.logout').first);
      await tester.pump();

      // AlertDialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('confirmation dialog has cancel and logout buttons', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('auth.logout').first);
      await tester.pump();

      expect(find.text('common.cancel'), findsOneWidget);
      // 'auth.logout' appears in dialog title and confirm button
      expect(find.text('auth.logout'), findsAtLeastNWidgets(2));
    });

    testWidgets('cancel dismisses dialog without signing out', (tester) async {
      final mockActions = MockAuthActions();
      await _pump(tester, authActions: mockActions);

      await tester.tap(find.text('auth.logout').first);
      await tester.pump();

      await tester.tap(find.text('common.cancel'));
      await tester.pump();

      // Dialog dismissed
      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => mockActions.signOut());
    });

    testWidgets('renders Card with error border styling', (tester) async {
      await _pump(tester);

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('has Divider between logout and delete', (tester) async {
      await _pump(tester);

      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
