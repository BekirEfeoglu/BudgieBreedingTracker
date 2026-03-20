part of 'budgie_color_resolver.dart';

Color _resolveBaseBodyColor({
  required Set<String> ids,
  required String lower,
  required bool isBlueSeries,
  required bool hasAqua,
  required bool hasTurquoise,
}) {
  final hasGrey = ids.contains('grey');
  final hasSlate = ids.contains('slate');
  final hasAnthracite = ids.contains('anthracite');
  final hasViolet = ids.contains('violet');
  final isDoubleAnthracite =
      lower.contains('double factor anthracite') ||
      lower.contains('df anthracite');

  if (lower.contains('double factor anthracite') || hasAnthracite) {
    return _resolveAnthraciteBodyColor(
      lower: lower,
      isBlueSeries: isBlueSeries,
      isDoubleFactor: isDoubleAnthracite,
    );
  }
  if (lower.contains('slate') || hasSlate) {
    return _resolveSlateBodyColor(lower: lower, isBlueSeries: isBlueSeries);
  }
  if (lower.contains('visual violet')) {
    return BudgiePhenotypePalette.violet;
  }
  if (lower.contains('turquoise aqua') || (hasAqua && hasTurquoise)) {
    return BudgiePhenotypePalette.turquoiseAqua;
  }
  if (lower.contains('turquoise') || hasTurquoise) {
    return BudgiePhenotypePalette.turquoise;
  }
  if (lower.contains('aqua') || hasAqua) {
    return BudgiePhenotypePalette.aqua;
  }
  if (lower.contains('grey-green')) {
    return BudgiePhenotypePalette.greyGreen;
  }
  if ((lower.contains('grey') && !lower.contains('greywing')) || hasGrey) {
    return isBlueSeries
        ? BudgiePhenotypePalette.grey
        : BudgiePhenotypePalette.greyGreen;
  }
  if (lower.contains('olive')) {
    return BudgiePhenotypePalette.olive;
  }
  if (lower.contains('dark green')) {
    return BudgiePhenotypePalette.darkGreen;
  }
  if (lower.contains('mauve')) {
    return BudgiePhenotypePalette.mauve;
  }
  if (lower.contains('cobalt')) {
    return BudgiePhenotypePalette.cobalt;
  }
  if ((lower.contains('violet') || hasViolet) && isBlueSeries) {
    return _mix(
      BudgiePhenotypePalette.skyBlue,
      BudgiePhenotypePalette.violet,
      0.55,
    );
  }
  if (isBlueSeries) {
    return BudgiePhenotypePalette.skyBlue;
  }
  if (lower.contains('grey-green')) {
    return BudgiePhenotypePalette.greyGreen;
  }
  return BudgiePhenotypePalette.lightGreen;
}

Color _resolveSlateBodyColor({
  required String lower,
  required bool isBlueSeries,
}) {
  if (isBlueSeries) {
    if (lower.contains('mauve')) {
      return _mix(
        BudgiePhenotypePalette.mauve,
        BudgiePhenotypePalette.slate,
        0.72,
      );
    }
    if (lower.contains('cobalt')) {
      return _mix(
        BudgiePhenotypePalette.cobalt,
        BudgiePhenotypePalette.slate,
        0.74,
      );
    }
    return BudgiePhenotypePalette.slate;
  }

  if (lower.contains('olive')) {
    return _mix(
      BudgiePhenotypePalette.olive,
      BudgiePhenotypePalette.anthraciteGreenDouble,
      0.16,
    );
  }
  if (lower.contains('dark green')) {
    return _mix(
      BudgiePhenotypePalette.darkGreen,
      BudgiePhenotypePalette.greyGreen,
      0.44,
    );
  }
  return _mix(
    BudgiePhenotypePalette.lightGreen,
    BudgiePhenotypePalette.greyGreen,
    0.42,
  );
}

