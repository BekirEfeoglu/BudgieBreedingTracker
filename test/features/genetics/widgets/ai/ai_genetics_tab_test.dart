import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_genetics_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_bird_picker.dart';

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

  group('AiGeneticsTab', () {
    testWidgets('renders bird picker and analyze button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: const AiGeneticsTab())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AiBirdPicker), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('analyze button is disabled without pair', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: const AiGeneticsTab())),
        ),
      );
      await tester.pumpAndSettle();

      final button =
          tester.widget<FilledButton>(find.byType(FilledButton).first);
      expect(button.onPressed, isNull);
    });
  });
}
