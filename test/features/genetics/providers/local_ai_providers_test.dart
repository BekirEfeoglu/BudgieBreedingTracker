import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_service.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';

class MockLocalAiService extends Mock implements LocalAiService {}

void main() {
  group('AiAnalysisPhase enum', () {
    test('isIdle is true only for idle', () {
      expect(AiAnalysisPhase.idle.isIdle, isTrue);
      expect(AiAnalysisPhase.preparing.isIdle, isFalse);
      expect(AiAnalysisPhase.analyzing.isIdle, isFalse);
      expect(AiAnalysisPhase.complete.isIdle, isFalse);
      expect(AiAnalysisPhase.error.isIdle, isFalse);
    });

    test('isPreparing is true only for preparing', () {
      expect(AiAnalysisPhase.preparing.isPreparing, isTrue);
      expect(AiAnalysisPhase.idle.isPreparing, isFalse);
      expect(AiAnalysisPhase.analyzing.isPreparing, isFalse);
      expect(AiAnalysisPhase.complete.isPreparing, isFalse);
      expect(AiAnalysisPhase.error.isPreparing, isFalse);
    });

    test('isAnalyzing is true only for analyzing', () {
      expect(AiAnalysisPhase.analyzing.isAnalyzing, isTrue);
      expect(AiAnalysisPhase.idle.isAnalyzing, isFalse);
      expect(AiAnalysisPhase.preparing.isAnalyzing, isFalse);
      expect(AiAnalysisPhase.complete.isAnalyzing, isFalse);
      expect(AiAnalysisPhase.error.isAnalyzing, isFalse);
    });

    test('isComplete is true only for complete', () {
      expect(AiAnalysisPhase.complete.isComplete, isTrue);
      expect(AiAnalysisPhase.idle.isComplete, isFalse);
      expect(AiAnalysisPhase.preparing.isComplete, isFalse);
      expect(AiAnalysisPhase.analyzing.isComplete, isFalse);
      expect(AiAnalysisPhase.error.isComplete, isFalse);
    });

    test('isError is true only for error', () {
      expect(AiAnalysisPhase.error.isError, isTrue);
      expect(AiAnalysisPhase.idle.isError, isFalse);
      expect(AiAnalysisPhase.preparing.isError, isFalse);
      expect(AiAnalysisPhase.analyzing.isError, isFalse);
      expect(AiAnalysisPhase.complete.isError, isFalse);
    });

    test('isActive is true for preparing and analyzing only', () {
      expect(AiAnalysisPhase.preparing.isActive, isTrue);
      expect(AiAnalysisPhase.analyzing.isActive, isTrue);
      expect(AiAnalysisPhase.idle.isActive, isFalse);
      expect(AiAnalysisPhase.complete.isActive, isFalse);
      expect(AiAnalysisPhase.error.isActive, isFalse);
    });
  });

  group('Phase providers initial state', () {
    late MockLocalAiService mockService;

    setUp(() {
      mockService = MockLocalAiService();
    });

    ProviderContainer _makeContainer() {
      return ProviderContainer(
        overrides: [
          localAiServiceProvider.overrideWithValue(mockService),
        ],
      );
    }

    test('geneticsAiPhaseProvider starts as idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(geneticsAiPhaseProvider), AiAnalysisPhase.idle);
    });

    test('sexAiPhaseProvider starts as idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(sexAiPhaseProvider), AiAnalysisPhase.idle);
    });

    test('mutationAiPhaseProvider starts as idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(mutationAiPhaseProvider), AiAnalysisPhase.idle);
    });
  });

  group('clear() resets phase to idle', () {
    late MockLocalAiService mockService;

    setUp(() {
      mockService = MockLocalAiService();
    });

    ProviderContainer _makeContainer() {
      return ProviderContainer(
        overrides: [
          localAiServiceProvider.overrideWithValue(mockService),
        ],
      );
    }

    test('GeneticsAiAnalysisNotifier.clear() resets geneticsAiPhaseProvider to idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      // Manually set phase to a non-idle state
      container.read(geneticsAiPhaseProvider.notifier).set(AiAnalysisPhase.complete);
      expect(container.read(geneticsAiPhaseProvider), AiAnalysisPhase.complete);

      container.read(geneticsAiAnalysisProvider.notifier).clear();

      expect(container.read(geneticsAiPhaseProvider), AiAnalysisPhase.idle);
    });

    test('SexAiAnalysisNotifier.clear() resets sexAiPhaseProvider to idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(sexAiPhaseProvider.notifier).set(AiAnalysisPhase.analyzing);
      expect(container.read(sexAiPhaseProvider), AiAnalysisPhase.analyzing);

      container.read(sexAiAnalysisProvider.notifier).clear();

      expect(container.read(sexAiPhaseProvider), AiAnalysisPhase.idle);
    });

    test('MutationImageAiAnalysisNotifier.clear() resets mutationAiPhaseProvider to idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(mutationAiPhaseProvider.notifier).set(AiAnalysisPhase.error);
      expect(container.read(mutationAiPhaseProvider), AiAnalysisPhase.error);

      container.read(mutationImageAiAnalysisProvider.notifier).clear();

      expect(container.read(mutationAiPhaseProvider), AiAnalysisPhase.idle);
    });
  });
}
