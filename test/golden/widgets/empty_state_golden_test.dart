@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';

import '../golden_test_helper.dart';

void main() {
  group('EmptyState golden tests', () {
    testWidgets('with action button', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        EmptyState(
          icon: const Icon(Icons.pets),
          title: 'Henuz kus eklenmemis',
          subtitle: 'Ilk kusunuzu ekleyin',
          actionLabel: 'Kus Ekle',
          onAction: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(EmptyState),
        matchesGoldenFile('goldens/empty_state_with_action.png'),
      );
    });

    testWidgets('without action (search results)', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        const EmptyState(
          icon: Icon(Icons.search_off),
          title: 'Sonuc bulunamadi',
          subtitle: 'Arama kriterlerini degistirin',
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(EmptyState),
        matchesGoldenFile('goldens/empty_state_no_action.png'),
      );
    });

    testWidgets('title only (minimal)', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        const EmptyState(
          icon: Icon(Icons.inbox),
          title: 'Bos',
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(EmptyState),
        matchesGoldenFile('goldens/empty_state_minimal.png'),
      );
    });

    testWidgets('dark mode', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        EmptyState(
          icon: const Icon(Icons.pets),
          title: 'Henuz kus eklenmemis',
          subtitle: 'Ilk kusunuzu ekleyin',
          actionLabel: 'Kus Ekle',
          onAction: () {},
        ),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(EmptyState),
        matchesGoldenFile('goldens/empty_state_dark.png'),
      );
    });
  });
}
