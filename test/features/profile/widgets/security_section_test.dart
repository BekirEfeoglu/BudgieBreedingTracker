import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/security_score_card.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/security_section.dart';

const _mockScore = SecurityScore(
  score: 45,
  factors: [
    SecurityFactor(
      labelKey: 'profile.security_factor_password',
      isCompleted: true,
      points: 25,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_2fa',
      isCompleted: false,
      points: 30,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onChangePassword,
  SecurityScore score = _mockScore,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: SecuritySection(onChangePassword: onChangePassword ?? () {}),
        ),
      ),
      GoRoute(path: '/2fa-setup', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/profile', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/premium', builder: (_, __) => const SizedBox()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        securityScoreProvider.overrideWith((ref, id) => score),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SecuritySection', () {
    testWidgets('renders SecurityScoreCard', (tester) async {
      await _pump(tester);

      expect(find.byType(SecurityScoreCard), findsOneWidget);
    });

    testWidgets('shows change_password tile label', (tester) async {
      await _pump(tester);

      expect(find.text('profile.change_password'), findsOneWidget);
    });

    testWidgets('shows two_factor_auth tile label', (tester) async {
      await _pump(tester);

      expect(find.text('profile.two_factor_auth'), findsOneWidget);
    });

    testWidgets('calls onChangePassword when password tile tapped', (
      tester,
    ) async {
      var called = false;
      await _pump(tester, onChangePassword: () => called = true);

      await tester.tap(find.text('profile.change_password'));
      expect(called, isTrue);
    });

    testWidgets('renders with high score', (tester) async {
      const highScore = SecurityScore(
        score: 95,
        factors: [
          SecurityFactor(
            labelKey: 'profile.security_factor_password',
            isCompleted: true,
            points: 25,
          ),
        ],
      );

      await _pump(tester, score: highScore);
      expect(find.byType(SecurityScoreCard), findsOneWidget);
    });

    testWidgets('shows score level label from SecurityScoreCard', (
      tester,
    ) async {
      await _pump(tester);

      // score 45 >= 40 and < 60 → 'profile.security_medium'
      expect(find.text('profile.security_medium'), findsOneWidget);
    });
  });
}
