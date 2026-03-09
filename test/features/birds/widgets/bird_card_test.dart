import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_card.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_gender_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_status_badge.dart';

import '../../../helpers/pump_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('BirdCard', () {
    testWidgets('displays bird name', (tester) async {
      final bird = createTestBird(name: 'Mavi');

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      expect(find.text('Mavi'), findsOneWidget);
    });

    testWidgets('displays ring number when present', (tester) async {
      final bird = createTestBird(name: 'Mavi', ringNumber: 'TR-2024-001');

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      expect(find.text('TR-2024-001'), findsOneWidget);
    });

    testWidgets('does not show ring number when null', (tester) async {
      final bird = createTestBird(name: 'Mavi', ringNumber: null);

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.asset == AppIcons.ring,
        ),
        findsNothing,
      );
    });

    testWidgets('displays age when birthDate is set', (tester) async {
      final twoYearsAgo = DateTime(
        DateTime.now().year - 2,
        DateTime.now().month,
        DateTime.now().day,
      );
      final bird = createTestBird(name: 'Mavi', birthDate: twoYearsAgo);

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      expect(find.textContaining('birds.age_short_ym'), findsOneWidget);
    });

    testWidgets('shows status badge', (tester) async {
      final bird = createTestBird(name: 'Mavi', status: BirdStatus.alive);

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      final badge = tester.widget<BirdStatusBadge>(
        find.byType(BirdStatusBadge),
      );
      expect(badge.status, BirdStatus.alive);
    });

    testWidgets('shows species label for non-budgie species', (tester) async {
      final bird = createTestBird(name: 'Sari', species: Species.canary);

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      expect(find.text('birds.canary'), findsOneWidget);
    });

    testWidgets('does not show species label for budgie', (tester) async {
      final bird = createTestBird(name: 'Mavi', species: Species.budgie);

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      expect(find.text('birds.budgie'), findsNothing);
    });

    testWidgets('shows male icon for male bird', (tester) async {
      final bird = createTestBird(name: 'Mavi', gender: BirdGender.male);

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      final icon = tester.widget<BirdGenderIcon>(find.byType(BirdGenderIcon));
      expect(icon.gender, BirdGender.male);
    });

    testWidgets('shows female icon for female bird', (tester) async {
      final bird = createTestBird(name: 'Sari', gender: BirdGender.female);

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      final icon = tester.widget<BirdGenderIcon>(find.byType(BirdGenderIcon));
      expect(icon.gender, BirdGender.female);
    });

    testWidgets('custom onTap callback is invoked', (tester) async {
      var tapped = false;
      final bird = createTestBird(name: 'Mavi');

      await pumpWidget(
        tester,
        Scaffold(
          body: BirdCard(bird: bird, onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(BirdCard));
      expect(tapped, isTrue);
    });

    testWidgets('contains Hero widget with correct tag', (tester) async {
      final bird = createTestBird(id: 'bird-42', name: 'Hero Test');

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'bird_bird-42');
    });

    testWidgets('dead bird shows dead badge', (tester) async {
      final bird = createTestBird(name: 'Eski', status: BirdStatus.dead);

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      final badge = tester.widget<BirdStatusBadge>(
        find.byType(BirdStatusBadge),
      );
      expect(badge.status, BirdStatus.dead);
    });

    testWidgets('sold bird shows sold badge', (tester) async {
      final bird = createTestBird(name: 'Satilan', status: BirdStatus.sold);

      await pumpWidget(tester, Scaffold(body: BirdCard(bird: bird)));

      final badge = tester.widget<BirdStatusBadge>(
        find.byType(BirdStatusBadge),
      );
      expect(badge.status, BirdStatus.sold);
    });
  });
}
