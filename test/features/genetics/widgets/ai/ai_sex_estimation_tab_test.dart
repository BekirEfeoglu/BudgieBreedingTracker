import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_quick_tags.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_result_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_sex_estimation_tab.dart';

// ── Fake notifiers for provider overrides ──

class _FakeSexAnalysis extends SexAiAnalysisNotifier {
  _FakeSexAnalysis(this._initial);
  final AsyncValue<LocalAiSexInsight?> _initial;

  @override
  AsyncValue<LocalAiSexInsight?> build() => _initial;
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

const _maleResult = LocalAiSexInsight(
  predictedSex: LocalAiSexPrediction.male,
  confidence: LocalAiConfidence.high,
  rationale: 'Blue cere indicates adult male.',
  indicators: ['Blue cere coloring', 'Active singing behavior'],
  nextChecks: ['DNA test for confirmation'],
);

const _uncertainResult = LocalAiSexInsight(
  predictedSex: LocalAiSexPrediction.uncertain,
  confidence: LocalAiConfidence.low,
  rationale: 'Juvenile bird with pale cere.',
  indicators: ['Pale pink/blue cere'],
  nextChecks: ['Wait for maturity', 'DNA test'],
);

/// Creates a [ProviderContainer] with the desired state and wraps
/// the widget in [UncontrolledProviderScope].
///
/// Using UncontrolledProviderScope lets us pre-set phase state via the
/// container since [_AiPhaseNotifier] is file-private and cannot be subclassed.
Widget _subject({
  AsyncValue<LocalAiSexInsight?> sexState = const AsyncData(null),
  AiAnalysisPhase phase = AiAnalysisPhase.idle,
  AsyncValue<LocalAiConfig>? configState,
  required void Function(ProviderContainer) onContainer,
}) {
  final container = ProviderContainer(
    overrides: [
      sexAiAnalysisProvider
          .overrideWith(() => _FakeSexAnalysis(sexState)),
      localAiConfigProvider.overrideWith(
        () => _FakeConfig(configState ?? const AsyncData(_testConfig)),
      ),
    ],
  );
  onContainer(container);

  // Set phase after container creation
  if (phase != AiAnalysisPhase.idle) {
    container.read(sexAiPhaseProvider.notifier).set(phase);
  }

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      home: Scaffold(body: AiSexEstimationTab()),
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

  group('AiSexEstimationTab', () {
    testWidgets('renders quick tags and observation field in idle state',
        (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.byType(AiQuickTags), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders section title and subtitle', (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.sex_ai_title'), findsOneWidget);
      expect(find.text('genetics.sex_ai_subtitle'), findsOneWidget);
    });

    testWidgets('analyze button has correct label', (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.run_sex_ai'), findsOneWidget);
    });

    testWidgets(
        'analyze button is enabled in idle state (validation on tap)',
        (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      // The analyze OutlinedButton is the last one (first is gallery in picker).
      // It is enabled even with empty text because validation is done inside
      // the callback, not via the onPressed null check.
      final analyzeBtn = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton).last,
      );
      expect(analyzeBtn.onPressed, isNotNull);
    });

    testWidgets('analyze button is disabled during loading state',
        (tester) async {
      await tester.pumpWidget(_subject(
        sexState: const AsyncLoading<LocalAiSexInsight?>(),
        phase: AiAnalysisPhase.analyzing,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      // The analyze button is the last OutlinedButton (first is gallery picker)
      final analyzeBtn = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton).last,
      );
      expect(analyzeBtn.onPressed, isNull,
          reason: 'Analyze button should be disabled while loading');
    });

    testWidgets('shows skeleton loader during loading state',
        (tester) async {
      await tester.pumpWidget(_subject(
        sexState: const AsyncLoading<LocalAiSexInsight?>(),
        phase: AiAnalysisPhase.analyzing,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.byType(AiInsightSkeleton), findsOneWidget);
    });

    testWidgets('shows error box when analysis fails', (tester) async {
      await tester.pumpWidget(_subject(
        sexState: AsyncError<LocalAiSexInsight?>(
          Exception('Network error'),
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
        sexState: const AsyncData<LocalAiSexInsight?>(_maleResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.byType(AiResultSection), findsOneWidget);
    });

    testWidgets('result section shows rationale text', (tester) async {
      await tester.pumpWidget(_subject(
        sexState: const AsyncData<LocalAiSexInsight?>(_maleResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(
        find.text('Blue cere indicates adult male.'),
        findsOneWidget,
      );
    });

    testWidgets('result section shows indicator bullets', (tester) async {
      await tester.pumpWidget(_subject(
        sexState: const AsyncData<LocalAiSexInsight?>(_maleResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('Blue cere coloring'), findsOneWidget);
      expect(find.text('Active singing behavior'), findsOneWidget);
    });

    testWidgets('result section shows next checks', (tester) async {
      await tester.pumpWidget(_subject(
        sexState: const AsyncData<LocalAiSexInsight?>(_maleResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('DNA test for confirmation'), findsOneWidget);
    });

    testWidgets('high confidence result shows high badge', (tester) async {
      await tester.pumpWidget(_subject(
        sexState: const AsyncData<LocalAiSexInsight?>(_maleResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.ai_confidence_high'), findsOneWidget);
    });

    testWidgets('low confidence uncertain result shows low badge',
        (tester) async {
      await tester.pumpWidget(_subject(
        sexState:
            const AsyncData<LocalAiSexInsight?>(_uncertainResult),
        phase: AiAnalysisPhase.complete,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.ai_confidence_low'), findsOneWidget);
    });

    testWidgets('progress phases visible during analysis', (tester) async {
      await tester.pumpWidget(_subject(
        sexState: const AsyncLoading<LocalAiSexInsight?>(),
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
    });

    testWidgets('error phase shows error label in progress phases',
        (tester) async {
      await tester.pumpWidget(_subject(
        sexState: AsyncError<LocalAiSexInsight?>(
          Exception('Server error'),
          StackTrace.current,
        ),
        phase: AiAnalysisPhase.error,
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(find.text('genetics.ai_phase_error'), findsOneWidget);
    });

    testWidgets('tapping filter chip toggles tag selection',
        (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      // Tap the first filter chip
      final chips = find.byType(FilterChip);
      expect(chips, findsAtLeast(1));
      await tester.tap(chips.first);
      await tester.pump();

      // The chip should now be selected
      final chip = tester.widget<FilterChip>(chips.first);
      expect(chip.selected, isTrue);
    });

    testWidgets('typing in observation field updates text',
        (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Blue cere observed');
      await tester.pump();

      expect(find.text('Blue cere observed'), findsOneWidget);
    });

    testWidgets(
        'tapping analyze with empty observations and no tags shows validation error',
        (tester) async {
      // Use a tall surface so all widgets including the analyze button
      // are within the render bounds and hittable.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      // Wait for async config provider to resolve so button is enabled
      await tester.pumpAndSettle();

      // The analyze button is the last OutlinedButton (first is gallery picker)
      final analyzeBtn = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton).last,
      );
      expect(analyzeBtn.onPressed, isNotNull,
          reason: 'Button should be enabled after config resolves');

      // Tap the analyze button with empty observations and no tags
      await tester.tap(find.byType(OutlinedButton).last);
      await tester.pump();

      // Validation logic sets _showObservationError=true which renders the text
      expect(
        find.text('genetics.sex_observations_required'),
        findsOneWidget,
      );
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

    testWidgets('bird selector is rendered with optional label',
        (tester) async {
      await tester.pumpWidget(_subject(
        onContainer: (c) => addTearDown(c.dispose),
      ));
      await tester.pump();

      expect(
        find.text('genetics.ai_select_bird_optional'),
        findsOneWidget,
      );
    });
  });
}
