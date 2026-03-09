import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_header.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_gender_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_status_badge.dart';

import '../../../helpers/pump_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('BirdDetailHeader', () {
    testWidgets('displays bird name', (tester) async {
      final bird = createTestBird(name: 'Mavi');

      await pumpWidgetSimple(tester, BirdDetailHeader(bird: bird));

      expect(find.text('Mavi'), findsOneWidget);
    });

    testWidgets('displays ring number when present', (tester) async {
      final bird = createTestBird(name: 'Mavi', ringNumber: 'TR-2024-001');

      await pumpWidgetSimple(tester, BirdDetailHeader(bird: bird));

      expect(find.textContaining('TR-2024-001'), findsOneWidget);
    });

    testWidgets('does not display ring number label when ringNumber is null', (
      tester,
    ) async {
      final bird = createTestBird(name: 'Mavi', ringNumber: null);

      await pumpWidgetSimple(tester, BirdDetailHeader(bird: bird));

      expect(find.textContaining('birds.ring_number'), findsNothing);
    });

    testWidgets('shows status badge with correct status', (tester) async {
      final bird = createTestBird(name: 'Mavi', status: BirdStatus.alive);

      await pumpWidgetSimple(tester, BirdDetailHeader(bird: bird));

      final badge = tester.widget<BirdStatusBadge>(
        find.byType(BirdStatusBadge),
      );
      expect(badge.status, BirdStatus.alive);
    });

    testWidgets('shows dead status badge for dead bird', (tester) async {
      final bird = createTestBird(name: 'Eski', status: BirdStatus.dead);

      await pumpWidgetSimple(tester, BirdDetailHeader(bird: bird));

      final badge = tester.widget<BirdStatusBadge>(
        find.byType(BirdStatusBadge),
      );
      expect(badge.status, BirdStatus.dead);
    });

    testWidgets('shows gender icon when no photo', (tester) async {
      final bird = createTestBird(
        name: 'Mavi',
        gender: BirdGender.male,
        photoUrl: null,
      );

      await pumpWidgetSimple(tester, BirdDetailHeader(bird: bird));

      expect(find.byType(BirdGenderIcon), findsAtLeastNWidgets(1));
    });

    testWidgets('contains Hero widget with correct tag', (tester) async {
      final bird = createTestBird(id: 'bird-42', name: 'Hero Test');

      await pumpWidgetSimple(tester, BirdDetailHeader(bird: bird));

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'bird_bird-42');
    });

    testWidgets('renders inside Column layout', (tester) async {
      final bird = createTestBird(name: 'Mavi');

      await pumpWidgetSimple(tester, BirdDetailHeader(bird: bird));

      expect(find.byType(Column), findsAtLeastNWidgets(1));
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });
}
