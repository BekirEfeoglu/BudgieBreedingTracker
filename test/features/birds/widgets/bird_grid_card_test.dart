import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_gender_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_grid_card.dart';

import '../../../helpers/pump_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('BirdGridCard', () {
    testWidgets('displays bird name', (tester) async {
      final bird = createTestBird(name: 'Mavi');

      await pumpWidget(tester, Scaffold(body: BirdGridCard(bird: bird)));

      expect(find.text('Mavi'), findsOneWidget);
    });

    testWidgets('shows gender icon fallback when no photo is set', (
      tester,
    ) async {
      final bird = createTestBird(
        name: 'Mavi',
        gender: BirdGender.male,
        photoUrl: null,
      );

      await pumpWidget(tester, Scaffold(body: BirdGridCard(bird: bird)));

      expect(find.byType(BirdGenderIcon), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('shows a CachedNetworkImage with a placeholder when a '
        'photo is set', (tester) async {
      final bird = createTestBird(
        name: 'Mavi',
        photoUrl: 'https://example.com/bird.jpg',
      );

      await pumpWidget(tester, Scaffold(body: BirdGridCard(bird: bird)));

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(
        image.placeholder,
        isNotNull,
        reason:
            'a missing placeholder leaves a blank cell during fast scroll '
            '— see assets-images.md § Network Image',
      );
    });
  });
}
