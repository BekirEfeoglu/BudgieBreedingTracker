import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_service.dart';

enum AiAnalysisPhase {
  idle,
  preparing,
  analyzing,
  complete,
  error;

  bool get isIdle => this == idle;
  bool get isPreparing => this == preparing;
  bool get isAnalyzing => this == analyzing;
  bool get isComplete => this == complete;
  bool get isError => this == error;
  bool get isActive => this == preparing || this == analyzing;
}

final localAiServiceProvider = Provider<LocalAiService>((ref) {
  final service = LocalAiService();
  ref.onDispose(service.dispose);
  return service;
});

final localAiConfigProvider =
    AsyncNotifierProvider<LocalAiConfigNotifier, LocalAiConfig>(
      LocalAiConfigNotifier.new,
    );

final localAiModelListProvider =
    NotifierProvider<LocalAiModelListNotifier, AsyncValue<List<String>>>(
      LocalAiModelListNotifier.new,
    );

class LocalAiConfigNotifier extends AsyncNotifier<LocalAiConfig> {
  static const _secureKeyApiKey = 'local_ai_api_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  Future<LocalAiConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
    final ap = AppPreferences(prefs);
    final provider = LocalAiProvider.fromRaw(
      ap.getString(AppPreferences.keyLocalAiProvider),
    );
    final providerDefaults = provider == LocalAiProvider.openRouter
        ? LocalAiConfig.openRouterDefaults
        : LocalAiConfig.defaults;
    final apiKey = await _secureStorage.read(key: _secureKeyApiKey) ?? '';
    return LocalAiConfig(
      provider: provider,
      baseUrl:
          ap.getString(AppPreferences.keyLocalAiBaseUrl) ??
          providerDefaults.baseUrl,
      model:
          ap.getString(AppPreferences.keyLocalAiModel) ??
          providerDefaults.model,
      apiKey: apiKey,
    );
  }

  Future<void> save({
    required LocalAiProvider provider,
    required String baseUrl,
    required String model,
    required String apiKey,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      final ap = AppPreferences(prefs);
      final raw = LocalAiConfig(
        provider: provider,
        baseUrl: baseUrl,
        model: model,
        apiKey: apiKey.trim(),
      );
      final next = LocalAiConfig(
        provider: provider,
        baseUrl: raw.normalizedBaseUrl,
        model: raw.normalizedModel,
        apiKey: raw.apiKey,
      );
      await ap.setString(AppPreferences.keyLocalAiProvider, next.provider.key);
      await ap.setString(AppPreferences.keyLocalAiBaseUrl, next.baseUrl);
      await ap.setString(AppPreferences.keyLocalAiModel, next.model);
      await _secureStorage.write(key: _secureKeyApiKey, value: next.apiKey);
      // Clean up legacy plaintext key from SharedPreferences
      await ap.remove(AppPreferences.keyLocalAiApiKey);
      return next;
    });
  }
}

class LocalAiModelListNotifier extends Notifier<AsyncValue<List<String>>> {
  String? _lastBaseUrl;

  @override
  AsyncValue<List<String>> build() => const AsyncData([]);

  Future<void> fetch({
    required String baseUrl,
    String? selectedModel,
    LocalAiProvider provider = LocalAiProvider.ollama,
    String apiKey = '',
    bool force = false,
  }) async {
    final normalizedConfig = LocalAiConfig(
      provider: provider,
      baseUrl: baseUrl,
      model: selectedModel ?? LocalAiConfig.defaults.model,
      apiKey: apiKey,
    );

    if (!force &&
        _lastBaseUrl == normalizedConfig.normalizedBaseUrl &&
        state is AsyncData<List<String>>) {
      final current = state.asData?.value ?? const <String>[];
      if (current.isNotEmpty) return;
    }

    _lastBaseUrl = normalizedConfig.normalizedBaseUrl;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(localAiServiceProvider)
          .listModels(config: normalizedConfig);
    });
  }

  void clear() {
    _lastBaseUrl = null;
    state = const AsyncData([]);
  }
}

final geneticsAiAnalysisProvider =
    NotifierProvider<
      GeneticsAiAnalysisNotifier,
      AsyncValue<LocalAiGeneticsInsight?>
    >(GeneticsAiAnalysisNotifier.new);

