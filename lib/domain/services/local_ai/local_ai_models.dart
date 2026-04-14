import 'package:flutter/foundation.dart' show immutable;

part 'local_ai_mutation_postprocess.dart';

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

  /// Warning shown when ino is predicted — eye color verification needed.
  final String inoWarning;

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
    this.inoWarning = '',
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

    // Unknown fallback: if model says "unknown" but has series/pattern info,
    // try to infer the most likely mutation from available evidence.
    var correctedMutation = predictedMutation;
    if (predictedMutation == 'unknown' && baseSeries != 'unknown') {
      correctedMutation = _inferFromEvidence(
        baseSeries: baseSeries,
        patternFamily: patternFamily,
        bodyColor: bodyColor,
        eyeColor: eyeColor,
        secondary: secondary,
      );
    }

    // Eye color gate: ino mutations (albino/lutino) REQUIRE red/pink eyes.
    // If the model predicts ino but eye_color doesn't clearly indicate
    // red/pink, downgrade to the most likely non-ino alternative.
    if (_isInoMutation(predictedMutation) &&
        eyeColor.isNotEmpty &&
        !_hasRedPinkEyes(eyeColor)) {
      // Model hallucinated ino — correct to spangle DF or dominant pied
      correctedMutation = _correctInoToNonIno(
        predictedMutation: predictedMutation,
        baseSeries: baseSeries,
        secondary: secondary,
      );
      // Override series/pattern to match the corrected mutation
      final correctedSig = _mutationSignature[correctedMutation];
      if (correctedSig != null) {
        if (correctedSig.series.length == 1) {
          baseSeries = correctedSig.series.first;
        }
        if (correctedSig.family.length == 1) {
          patternFamily = correctedSig.family.first;
        }
      }
    }

    // Ino predictions always get low confidence + warning because
    // small models frequently hallucinate red eye color.
    final isInoPrediction = _isInoMutation(correctedMutation);
    // Store L10n key instead of hardcoded Turkish text — UI resolves via .tr()
    final inoWarning = isInoPrediction ? 'genetics.ino_warning' : '';

    return LocalAiMutationInsight(
      predictedMutation: correctedMutation,
      confidence: isInoPrediction
          ? LocalAiConfidence.low
          : _normalizeMutationConfidence(
              rawConfidence: rawConfidence,
              predictedMutation: correctedMutation,
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
      inoWarning: inoWarning,
      secondaryPossibilities: _buildSecondaryList(
        secondary: secondary,
        baseSeries: baseSeries,
        patternFamily: patternFamily,
        isInoPrediction: isInoPrediction,
        correctedMutation: correctedMutation,
      ),
    );
  }
}

String _normalizedTag(String? value) {
  final normalized = _normalizeToken(value);
  return normalized.isEmpty ? 'unknown' : normalized;
}

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
  final raw = value?.trim().toLowerCase() ?? 'unknown';
  // Strip Turkish diacritics for robust matching.
  final normalized = _stripDiacritics(raw);
  return switch (normalized) {
    'disi' => 'disi',
    'dusuk' || 'dusuk' => 'dusuk',
    'yuksek' => 'yuksek',
    'yesil' => 'green',
    'mavi' => 'blue',
    'normal desen' => 'normal',
    'erkek' => 'erkek',
    'belirsiz' => 'belirsiz',
    'orta' => 'orta',
    _ => normalized,
  };
}

/// Strips Turkish diacritics so that 'açık' == 'acik', 'düşük' == 'dusuk', etc.
String _stripDiacritics(String input) {
  const map = {
    'ş': 's', 'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ü': 'u',
    'İ': 'i', 'Ş': 's', 'Ç': 'c', 'Ğ': 'g', 'Ö': 'o', 'Ü': 'u',
    // Common model-output characters
    'é': 'e', 'è': 'e', 'ê': 'e', 'ä': 'a', 'â': 'a',
  };
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    buffer.write(map[c] ?? c);
  }
  return buffer.toString();
}