Color _resolveAnthraciteBodyColor({
  required String lower,
  required bool isBlueSeries,
  required bool isDoubleFactor,
}) {
  if (isBlueSeries) {
    if (isDoubleFactor) {
      return BudgiePhenotypePalette.anthraciteDouble;
    }
    return _mix(
      BudgiePhenotypePalette.cobalt,
      BudgiePhenotypePalette.anthraciteSingle,
      0.26,
    );
  }

  if (isDoubleFactor) {
    return BudgiePhenotypePalette.anthraciteGreenDouble;
  }
  return BudgiePhenotypePalette.anthraciteGreenSingle;
}

Color _resolveBaseCheekPatch({
  required bool isBlueSeries,
  required bool hasGrey,
  required bool hasAnthracite,
  required bool hasSlate,
  required String lower,
}) {
  if (hasAnthracite) {
    return BudgiePhenotypePalette.anthraciteSingle;
  }

  if (hasGrey || lower.contains('grey-green')) {
    return BudgiePhenotypePalette.grey;
  }

  if (hasSlate) {
    return BudgiePhenotypePalette.cheekViolet;
  }

  return isBlueSeries
      ? BudgiePhenotypePalette.cheekViolet
      : BudgiePhenotypePalette.cheekBlue;
}

bool _isBlueSeries(
  Set<String> ids,
  String lower,
  bool hasBlue,
  bool hasAqua,
  bool hasTurquoise,
) {
  if (_containsAny(lower, const [
    'light green',
    'dark green',
    'olive',
    'grey-green',
  ])) {
    return false;
  }

  if (hasAqua || hasTurquoise) return true;

  return hasBlue ||
      ids.contains('bluefactor_1') ||
      ids.contains('bluefactor_2') ||
      ids.contains('yellowface_type1') ||
      ids.contains('yellowface_type2') ||
      ids.contains('goldenface') ||
      _containsAny(lower, const [
        'skyblue',
        'cobalt',
        'mauve',
        'blue',
        'violet',
        'slate',
        'albino',
        'creamino',
        'whitefaced',
      ]);
}

bool _containsAny(String input, List<String> terms) {
  for (final term in terms) {
    if (input.contains(term)) return true;
  }
  return false;
}

bool _containsPhrase(String input, String phrase) {
  final pattern = RegExp(
    '(^|[^a-z])${RegExp.escape(phrase)}([^a-z]|\$)',
    caseSensitive: false,
  );
  return pattern.hasMatch(input);
}

String _normalizeMutationId(String raw) {
  final value = raw.trim().toLowerCase();
  return switch (value) {
    'blue' || 'mavi' => 'blue',
    'aqua' => 'aqua',
    'turquoise' || 'turkuaz' => 'turquoise',
    'yellowface type i' || 'yellowface_type1' => 'yellowface_type1',
    'yellowface type ii' || 'yellowface_type2' => 'yellowface_type2',
    'goldenface' => 'goldenface',
    'blue factor i' || 'bluefactor_1' => 'bluefactor_1',
    'blue factor ii' || 'bluefactor_2' => 'bluefactor_2',
    'grey' || 'gri' => 'grey',
    'violet' || 'mor' => 'violet',
    'dark factor' || 'dark_factor' => 'dark_factor',
    'cinnamon' || 'tarcin' => 'cinnamon',
    'ino' || 'albino' || 'lutino' => 'ino',
    'pallid' => 'pallid',
    'greywing' => 'greywing',
    'clearwing' => 'clearwing',
    'dilute' => 'dilute',
    'spangle' => 'spangle',
    'opaline' => 'opaline',
    'pearly' => 'pearly',
    'recessive pied' || 'recessive_pied' => 'recessive_pied',
    'dominant pied' || 'dominant_pied' => 'dominant_pied',
    'clearflight pied' || 'clearflight_pied' => 'clearflight_pied',
    'dutch pied' || 'dutch_pied' => 'dutch_pied',
    'slate' => 'slate',
    'anthracite' => 'anthracite',
    'english fallow' || 'fallow_english' => 'fallow_english',
    'german fallow' || 'fallow_german' => 'fallow_german',
    'texas clearbody' || 'texas_clearbody' => 'texas_clearbody',
    'dominant clearbody' || 'dominant_clearbody' => 'dominant_clearbody',
    'blackface' => 'blackface',
    'saddleback' => 'saddleback',
    _ => value.replaceAll(' ', '_'),
  };
}

