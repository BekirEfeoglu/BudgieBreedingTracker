part of 'budgie_color_resolver.dart';

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

/// Computes eye, throat-spot, tail, back and beak details from mutations.
({
  Color eyeColor, Color eyeRingColor, bool showEyeRing,
  Color? backColor, Color tailColor,
  Color throatSpotColor, bool showThroatSpots, int throatSpotCount,
  Color beakColor,
}) _resolveAnatomyDetails({
  required bool isAlbino, required bool isLutino,
  required bool isCreamino, required bool isLacewing,
  required bool isDarkEyedClear, required bool isDoubleFactorSpangle,
  required bool isBlueSeries, required bool hasOpaline,
  required bool hasCinnamon, required bool hasDilute,
  required bool hasGreywing, required bool hasEnglishFallow,
  required bool hasGermanFallow, required bool hasRecessivePied,
  required bool hasTexasClearbody, required Color body,
}) {
  final isIno = isAlbino || isLutino || isCreamino || isLacewing;
  const black = Color(0xFF1A1A1A);
  const whiteRing = Color(0xFFF0F0F0);
  const baseTailBlue = Color(0xFF2B3F6F);
  const baseTailGreen = Color(0xFF2B4F6F);

  // Eye
  final (Color eyeColor, Color eyeRingColor, bool showEyeRing) = switch (true) {
    _ when isIno => (const Color(0xFFCC2233), const Color(0xFFF2C8CC), true),
    _ when hasEnglishFallow => (const Color(0xFFCC2838), whiteRing, false),
    _ when hasGermanFallow => (const Color(0xFFA82030), whiteRing, true),
    _ when hasRecessivePied => (const Color(0xFF1F0F18), whiteRing, false),
    _ when isDarkEyedClear => (const Color(0xFF0F0F0F), whiteRing, false),
    _ => (black, whiteRing, true),
  };

  // Throat spots
  final (bool showThroatSpots, int throatSpotCount, Color throatSpotColor) =
      switch (true) {
    _ when isIno || isDoubleFactorSpangle || isDarkEyedClear =>
      (false, 0, black),
    _ when hasOpaline => (
        true, 4,
        hasCinnamon ? BudgiePhenotypePalette.cinnamon : black,
      ),
    _ when hasCinnamon => (true, 6, BudgiePhenotypePalette.cinnamon),
    _ when hasDilute || hasGreywing => (true, 6, BudgiePhenotypePalette.wingGrey),
    _ => (true, 6, black),
  };

  // Tail
  final baseTail = isBlueSeries ? baseTailBlue : baseTailGreen;
  final Color tailColor = switch (true) {
    _ when isIno && !isBlueSeries =>
      BudgiePhenotypePalette.maskYellow.withValues(alpha: 0.20),
    _ when isIno => baseTail.withValues(alpha: 0.10),
    _ when hasCinnamon => const Color(0xFF6B5040),
    _ when hasDilute || hasGreywing => BudgiePhenotypePalette.wingGrey,
    _ when hasOpaline => _mix(baseTail, body, 0.30),
    _ => baseTail,
  };

  // Back
  final Color? backColor = switch (true) {
    _ when hasCinnamon && hasOpaline =>
      _mix(body, BudgiePhenotypePalette.cinnamon, 0.15),
    _ when hasOpaline => body,
    _ when hasTexasClearbody => _lighten(body, 0.08),
    _ => null,
  };

  // Beak
  final Color beakColor = switch (true) {
    _ when isIno => const Color(0xFFF0C060),
    _ when hasEnglishFallow || hasGermanFallow => const Color(0xFFE89830),
    _ => const Color(0xFFE8A830),
  };

  return (
    eyeColor: eyeColor, eyeRingColor: eyeRingColor, showEyeRing: showEyeRing,
    backColor: backColor, tailColor: tailColor,
    throatSpotColor: throatSpotColor, showThroatSpots: showThroatSpots,
    throatSpotCount: throatSpotCount, beakColor: beakColor,
  );
}
