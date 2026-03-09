import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/account_info_card.dart';

/// Wraps [child] in a GoRouter context (AccountInfoCard uses `context.push`
/// indirectly via clipboard SnackBar, but the card itself only needs
/// a Scaffold — GoRouter is added for nav compatibility).
Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => NoTransitionPage(child: Scaffold(body: child)),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('AccountInfoCard', () {
    const email = 'test@example.com';

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(const AccountInfoCard(profile: null, email: email)),
      );
      await tester.pump();

      expect(find.byType(AccountInfoCard), findsOneWidget);
    });

    testWidgets('shows email label and value', (tester) async {
      await tester.pumpWidget(
        _wrap(const AccountInfoCard(profile: null, email: email)),
      );
      await tester.pump();

      expect(find.text('profile.email'), findsOneWidget);
      expect(find.text(email), findsOneWidget);
    });

    testWidgets('shows copy icon when email is non-empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const AccountInfoCard(profile: null, email: email)),
      );
      await tester.pump();

      // Copy tooltip is on an InkWell — at least one exists
      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });

    testWidgets('shows full name row when profile has fullName', (
      tester,
    ) async {
      const profile = Profile(id: 'u1', email: email, fullName: 'Test User');

      await tester.pumpWidget(
        _wrap(const AccountInfoCard(profile: profile, email: email)),
      );
      await tester.pump();

      expect(find.text('profile.full_name'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('hides full name row when profile fullName is null', (
      tester,
    ) async {
      const profile = Profile(id: 'u1', email: email);

      await tester.pumpWidget(
        _wrap(const AccountInfoCard(profile: profile, email: email)),
      );
      await tester.pump();

      expect(find.text('profile.full_name'), findsNothing);
    });

    testWidgets('shows admin role label', (tester) async {
      const profile = Profile(id: 'u1', email: email, role: 'admin');

      await tester.pumpWidget(
        _wrap(const AccountInfoCard(profile: profile, email: email)),
      );
      await tester.pump();

      expect(find.text('profile.role_label'), findsOneWidget);
      expect(find.text('profile.role_admin'), findsOneWidget);
    });

    testWidgets('shows founder role label', (tester) async {
      const profile = Profile(id: 'u1', email: email, role: 'founder');

      await tester.pumpWidget(
        _wrap(const AccountInfoCard(profile: profile, email: email)),
      );
      await tester.pump();

      expect(find.text('profile.role_founder'), findsOneWidget);
    });

    testWidgets('shows user role label for unknown role', (tester) async {
      const profile = Profile(id: 'u1', email: email, role: 'user');

      await tester.pumpWidget(
        _wrap(const AccountInfoCard(profile: profile, email: email)),
      );
      await tester.pump();

      expect(find.text('profile.role_user'), findsOneWidget);
    });

    testWidgets('hides role row when profile is null', (tester) async {
      await tester.pumpWidget(
        _wrap(const AccountInfoCard(profile: null, email: email)),
      );
      await tester.pump();

      expect(find.text('profile.role_label'), findsNothing);
    });
  });
}