Color _resolveCarrierAccent(Set<String> carriedIds) {
  if (carriedIds.isEmpty) return Colors.transparent;

  if (carriedIds.contains('anthracite')) {
    return BudgiePhenotypePalette.anthraciteSingle;
  }
  if (carriedIds.contains('slate')) {
    return BudgiePhenotypePalette.slate;
  }
  if (carriedIds.contains('violet')) {
    return BudgiePhenotypePalette.violet;
  }
  if (carriedIds.contains('grey')) {
    return BudgiePhenotypePalette.grey;
  }
  if (carriedIds.contains('blue') ||
      carriedIds.contains('bluefactor_1') ||
      carriedIds.contains('bluefactor_2')) {
    return BudgiePhenotypePalette.skyBlue;
  }
  if (carriedIds.contains('aqua')) {
    return BudgiePhenotypePalette.aqua;
  }
  if (carriedIds.contains('turquoise')) {
    return BudgiePhenotypePalette.turquoise;
  }
  if (carriedIds.contains('goldenface') ||
      carriedIds.contains('yellowface_type1') ||
      carriedIds.contains('yellowface_type2')) {
    return BudgiePhenotypePalette.maskYellow;
  }
  if (carriedIds.contains('ino')) {
    return BudgiePhenotypePalette.lutino;
  }
  if (carriedIds.contains('cinnamon')) {
    return BudgiePhenotypePalette.cinnamon;
  }
  if (carriedIds.contains('pallid')) {
    return BudgiePhenotypePalette.cream;
  }
  if (carriedIds.contains('greywing')) {
    return BudgiePhenotypePalette.wingGrey;
  }
  if (carriedIds.contains('clearwing') || carriedIds.contains('spangle')) {
    return BudgiePhenotypePalette.maskWhite;
  }
  if (carriedIds.contains('dilute')) {
    return BudgiePhenotypePalette.warmIvory;
  }
  if (carriedIds.contains('opaline') || carriedIds.contains('pearly')) {
    return BudgiePhenotypePalette.cheekViolet;
  }
  if (carriedIds.contains('texas_clearbody') ||
      carriedIds.contains('dominant_clearbody')) {
    return BudgiePhenotypePalette.cheekBlue;
  }
  if (carriedIds.contains('recessive_pied') ||
      carriedIds.contains('dominant_pied') ||
      carriedIds.contains('clearflight_pied') ||
      carriedIds.contains('dutch_pied')) {
    return BudgiePhenotypePalette.maskYellow;
  }
  if (carriedIds.contains('fallow_english') ||
      carriedIds.contains('fallow_german')) {
    return BudgiePhenotypePalette.fallowTaupe;
  }
  if (carriedIds.contains('blackface')) {
    return BudgiePhenotypePalette.wingBlack;
  }

  return BudgiePhenotypePalette.cheekBlue;
}

Color _mix(Color a, Color b, double amount) {
  return Color.lerp(a, b, amount.clamp(0.0, 1.0)) ?? a;
}

Color _lighten(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

Color _saturate(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withSaturation((hsl.saturation + amount).clamp(0.0, 1.0))
      .toColor();
}

const List<String> _blueTerms = [
  'skyblue',
  'cobalt',
  'mauve',
  'blue',
  'anthracite',
  'albino',
  'creamino',
  'whitefaced',
  'yellowface',
  'goldenface',
];
