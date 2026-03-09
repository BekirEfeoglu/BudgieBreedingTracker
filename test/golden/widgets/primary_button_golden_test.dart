@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';

import '../golden_test_helper.dart';

void main() {
  group('PrimaryButton golden tests', () {
    testWidgets('default state', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        SizedBox(
          width: 320,
          child: PrimaryButton(
            label: 'Kaydet',
            onPressed: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_default.png'),
      );
    });

    testWidgets('with icon', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        SizedBox(
          width: 320,
          child: PrimaryButton(
            label: 'Kus Ekle',
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_with_icon.png'),
      );
    });

    testWidgets('loading state', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        const SizedBox(
          width: 320,
          child: PrimaryButton(
            label: 'Kaydediliyor',
            isLoading: true,
          ),
        ),
      ));
      // pump once — pumpAndSettle times out due to CircularProgressIndicator animation
      await tester.pump();

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_loading.png'),
      );
    });

    testWidgets('disabled state', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        const SizedBox(
          width: 320,
          child: PrimaryButton(
            label: 'Devre Disi',
            onPressed: null,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_disabled.png'),
      );
    });

    testWidgets('dark mode', (tester) async {
      await tester.pumpWidget(buildGoldenWidget(
        SizedBox(
          width: 320,
          child: PrimaryButton(
            label: 'Kaydet',
            onPressed: () {},
          ),
        ),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_dark.png'),
      );
    });
  });
}
