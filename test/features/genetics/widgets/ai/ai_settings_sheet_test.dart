import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_service.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_settings_sheet.dart';

class MockLocalAiService extends Mock implements LocalAiService {}

Widget _buildSheet(MockLocalAiService mockService) {
  return ProviderScope(
    overrides: [
      localAiServiceProvider.overrideWithValue(mockService),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AiSettingsSheet(),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockLocalAiService mockService;

  setUp(() {
    mockService = MockLocalAiService();
    when(() => mockService.dispose()).thenReturn(null);
  });

  group('AiSettingsSheet', () {
    testWidgets('renders settings title', (tester) async {
      await tester.pumpWidget(_buildSheet(mockService));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AiSettingsSheet), findsOneWidget);
      expect(find.byIcon(LucideIcons.settings2), findsWidgets);
    });

    testWidgets('shows provider segmented button', (tester) async {
      await tester.pumpWidget(_buildSheet(mockService));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<LocalAiProvider>), findsOneWidget);
      expect(find.text('Ollama'), findsOneWidget);
      expect(find.text('OpenRouter'), findsOneWidget);
    });

    testWidgets('shows text fields and close button', (tester) async {
      await tester.pumpWidget(_buildSheet(mockService));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('shows drag handle', (tester) async {
      await tester.pumpWidget(_buildSheet(mockService));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });
  });
}
