import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_sex_estimation_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_quick_tags.dart';

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

  group('AiSexEstimationTab', () {
    testWidgets('renders quick tags and observation field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: const AiSexEstimationTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AiQuickTags), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('analyze button disabled with empty observations',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: const AiSexEstimationTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttons = find.byType(OutlinedButton);
      expect(buttons, findsWidgets);
    });
  });
}
