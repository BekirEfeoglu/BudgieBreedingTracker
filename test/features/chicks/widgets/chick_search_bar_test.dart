import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_search_bar.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('ChickSearchBar', () {
    testWidgets('renders text field', (tester) async {
      await pumpLocalizedApp(
        tester,
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: const ChickSearchBar()),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('updates provider on text input after debounce', (tester) async {
      late ProviderContainer container;

      await pumpLocalizedApp(
        tester,
        ProviderScope(
          child: Builder(
            builder: (context) {
              return MaterialApp(
                home: Consumer(
                  builder: (context, ref, _) {
                    container = ProviderScope.containerOf(context);
                    return Scaffold(body: const ChickSearchBar());
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      // Wait for debounce (300ms)
      await tester.pump(const Duration(milliseconds: 350));

      expect(container.read(chickSearchQueryProvider), 'test');
    });

    testWidgets('shows clear button when query is not empty', (tester) async {
      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            chickSearchQueryProvider.overrideWith(() {
              final notifier = ChickSearchQueryNotifier();
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(body: const ChickSearchBar()),
          ),
        ),
      );

      // Type text
      await tester.enterText(find.byType(TextField), 'search');
      await tester.pump(const Duration(milliseconds: 350));

      // Clear button should appear
      expect(find.byType(IconButton), findsOneWidget);
    });
  });
}