class GeneticsAiAnalysisNotifier
    extends Notifier<AsyncValue<LocalAiGeneticsInsight?>> {
  int _requestId = 0;

  @override
  AsyncValue<LocalAiGeneticsInsight?> build() => const AsyncData(null);

  Future<void> analyze({
    required LocalAiConfig config,
    required ParentGenotype father,
    required ParentGenotype mother,
    required List<OffspringResult> calculatorResults,
    String? fatherName,
    String? motherName,
  }) async {
    final requestId = ++_requestId;
    state = const AsyncLoading();
    ref.read(geneticsAiPhaseProvider.notifier).set(AiAnalysisPhase.preparing);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (requestId != _requestId) return;
    ref.read(geneticsAiPhaseProvider.notifier).set(AiAnalysisPhase.analyzing);
    final nextState = await AsyncValue.guard(() {
      return ref
          .read(localAiServiceProvider)
          .analyzeGenetics(
            config: config,
            father: father,
            mother: mother,
            fatherName: fatherName,
            motherName: motherName,
            calculatorResults: calculatorResults,
          );
    });
    if (requestId == _requestId) {
      state = nextState;
      ref.read(geneticsAiPhaseProvider.notifier).set(
            nextState.hasError ? AiAnalysisPhase.error : AiAnalysisPhase.complete,
          );
    }
  }

  void clear() {
    _requestId++;
    state = const AsyncData(null);
    ref.read(geneticsAiPhaseProvider.notifier).set(AiAnalysisPhase.idle);
  }
}

final sexAiAnalysisProvider =
    NotifierProvider<SexAiAnalysisNotifier, AsyncValue<LocalAiSexInsight?>>(
      SexAiAnalysisNotifier.new,
    );

class SexAiAnalysisNotifier extends Notifier<AsyncValue<LocalAiSexInsight?>> {
  int _requestId = 0;

  @override
  AsyncValue<LocalAiSexInsight?> build() => const AsyncData(null);

  Future<void> analyze({
    required LocalAiConfig config,
    required String observations,
    String? imagePath,
  }) async {
    final requestId = ++_requestId;
    state = const AsyncLoading();
    ref.read(sexAiPhaseProvider.notifier).set(AiAnalysisPhase.preparing);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (requestId != _requestId) return;
    ref.read(sexAiPhaseProvider.notifier).set(AiAnalysisPhase.analyzing);
    final nextState = await AsyncValue.guard(() {
      return ref.read(localAiServiceProvider).analyzeSex(
            config: config,
            observations: observations,
            imagePath: imagePath,
          );
    });
    if (requestId == _requestId) {
      state = nextState;
      ref.read(sexAiPhaseProvider.notifier).set(
            nextState.hasError ? AiAnalysisPhase.error : AiAnalysisPhase.complete,
          );
    }
  }

  void clear() {
    _requestId++;
    state = const AsyncData(null);
    ref.read(sexAiPhaseProvider.notifier).set(AiAnalysisPhase.idle);
  }
}

final mutationImageAiAnalysisProvider =
    NotifierProvider<
      MutationImageAiAnalysisNotifier,
      AsyncValue<LocalAiMutationInsight?>
    >(MutationImageAiAnalysisNotifier.new);

class MutationImageAiAnalysisNotifier
    extends Notifier<AsyncValue<LocalAiMutationInsight?>> {
  int _requestId = 0;

  @override
  AsyncValue<LocalAiMutationInsight?> build() => const AsyncData(null);

  Future<void> analyze({
    required LocalAiConfig config,
    required String imagePath,
  }) async {
    final requestId = ++_requestId;
    state = const AsyncLoading();
    ref.read(mutationAiPhaseProvider.notifier).set(AiAnalysisPhase.preparing);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (requestId != _requestId) return;
    ref.read(mutationAiPhaseProvider.notifier).set(AiAnalysisPhase.analyzing);
    final nextState = await AsyncValue.guard(() {
      return ref
          .read(localAiServiceProvider)
          .analyzeMutationFromImage(config: config, imagePath: imagePath);
    });
    if (requestId == _requestId) {
      state = nextState;
      ref.read(mutationAiPhaseProvider.notifier).set(
            nextState.hasError ? AiAnalysisPhase.error : AiAnalysisPhase.complete,
          );
    }
  }

  void clear() {
    _requestId++;
    state = const AsyncData(null);
    ref.read(mutationAiPhaseProvider.notifier).set(AiAnalysisPhase.idle);
  }
}

class _AiPhaseNotifier extends Notifier<AiAnalysisPhase> {
  @override
  AiAnalysisPhase build() => AiAnalysisPhase.idle;

  // ignore: use_setters_to_change_properties
  void set(AiAnalysisPhase phase) => state = phase;
}

final geneticsAiPhaseProvider =
    NotifierProvider<_AiPhaseNotifier, AiAnalysisPhase>(
      _AiPhaseNotifier.new,
    );

final sexAiPhaseProvider =
    NotifierProvider<_AiPhaseNotifier, AiAnalysisPhase>(
      _AiPhaseNotifier.new,
    );

final mutationAiPhaseProvider =
    NotifierProvider<_AiPhaseNotifier, AiAnalysisPhase>(
      _AiPhaseNotifier.new,
    );
