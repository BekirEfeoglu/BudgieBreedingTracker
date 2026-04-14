part of 'local_ai_models.dart';

/// Build filtered secondary possibilities list.
List<String> _buildSecondaryList({
  required List<String> secondary,
  required String baseSeries,
  required String patternFamily,
  required bool isInoPrediction,
  required String correctedMutation,
}) {
  final filtered = secondary
      .where(
        (item) => _isMutationConsistent(
          mutation: item,
          baseSeries: baseSeries,
          patternFamily: patternFamily,
        ),
      )
      .toList();

  // When red-eye mutation is predicted, suggest dark-eye alternatives
  if (isInoPrediction) {
    final isBlue = baseSeries == 'blue' || baseSeries == 'albino';
    final alts = isBlue
        ? ['spangle_blue', 'dominant_pied_blue']
        : ['spangle_green', 'dominant_pied_green'];

    for (final alt in alts) {
      if (!filtered.contains(alt) && alt != correctedMutation) {
        filtered.add(alt);
      }
    }
  }

  return filtered.take(3).toList(growable: false);
}

/// When model returns "unknown" but has series/pattern data,
/// infer the most likely mutation from available evidence.
String _inferFromEvidence({
  required String baseSeries,
  required String patternFamily,
  required String bodyColor,
  required String eyeColor,
  required List<String> secondary,
}) {
  // Prefer non-unknown secondary if available
  for (final alt in secondary) {
    if (alt != 'unknown') return alt;
  }

  // Infer from pattern + series
  if (patternFamily != 'unknown') {
    final suffix = baseSeries == 'green' ? '_green' : '_blue';
    final candidate = '$patternFamily$suffix';
    if (_mutationSignature.containsKey(candidate)) return candidate;
  }

  // Pale/white body + blue series + unknown pattern → likely spangle DF or dilute
  // Strip diacritics so 'açık'/'acik', 'seyreltilmiş'/'seyreltilmis' etc. match.
  final lowerBody = _stripDiacritics(bodyColor.toLowerCase());
  final isPaleBody = lowerBody.contains('beyaz') ||
      lowerBody.contains('white') ||
      lowerBody.contains('acik') ||
      lowerBody.contains('soluk') ||
      lowerBody.contains('light') ||
      lowerBody.contains('pale') ||
      lowerBody.contains('krem') ||
      lowerBody.contains('cream') ||
      lowerBody.contains('dilute') ||
      lowerBody.contains('seyreltilmis') ||
      lowerBody.contains('faded') ||
      lowerBody.contains('washed');

  if (isPaleBody && baseSeries == 'blue') {
    // Check eye color for ino vs non-ino
    if (_hasRedPinkEyes(eyeColor)) return 'albino';
    return 'spangle_blue'; // DF Spangle most likely for pale + dark eyes
  }
  if (isPaleBody && baseSeries == 'green') {
    if (_hasRedPinkEyes(eyeColor)) return 'lutino';
    return 'spangle_green';
  }

  // Fall back to normal variant based on series
  return baseSeries == 'blue' ? 'normal_skyblue' : 'normal_light_green';
}

/// Mutations that require red/pink eyes. Includes ino-based and fallow.
bool _isInoMutation(String mutation) {
  const redEyeMutations = {
    'lutino', 'albino', 'creamino',
    'fallow_green', 'fallow_blue',
    'lacewing_green', 'lacewing_blue',
    'texas_clearbody_green', 'texas_clearbody_blue',
  };
  return redEyeMutations.contains(mutation);
}

/// Returns true if the eye color description indicates red/pink eyes.
bool _hasRedPinkEyes(String eyeColor) {
  final lower = _stripDiacritics(eyeColor.toLowerCase());
  const redPinkTokens = [
    'red', 'pink', 'kirmizi', 'pembe', 'ruby', 'rot', 'rosa',
    'kizil', 'rosy', 'crimson', 'scarlet', 'magenta',
  ];
  return redPinkTokens.any(lower.contains);
}

/// When the model incorrectly predicts a red-eye mutation but eyes aren't
/// red/pink, substitute the most likely dark-eye alternative.
String _correctInoToNonIno({
  required String predictedMutation,
  required String baseSeries,
  required List<String> secondary,
}) {
  // Prefer a non-red-eye secondary if available
  for (final alt in secondary) {
    if (!_isInoMutation(alt) && alt != 'unknown') return alt;
  }
  // Map each red-eye mutation to its dark-eye equivalent
  final isBlue = baseSeries == 'blue' ||
      predictedMutation.contains('blue') ||
      predictedMutation == 'albino' ||
      predictedMutation == 'creamino';
  return switch (predictedMutation) {
    'albino' => 'spangle_blue',
    'lutino' => 'spangle_green',
    'creamino' => 'spangle_blue',
    'fallow_green' => 'cinnamon_green',
    'fallow_blue' => 'cinnamon_blue',
    'lacewing_green' => 'cinnamon_green',
    'lacewing_blue' => 'cinnamon_blue',
    'texas_clearbody_green' => 'clearbody_green',
    'texas_clearbody_blue' => 'clearbody_blue',
    _ => isBlue ? 'spangle_blue' : 'spangle_green',
  };
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

/// Known mutation label → valid (series, pattern family) combinations.
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
  'yellowface_blue': (series: {'blue'}, family: {'yellowface', 'normal'}),
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
  'grey_green': (series: {'green'}, family: {'grey', 'normal'}),
  'grey_blue': (series: {'blue'}, family: {'grey', 'normal'}),
  'fallow_green': (series: {'green'}, family: {'fallow'}),
  'fallow_blue': (series: {'blue'}, family: {'fallow'}),
  'lacewing_green': (series: {'green'}, family: {'lacewing'}),
  'lacewing_blue': (series: {'blue'}, family: {'lacewing'}),
  'opaline_cinnamon_green': (series: {'green'}, family: {'opaline', 'cinnamon'}),
  'opaline_cinnamon_blue': (series: {'blue'}, family: {'opaline', 'cinnamon'}),
  'violet_blue': (series: {'blue'}, family: {'violet', 'normal'}),
  'slate_blue': (series: {'blue'}, family: {'slate', 'normal'}),
  'dark_eyed_clear_green': (series: {'green'}, family: {'spangle', 'pied'}),
  'dark_eyed_clear_blue': (series: {'blue'}, family: {'spangle', 'pied'}),
  'texas_clearbody_green': (series: {'green'}, family: {'clearbody'}),
  'texas_clearbody_blue': (series: {'blue'}, family: {'clearbody'}),
  'creamino': (series: {'blue'}, family: {'ino'}),
};
