@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import '../golden_test_helper.dart';

void main() {
  group('EmptyState multi-locale golden tests', () {
    for (final locale in const ['tr', 'en', 'de']) {
      testWidgets('birds empty state $locale', (tester) async {
        await tester.pumpWidget(
          buildGoldenWidget(
            EmptyState(
              icon: const Icon(Icons.pets),
              title: resolvedL10n('birds.no_birds', locale: locale),
              subtitle: resolvedL10n('birds.no_birds_hint', locale: locale),
              actionLabel: resolvedL10n('birds.add_bird', locale: locale),
              onAction: () {},
            ),
            surfaceSize: const Size(420, 360),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(EmptyState),
          matchesGoldenFile('goldens/empty_state_birds_$locale.png'),
        );
      });
    }
  });
}
