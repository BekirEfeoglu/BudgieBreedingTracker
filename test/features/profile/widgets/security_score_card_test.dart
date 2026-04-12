import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/security_score_card.dart';
import '../../../helpers/test_localization.dart';

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
  Widget buildSubject({
    required SecurityScore securityScore,
    ValueChanged<SecurityFactor>? onFactorTap,
  }) {
    return SingleChildScrollView(
      child: SecurityScoreCard(
        securityScore: securityScore,
        onFactorTap: onFactorTap,
      ),
    );
  }

  group('SecurityScoreCard', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject(securityScore: _lowScore),
      );

      expect(find.byType(SecurityScoreCard), findsOneWidget);
    });

    testWidgets('shows security_score label', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject(securityScore: _lowScore),
      );

      expect(find.text(resolvedL10n('profile.security_score')), findsOneWidget);
    });

    testWidgets('shows low level label for score=25', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject(securityScore: _lowScore),
      );

      expect(find.text(resolvedL10n('profile.security_low')), findsOneWidget);
    });

    testWidgets('shows excellent label for score=95', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject(securityScore: _highScore),
      );

      expect(
        find.text(resolvedL10n('profile.security_excellent')),
        findsOneWidget,
      );
    });

    testWidgets('shows high label for score=65', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject(securityScore: _mediumScore),
      );

      expect(find.text(resolvedL10n('profile.security_high')), findsOneWidget);
    });

    testWidgets('renders factor rows', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject(securityScore: _lowScore),
      );

      expect(
        find.text(resolvedL10n('profile.security_factor_password')),
        findsOneWidget,
      );
      expect(
        find.text(resolvedL10n('profile.security_factor_2fa')),
        findsOneWidget,
      );
    });

    testWidgets('completed factor has strikethrough decoration', (
      tester,
    ) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject(securityScore: _lowScore),
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final completedText = textWidgets.firstWhere(
        (t) => t.data == resolvedL10n('profile.security_factor_password'),
        orElse: () => const Text(''),
      );
      expect(completedText.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('calls onFactorTap for incomplete factor', (tester) async {
      SecurityFactor? tappedFactor;

      await pumpTranslatedWidget(
        tester,
        buildSubject(
          securityScore: _lowScore,
          onFactorTap: (f) => tappedFactor = f,
        ),
      );

      await tester.tap(find.text(resolvedL10n('profile.security_factor_2fa')));
      expect(tappedFactor, _lowScore.factors[1]);
      expect(tappedFactor?.points, 30);
    });

    testWidgets('does NOT call onFactorTap for completed factor', (
      tester,
    ) async {
      SecurityFactor? tappedFactor;

      await pumpTranslatedWidget(
        tester,
        buildSubject(
          securityScore: _lowScore,
          onFactorTap: (f) => tappedFactor = f,
        ),
      );

      await tester.tap(
        find.text(resolvedL10n('profile.security_factor_password')),
      );
      expect(tappedFactor, isNull);
    });
  });
}
