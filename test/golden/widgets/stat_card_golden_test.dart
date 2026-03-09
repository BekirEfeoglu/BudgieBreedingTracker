@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/stat_card.dart';

import '../golden_test_helper.dart';

void main() {
  group('StatCard golden tests', () {
    testWidgets('vertical layout with icon', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        const SizedBox(
          width: 160,
          height: 140,
          child: StatCard(
            label: 'Toplam Kus',
            value: '42',
            icon: Icon(Icons.pets),
            color: Colors.blue,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatCard),
        matchesGoldenFile('goldens/stat_card_vertical.png'),
      );
    });

    testWidgets('horizontal layout with icon', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        const SizedBox(
          width: 280,
          height: 100,
          child: StatCard(
            label: 'Aktif Cift',
            value: '8',
            icon: Icon(Icons.favorite),
            color: Colors.pink,
            isHorizontal: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatCard),
        matchesGoldenFile('goldens/stat_card_horizontal.png'),
      );
    });

    testWidgets('with trend indicator', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        const SizedBox(
          width: 160,
          height: 160,
          child: StatCard(
            label: 'Basari Orani',
            value: '75%',
            icon: Icon(Icons.trending_up),
            color: Colors.green,
            trendPercent: 12,
            trendUp: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatCard),
        matchesGoldenFile('goldens/stat_card_trend_up.png'),
      );
    });

    testWidgets('without icon', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        const SizedBox(
          width: 160,
          height: 140,
          child: StatCard(
            label: 'Yumurta',
            value: '15',
            color: Colors.orange,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatCard),
        matchesGoldenFile('goldens/stat_card_no_icon.png'),
      );
    });

    testWidgets('dark mode', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        const SizedBox(
          width: 160,
          height: 140,
          child: StatCard(
            label: 'Toplam Kus',
            value: '42',
            icon: Icon(Icons.pets),
            color: Colors.blue,
          ),
        ),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatCard),
        matchesGoldenFile('goldens/stat_card_dark.png'),
      );
    });
  });
}
