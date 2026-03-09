import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_gender_icon.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('BirdGenderIcon', () {
    testWidgets('renders without crashing for male gender', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdGenderIcon(gender: BirdGender.male)),
      );
      await tester.pump();

      expect(find.byType(BirdGenderIcon), findsOneWidget);
    });

    testWidgets('renders without crashing for female gender', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdGenderIcon(gender: BirdGender.female)),
      );
      await tester.pump();

      expect(find.byType(BirdGenderIcon), findsOneWidget);
    });

    testWidgets('renders without crashing for unknown gender', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdGenderIcon(gender: BirdGender.unknown)),
      );
      await tester.pump();

      expect(find.byType(BirdGenderIcon), findsOneWidget);
    });

    testWidgets('uses default size of 20', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdGenderIcon(gender: BirdGender.male)),
      );
      await tester.pump();

      final widget = tester.widget<BirdGenderIcon>(find.byType(BirdGenderIcon));
      expect(widget.size, 20.0);
    });

    testWidgets('uses custom size when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdGenderIcon(gender: BirdGender.male, size: 32)),
      );
      await tester.pump();

      final widget = tester.widget<BirdGenderIcon>(find.byType(BirdGenderIcon));
      expect(widget.size, 32.0);
    });

    testWidgets('renders all gender values without crashing', (tester) async {
      for (final gender in BirdGender.values) {
        await tester.pumpWidget(_wrap(BirdGenderIcon(gender: gender)));
        await tester.pump();

        expect(find.byType(BirdGenderIcon), findsOneWidget);
      }
    });
  });

  group('birdGenderColor', () {
    test('returns different colors for each gender', () {
      final maleColor = birdGenderColor(BirdGender.male);
      final femaleColor = birdGenderColor(BirdGender.female);
      final unknownColor = birdGenderColor(BirdGender.unknown);

      expect(maleColor, isNot(equals(femaleColor)));
      expect(maleColor, isNot(equals(unknownColor)));
      expect(femaleColor, isNot(equals(unknownColor)));
    });
  });
}
