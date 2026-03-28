import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/security_score_card.dart';

const _lowScore = SecurityScore(
  score: 25,
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

const _highScore = SecurityScore(
  score: 95,
  factors: [
    SecurityFactor(
      labelKey: 'profile.security_factor_password',
      isCompleted: true,
      points: 25,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_email',
      isCompleted: true,
      points: 20,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_profile',
      isCompleted: true,
      points: 15,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_premium',
      isCompleted: true,
      points: 10,
    ),
  ],
);

const _mediumScore = SecurityScore(
  score: 65,
  factors: [
    SecurityFactor(
      labelKey: 'profile.security_factor_password',
      isCompleted: true,
      points: 25,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_email',
      isCompleted: true,
      points: 20,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_2fa',
      isCompleted: false,
      points: 30,
    ),
  ],
);

void main() {
  group('SecurityScoreCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityScoreCard(securityScore: _lowScore),
            ),
          ),
        ),
      );

      expect(find.byType(SecurityScoreCard), findsOneWidget);
    });

    testWidgets('shows security_score label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityScoreCard(securityScore: _lowScore),
            ),
          ),
        ),
      );

      expect(find.text('profile.security_score'), findsOneWidget);
    });

    testWidgets('shows low level label for score=25', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityScoreCard(securityScore: _lowScore),
            ),
          ),
        ),
      );

      // score 25 < 40 → 'profile.security_low'
      expect(find.text('profile.security_low'), findsOneWidget);
    });

    testWidgets('shows excellent label for score=95', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityScoreCard(securityScore: _highScore),
            ),
          ),
        ),
      );

      // score 95 >= 80 → 'profile.security_excellent'
      expect(find.text('profile.security_excellent'), findsOneWidget);
    });

    testWidgets('shows high label for score=65', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityScoreCard(securityScore: _mediumScore),
            ),
          ),
        ),
      );

      // score 65 >= 60 → 'profile.security_high'
      expect(find.text('profile.security_high'), findsOneWidget);
    });

    testWidgets('renders factor rows', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityScoreCard(securityScore: _lowScore),
            ),
          ),
        ),
      );

      expect(find.text('profile.security_factor_password'), findsOneWidget);
      expect(find.text('profile.security_factor_2fa'), findsOneWidget);
    });

    testWidgets('completed factor has strikethrough decoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityScoreCard(securityScore: _lowScore),
            ),
          ),
        ),
      );

      // Completed factor text should have lineThrough decoration
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final completedText = textWidgets.firstWhere(
        (t) => t.data == 'profile.security_factor_password',
        orElse: () => const Text(''),
      );
      expect(completedText.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('calls onFactorTap for incomplete factor', (tester) async {
      SecurityFactor? tappedFactor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityScoreCard(
                securityScore: _lowScore,
                onFactorTap: (f) => tappedFactor = f,
              ),
            ),
          ),
        ),
      );

      // 'profile.security_factor_2fa' is incomplete → tappable
      await tester.tap(find.text('profile.security_factor_2fa'));
      expect(tappedFactor, _lowScore.factors[1]);
      expect(tappedFactor?.points, 30);
    });

    testWidgets('does NOT call onFactorTap for completed factor', (
      tester,
    ) async {
      SecurityFactor? tappedFactor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityScoreCard(
                securityScore: _lowScore,
                onFactorTap: (f) => tappedFactor = f,
              ),
            ),
          ),
        ),
      );

      // 'profile.security_factor_password' is completed → onTap == null
      await tester.tap(find.text('profile.security_factor_password'));
      expect(tappedFactor, isNull);
    });
  });
}
