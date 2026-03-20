@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';

import '../golden_test_helper.dart';

void main() {
  group('InfoCard golden tests', () {
    testWidgets('with icon and subtitle', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          const SizedBox(
            width: 360,
            child: InfoCard(
              icon: Icon(Icons.pets),
              title: 'Toplam Kuslar',
              subtitle: '42 kus kayitli',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(InfoCard),
        matchesGoldenFile('goldens/info_card_full.png'),
      );
    });

    testWidgets('title only', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          const SizedBox(width: 360, child: InfoCard(title: 'Basit Bilgi')),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(InfoCard),
        matchesGoldenFile('goldens/info_card_title_only.png'),
      );
    });

    testWidgets('with trailing widget', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          const SizedBox(
            width: 360,
            child: InfoCard(
              icon: Icon(Icons.calendar_today),
              title: 'Son Kontrol',
              subtitle: '2 gun once',
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(InfoCard),
        matchesGoldenFile('goldens/info_card_trailing.png'),
      );
    });

    testWidgets('dark mode', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          const SizedBox(
            width: 360,
            child: InfoCard(
              icon: Icon(Icons.pets),
              title: 'Toplam Kuslar',
              subtitle: '42 kus kayitli',
            ),
          ),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(InfoCard),
        matchesGoldenFile('goldens/info_card_dark.png'),
      );
    });
  });
}
