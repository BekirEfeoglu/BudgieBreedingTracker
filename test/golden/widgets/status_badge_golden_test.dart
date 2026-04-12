@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';

import '../golden_test_helper.dart';

void main() {
  group('StatusBadge golden tests', () {
    testWidgets('alive status', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          const StatusBadge(label: 'Canli', color: Colors.green),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatusBadge),
        matchesGoldenFile('goldens/status_badge_alive.png'),
      );
    });

    testWidgets('sold status', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          const StatusBadge(label: 'Satildi', color: Colors.orange),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatusBadge),
        matchesGoldenFile('goldens/status_badge_sold.png'),
      );
    });

    testWidgets('dead status', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(const StatusBadge(label: 'Oldu', color: Colors.red)),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatusBadge),
        matchesGoldenFile('goldens/status_badge_dead.png'),
      );
    });

    testWidgets('with icon', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          const StatusBadge(
            label: 'Canli',
            color: Colors.green,
            icon: Icon(Icons.check_circle),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatusBadge),
        matchesGoldenFile('goldens/status_badge_with_icon.png'),
      );
    });

    testWidgets('dark mode', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          const StatusBadge(label: 'Canli', color: Colors.green),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(StatusBadge),
        matchesGoldenFile('goldens/status_badge_dark.png'),
      );
    });
  });
}
