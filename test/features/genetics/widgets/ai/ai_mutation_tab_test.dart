import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_mutation_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_image_picker_zone.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyLocalAiProvider: 'openRouter',
      AppPreferences.keyLocalAiBaseUrl: 'https://openrouter.ai',
      AppPreferences.keyLocalAiModel: 'google/gemma-4-26b-a4b-it:free',
      AppPreferences.keyLocalAiApiKey: 'test-key',
    });
  });

  group('AiMutationTab', () {
    testWidgets('renders image picker zone', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: const AiMutationTab())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AiImagePickerZone), findsOneWidget);
    });

    testWidgets('analyze button disabled without image', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: const AiMutationTab())),
        ),
      );
      await tester.pumpAndSettle();

      // The last FilledButton is the analyze button (first is camera in picker)
      final buttons = find.byType(FilledButton);
      expect(buttons, findsAtLeast(2));
      final analyzeButton = tester.widget<FilledButton>(buttons.last);
      expect(analyzeButton.onPressed, isNull);
    });
  });
}
