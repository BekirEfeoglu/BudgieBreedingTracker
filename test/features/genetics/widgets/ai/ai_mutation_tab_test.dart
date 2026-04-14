import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_image_picker_zone.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_mutation_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_result_section.dart';

// ── Fake notifiers for provider overrides ──

class _FakeMutationAnalysis extends MutationImageAiAnalysisNotifier {
  _FakeMutationAnalysis(this._initial);
  final AsyncValue<LocalAiMutationInsight?> _initial;

  @override
  AsyncValue<LocalAiMutationInsight?> build() => _initial;
}

class _FakeConfig extends LocalAiConfigNotifier {
  _FakeConfig(this._initial);
  final AsyncValue<LocalAiConfig> _initial;

  @override
  Future<LocalAiConfig> build() async => _initial.requireValue;
}

// ── Helpers ──

const _testConfig = LocalAiConfig(
  provider: LocalAiProvider.openRouter,
  baseUrl: 'https://openrouter.ai',
  model: 'google/gemma-4-26b-a4b-it:free',
  apiKey: 'test-key',
);

const _sampleResult = LocalAiMutationInsight(
  predictedMutation: 'normal_light_green',
  confidence: LocalAiConfidence.high,
  baseSeries: 'green',
  patternFamily: 'normal',
  bodyColor: 'green',
  wingPattern: 'classic black barring',
  eyeColor: 'black',
  rationale: 'Bright green body with black wing markings.',
  secondaryPossibilities: ['normal_dark_green'],
);

/// Creates a [ProviderContainer] with the desired state and wraps
/// the widget in [UncontrolledProviderScope].
///
/// Using UncontrolledProviderScope lets us pre-set phase state via the
/// container since [_AiPhaseNotifier] is file-private and cannot be subclassed.
Widget _subject({
  AsyncValue<LocalAiMutationInsight?> mutationState =
      const AsyncData(null),
  AiAnalysisPhase phase = AiAnalysisPhase.idle,
  AsyncValue<LocalAiConfig>? configState,
  required void Function(ProviderContainer) onContainer,
}) {
  final container = ProviderContainer(
    overrides: [
      mutationImageAiAnalysisProvider
          .overrideWith(() => _FakeMutationAnalysis(mutationState)),
      localAiConfigProvider.overrideWith(
        () => _FakeConfig(configState ?? const AsyncData(_testConfig)),
      ),
    ],
  );
  onContainer(container);

  // Set phase after container creation
  if (phase != AiAnalysisPhase.idle) {
    container.read(mutationAiPhaseProvider.notifier).set(phase);
  }

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      home: Scaffold(body: AiMutationTab()),
    ),
  );
}

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
    testWidgets('renders image picker zone in idle state', (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.byType(AiImagePickerZone), findsOneWidget);
    });

    testWidgets('renders section title and subtitle', (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      // Without EasyLocalization, .tr() returns the raw key
      expect(find.text('genetics.image_ai_title'), findsOneWidget);
      expect(find.text('genetics.image_ai_subtitle'), findsOneWidget);
    });

    testWidgets('analyze button is disabled when no image is selected',
        (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      final buttons = find.byType(FilledButton);
      expect(buttons, findsAtLeast(1));
      final analyzeButton = tester.widget<FilledButton>(buttons.last);
      expect(analyzeButton.onPressed, isNull,
          reason: 'Analyze button should be disabled without image');
    });

    testWidgets('analyze button shows label text', (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.run_image_ai'), findsOneWidget);
    });

    testWidgets('shows skeleton loader during loading state',
        (tester) async {
      await tester.pumpWidget(_subject(
        mutationState: const AsyncLoading<LocalAiMutationInsight?>(),
        phase: AiAnalysisPhase.analyzing,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.byType(AiInsightSkeleton), findsOneWidget);
    });

    testWidgets('shows error box when analysis fails', (tester) async {
      await tester.pumpWidget(_subject(
        mutationState: AsyncError<LocalAiMutationInsight?>(
          Exception('Connection refused'),
          StackTrace.current,
        ),
        phase: AiAnalysisPhase.error,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.byType(AiErrorBox), findsOneWidget);
    });

    testWidgets('displays result section on successful analysis',
        (tester) async {
      await tester.pumpWidget(_subject(
        mutationState:
            const AsyncData<LocalAiMutationInsight?>(_sampleResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.byType(AiResultSection), findsOneWidget);
    });

    testWidgets('result section shows confidence badge', (tester) async {
      await tester.pumpWidget(_subject(
        mutationState:
            const AsyncData<LocalAiMutationInsight?>(_sampleResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.ai_confidence_high'), findsOneWidget);
    });

    testWidgets('result section shows rationale text', (tester) async {
      await tester.pumpWidget(_subject(
        mutationState:
            const AsyncData<LocalAiMutationInsight?>(_sampleResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(
        find.text('Bright green body with black wing markings.'),
        findsOneWidget,
      );
    });

    testWidgets('progress phases are visible during analysis',
        (tester) async {
      await tester.pumpWidget(_subject(
        mutationState: const AsyncLoading<LocalAiMutationInsight?>(),
        phase: AiAnalysisPhase.analyzing,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.ai_phase_preparing'), findsOneWidget);
      expect(find.text('genetics.ai_phase_analyzing'), findsOneWidget);
    });

    testWidgets('progress phases hidden in idle state', (tester) async {
      await tester.pumpWidget(_subject(
        phase: AiAnalysisPhase.idle,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.ai_phase_preparing'), findsNothing);
      expect(find.text('genetics.ai_phase_analyzing'), findsNothing);
    });

    testWidgets('analyze button is disabled during loading', (tester) async {
      await tester.pumpWidget(_subject(
        mutationState: const AsyncLoading<LocalAiMutationInsight?>(),
        phase: AiAnalysisPhase.analyzing,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      final buttons = find.byType(FilledButton);
      final analyzeButton = tester.widget<FilledButton>(buttons.last);
      expect(analyzeButton.onPressed, isNull,
          reason: 'Analyze button should be disabled while loading');
    });

    testWidgets('no result section displayed in idle state',
        (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.byType(AiResultSection), findsNothing);
      expect(find.byType(AiInsightSkeleton), findsNothing);
      expect(find.byType(AiErrorBox), findsNothing);
    });

    testWidgets('error phase shows error label in progress phases',
        (tester) async {
      await tester.pumpWidget(_subject(
        mutationState: AsyncError<LocalAiMutationInsight?>(
          Exception('timeout'),
          StackTrace.current,
        ),
        phase: AiAnalysisPhase.error,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.ai_phase_error'), findsOneWidget);
    });

    testWidgets('low confidence result shows low badge', (tester) async {
      const lowConfidenceResult = LocalAiMutationInsight(
        predictedMutation: 'unknown',
        confidence: LocalAiConfidence.low,
        baseSeries: 'unknown',
        patternFamily: 'unknown',
        bodyColor: '',
        wingPattern: '',
        eyeColor: '',
        rationale: 'Unable to determine mutation.',
        secondaryPossibilities: [],
      );

      await tester.pumpWidget(_subject(
        mutationState: const AsyncData<LocalAiMutationInsight?>(
            lowConfidenceResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.ai_confidence_low'), findsOneWidget);
    });
  });
}
