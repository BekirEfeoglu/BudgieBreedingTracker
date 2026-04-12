import 'package:flutter/foundation.dart' show immutable;

enum LocalAiConfidence {
  low,
  medium,
  high,
  unknown;

  static LocalAiConfidence fromRaw(String? value) =>
      switch (_normalizeToken(value)) {
        'low' || 'dusuk' => LocalAiConfidence.low,
        'medium' || 'orta' => LocalAiConfidence.medium,
        'high' || 'yuksek' => LocalAiConfidence.high,
        _ => LocalAiConfidence.unknown,
      };
}

enum LocalAiSexPrediction {
  male,
  female,
  uncertain;

  static LocalAiSexPrediction fromRaw(String? value) =>
      switch (_normalizeToken(value)) {
        'male' || 'erkek' => LocalAiSexPrediction.male,
        'female' || 'disi' || 'dişi' => LocalAiSexPrediction.female,
        'uncertain' || 'belirsiz' => LocalAiSexPrediction.uncertain,
        _ => LocalAiSexPrediction.uncertain,
      };
}

enum LocalAiProvider {
  ollama,
  openRouter;

  static LocalAiProvider fromRaw(String? value) => switch (value?.trim()) {
    'ollama' => LocalAiProvider.ollama,
    _ => LocalAiProvider.openRouter,
  };

  String get key => name;
}

@immutable
class LocalAiConfig {
  final LocalAiProvider provider;
  final String baseUrl;
  final String model;
  final String apiKey;

  const LocalAiConfig({
    this.provider = LocalAiProvider.ollama,
    required this.baseUrl,
    required this.model,
    this.apiKey = '',
  });

  static const defaults = LocalAiConfig(
    baseUrl: 'http://127.0.0.1:11434',
    model: 'gemma4:latest',
  );

  static const openRouterDefaults = LocalAiConfig(
    provider: LocalAiProvider.openRouter,
    baseUrl: 'https://openrouter.ai',
    model: 'google/gemma-4-26b-a4b-it:free',
  );

  bool get isOpenRouter => provider == LocalAiProvider.openRouter;

  String get normalizedBaseUrl {
    if (isOpenRouter) return 'https://openrouter.ai';
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) return defaults.baseUrl;

    final withScheme = trimmed.contains('://') ? trimmed : 'http://$trimmed';
    return withScheme.endsWith('/')
        ? withScheme.substring(0, withScheme.length - 1)
        : withScheme;
  }

  String get normalizedModel {
    final trimmed = model.trim();
    if (trimmed.isEmpty) {
      return isOpenRouter
          ? openRouterDefaults.model
          : defaults.model;
    }
    return trimmed;
  }

  LocalAiConfig copyWith({
    LocalAiProvider? provider,
    String? baseUrl,
    String? model,
    String? apiKey,
  }) {
    return LocalAiConfig(
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

@immutable
class LocalAiGeneticsInsight {
  final String summary;
  final LocalAiConfidence confidence;
  final List<String> likelyMutations;
  final List<String> matchedGenetics;
  final String sexLinkedNote;
  final List<String> warnings;
  final List<String> nextChecks;

  const LocalAiGeneticsInsight({
    required this.summary,
    required this.confidence,
    required this.likelyMutations,
    required this.matchedGenetics,
    required this.sexLinkedNote,
    required this.warnings,
    required this.nextChecks,
  });

  factory LocalAiGeneticsInsight.fromJson(
    Map<String, dynamic> json, {
    Set<String> allowedGenetics = const {},
  }) {
    final matchedGenetics = _stringList(json['matched_genetics'])
        .map((item) => item.trim())
        .where(
          (item) => allowedGenetics.isEmpty || allowedGenetics.contains(item),
        )
        .toList(growable: false);

    return LocalAiGeneticsInsight(
      summary: (json['summary'] as String?)?.trim() ?? '',
      confidence: LocalAiConfidence.fromRaw(json['confidence'] as String?),
      likelyMutations: _stringList(json['likely_mutations']),
      matchedGenetics: matchedGenetics,
      sexLinkedNote: (json['sex_linked_note'] as String?)?.trim() ?? '',
      warnings: _stringList(json['warnings']),
      nextChecks: _stringList(json['next_checks']),
    );
  }
}

@immutable
class LocalAiSexInsight {
  final LocalAiSexPrediction predictedSex;
  final LocalAiConfidence confidence;
  final String rationale;
  final List<String> indicators;
  final List<String> nextChecks;

  const LocalAiSexInsight({
    required this.predictedSex,
    required this.confidence,
    required this.rationale,
    required this.indicators,
    required this.nextChecks,
  });

  factory LocalAiSexInsight.fromJson(Map<String, dynamic> json) {
    return LocalAiSexInsight(
      predictedSex: LocalAiSexPrediction.fromRaw(
        json['predicted_sex'] as String?,
      ),
      confidence: LocalAiConfidence.fromRaw(json['confidence'] as String?),
      rationale: (json['rationale'] as String?)?.trim() ?? '',
      indicators: _stringList(json['indicators']),
      nextChecks: _stringList(json['next_checks']),
    );
  }
}

@immutable
class LocalAiMutationInsight {
  final String predictedMutation;
  final LocalAiConfidence confidence;
  final String baseSeries;
  final String patternFamily;
  final String bodyColor;
  final String wingPattern;
  final String eyeColor;
  final String rationale;
  final List<String> secondaryPossibilities;

  const LocalAiMutationInsight({
    required this.predictedMutation,
    required this.confidence,
    required this.baseSeries,
    required this.patternFamily,
    required this.bodyColor,
    required this.wingPattern,
    required this.eyeColor,
    required this.rationale,
    required this.secondaryPossibilities,
  });

  factory LocalAiMutationInsight.fromJson(Map<String, dynamic> json) {
    final predictedMutation =
        (json['predicted_mutation'] as String?)?.trim() ?? 'unknown';
    final secondary = _stringList(json['secondary_possibilities'])
        .where((item) => item != 'unknown' && item != predictedMutation)
        .take(3)
        .toList(growable: false);
    var baseSeries = _normalizedTag(json['base_series'] as String?);
    var patternFamily = _normalizedTag(json['pattern_family'] as String?);

    // Infer series/pattern from known mutation signature when model
    // returns "unknown" but gives a valid predicted_mutation.
    final signature = _mutationSignature[predictedMutation];
    if (signature != null) {
      if (baseSeries == 'unknown' && signature.series.length == 1) {
        baseSeries = signature.series.first;
      }
      if (patternFamily == 'unknown' && signature.family.length == 1) {
        patternFamily = signature.family.first;
      }
    }

    final bodyColor = (json['body_color'] as String?)?.trim() ?? '';
    final wingPattern = (json['wing_pattern'] as String?)?.trim() ?? '';
    final eyeColor = (json['eye_color'] as String?)?.trim() ?? '';
    final rationale = (json['rationale'] as String?)?.trim() ?? '';
    final rawConfidence = LocalAiConfidence.fromRaw(
      json['confidence'] as String?,
    );
    final evidenceCount = [
      bodyColor,
      wingPattern,
      eyeColor,
    ].where((item) => item.isNotEmpty).length;

    return LocalAiMutationInsight(
      predictedMutation: predictedMutation,
      confidence: _normalizeMutationConfidence(
        rawConfidence: rawConfidence,
        predictedMutation: predictedMutation,
        evidenceCount: evidenceCount,
        baseSeries: baseSeries,
        patternFamily: patternFamily,
      ),
      baseSeries: baseSeries,
      patternFamily: patternFamily,
      bodyColor: bodyColor,
      wingPattern: wingPattern,
      eyeColor: eyeColor,
      rationale: rationale,
      secondaryPossibilities: secondary
          .where(
            (item) => _isMutationConsistent(
              mutation: item,
              baseSeries: baseSeries,
              patternFamily: patternFamily,
            ),
          )
          .toList(growable: false),
    );
  }
}

LocalAiConfidence _normalizeMutationConfidence({
  required LocalAiConfidence rawConfidence,
  required String predictedMutation,
  required int evidenceCount,
  required String baseSeries,
  required String patternFamily,
}) {
  if (predictedMutation == 'unknown') return LocalAiConfidence.low;
  if (!_isMutationConsistent(
    mutation: predictedMutation,
    baseSeries: baseSeries,
    patternFamily: patternFamily,
  )) {
    return LocalAiConfidence.low;
  }
  if (evidenceCount <= 1) return LocalAiConfidence.low;
  if (evidenceCount == 2 && rawConfidence == LocalAiConfidence.high) {
    return LocalAiConfidence.medium;
  }
  return rawConfidence;
}

String _normalizedTag(String? value) {
  final normalized = _normalizeToken(value);
  return normalized.isEmpty ? 'unknown' : normalized;
}

bool _isMutationConsistent({
  required String mutation,
  required String baseSeries,
  required String patternFamily,
}) {
  final signature = _mutationSignature[mutation];
  if (signature == null) return mutation == 'unknown';
  final seriesOk =
      baseSeries == 'unknown' || signature.series.contains(baseSeries);
  final familyOk =
      patternFamily == 'unknown' || signature.family.contains(patternFamily);
  return seriesOk && familyOk;
}

const _mutationSignature = <String, ({Set<String> series, Set<String> family})>{
  'normal_light_green': (series: {'green'}, family: {'normal'}),
  'normal_dark_green': (series: {'green'}, family: {'normal'}),
  'normal_olive': (series: {'green'}, family: {'normal'}),
  'spangle_green': (series: {'green'}, family: {'spangle'}),
  'cinnamon_green': (series: {'green'}, family: {'cinnamon'}),
  'opaline_green': (series: {'green'}, family: {'opaline'}),
  'dominant_pied_green': (series: {'green'}, family: {'pied'}),
  'recessive_pied_green': (series: {'green'}, family: {'pied'}),
  'clearwing_green': (series: {'green'}, family: {'clearwing'}),
  'greywing_green': (series: {'green'}, family: {'greywing'}),
  'dilute_green': (series: {'green'}, family: {'dilute'}),
  'clearbody_green': (series: {'green'}, family: {'clearbody'}),
  'lutino': (series: {'lutino'}, family: {'ino'}),
  'yellowface_blue': (series: {'blue'}, family: {'yellowface'}),
  'violet_green': (series: {'green'}, family: {'violet', 'normal'}),
  'normal_skyblue': (series: {'blue'}, family: {'normal'}),
  'normal_cobalt': (series: {'blue'}, family: {'normal'}),
  'normal_mauve': (series: {'blue'}, family: {'normal'}),
  'spangle_blue': (series: {'blue'}, family: {'spangle'}),
  'cinnamon_blue': (series: {'blue'}, family: {'cinnamon'}),
  'opaline_blue': (series: {'blue'}, family: {'opaline'}),
  'dominant_pied_blue': (series: {'blue'}, family: {'pied'}),
  'recessive_pied_blue': (series: {'blue'}, family: {'pied'}),
  'clearwing_blue': (series: {'blue'}, family: {'clearwing'}),
  'greywing_blue': (series: {'blue'}, family: {'greywing'}),
  'dilute_blue': (series: {'blue'}, family: {'dilute'}),
  'clearbody_blue': (series: {'blue'}, family: {'clearbody'}),
  'albino': (series: {'albino', 'blue'}, family: {'ino'}),
};

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Object>()
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

String _normalizeToken(String? value) {
  final normalized = value?.trim().toLowerCase() ?? 'unknown';
  return switch (normalized) {
    'dişi' || 'disi' => 'disi',
    'düşük' || 'dusuk' || 'düsük' => 'dusuk',
    'yüksek' || 'yuksek' => 'yuksek',
    'yesil' || 'yeşil' => 'green',
    'mavi' => 'blue',
    'normal desen' => 'normal',
    'erkek' => 'erkek',
    'belirsiz' => 'belirsiz',
    'orta' => 'orta',
    _ => normalized,
  };
}
