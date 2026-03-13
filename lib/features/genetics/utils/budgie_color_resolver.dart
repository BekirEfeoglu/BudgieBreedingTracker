import 'package:flutter/material.dart';

/// Research-backed budgerigar palette used by genetics result previews.
///
/// Base hues are aligned to exhibition-style variety standards published by the
/// World Budgerigar Organisation and then adjusted for on-screen readability.
/// Mutation effect rules follow those standards plus phenotype descriptions from
/// BudgieGenEx, Budgie World, Budgie Bubble, and mutation reference articles.
abstract final class BudgiePhenotypePalette {
  static const lightGreen = Color(0xFF8CD600);
  static const darkGreen = Color(0xFF56AA1C);
  static const olive = Color(0xFF566B21);
  static const greyGreen = Color(0xFFAFA80A);

  static const skyBlue = Color(0xFF72D1DD);
  static const cobalt = Color(0xFF60AFDD);
  static const mauve = Color(0xFF9BA3B7);
  static const violet = Color(0xFF5D63C7);
  static const grey = Color(0xFFD1CEC6);
  static const slate = Color(0xFF647E90);
  static const anthraciteSingle = Color(0xFF57646E);
  static const anthraciteDouble = Color(0xFF3F474F);

  static const aqua = Color(0xFF67C9B7);
  static const turquoise = Color(0xFF4FB8C5);
  static const turquoiseAqua = Color(0xFF65C4AE);

  static const maskYellow = Color(0xFFF3DF63);
  static const maskWhite = Color(0xFFF4F7FA);
  static const warmIvory = Color(0xFFF4E7C6);
  static const cream = Color(0xFFF7E9AE);
  static const lutino = Color(0xFFF4DF57);

  static const wingBlack = Color(0xFF2F3138);
  static const wingPaleBlack = Color(0xFF5C6168);
  static const wingGrey = Color(0xFF7E8A92);
  static const wingSoftGrey = Color(0xFFB2BCC3);
  static const cinnamon = Color(0xFF8B6652);
  static const fallowTaupe = Color(0xFF9A7B63);

  static const cheekBlue = Color(0xFF3D76C3);
  static const cheekViolet = Color(0xFF7A78C7);
  static const cheekSilver = Color(0xFFD7DDE3);
  static const cheekPaleViolet = Color(0xFFD2C6E9);
  static const cheekSmokeGrey = Color(0xFF8F969C);
}

@immutable
class BudgieColorAppearance {
  final Color bodyColor;
  final Color maskColor;
  final Color wingMarkingColor;
  final Color wingFillColor;
  final Color cheekPatchColor;
  final Color piedPatchColor;
  final Color carrierAccentColor;
  final bool showCheekPatch;
  final bool showPiedPatch;
  final bool showMantleHighlight;
  final bool showCarrierAccent;
  final bool hideWingMarkings;

  const BudgieColorAppearance({
    required this.bodyColor,
    required this.maskColor,
    required this.wingMarkingColor,
    required this.wingFillColor,
    required this.cheekPatchColor,
    required this.piedPatchColor,
    required this.carrierAccentColor,
    required this.showCheekPatch,
    required this.showPiedPatch,
    required this.showMantleHighlight,
    required this.showCarrierAccent,
    required this.hideWingMarkings,
  });
}

abstract final class BudgieColorResolver {
  static BudgieColorAppearance resolve({
    required Iterable<String> visualMutations,
    required String phenotype,
    Iterable<String> carriedMutations = const [],
  }) {
    final ids = visualMutations.map((id) => id.toLowerCase()).toSet();
    final carriedIds = carriedMutations
        .map(_normalizeMutationId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final lower = phenotype.toLowerCase().trim();

    final hasBlue = ids.contains('blue') || _containsAny(lower, _blueTerms);
    final hasAqua = ids.contains('aqua') || lower.contains('aqua');
    final hasTurquoise =
        ids.contains('turquoise') || lower.contains('turquoise');
    final hasYf1 =
        ids.contains('yellowface_type1') ||
        _containsPhrase(lower, 'yellowface type i');
    final hasYf2 =
        ids.contains('yellowface_type2') ||
        _containsPhrase(lower, 'yellowface type ii');
    final hasGoldenface =
        ids.contains('goldenface') || _containsPhrase(lower, 'goldenface');
    final hasBlueFactor1 =
        ids.contains('bluefactor_1') || _containsPhrase(lower, 'blue factor i');
    final hasBlueFactor2 =
        ids.contains('bluefactor_2') ||
        _containsPhrase(lower, 'blue factor ii');
    final hasGrey =
        ids.contains('grey') ||
        (lower.contains('grey') && !lower.contains('greywing'));
    final hasSlate = ids.contains('slate') || lower.contains('slate');
    final hasAnthracite =
        ids.contains('anthracite') || lower.contains('anthracite');
    final hasClearwing =
        ids.contains('clearwing') || lower.contains('clearwing');
    final hasGreywing = ids.contains('greywing') || lower.contains('greywing');
    final hasDilute = ids.contains('dilute') || lower.contains('dilute');
    final hasCinnamon = ids.contains('cinnamon') || lower.contains('cinnamon');
    final hasPallid = ids.contains('pallid') || lower.contains('pallid');
    final hasOpaline = ids.contains('opaline') || lower.contains('opaline');
    final hasPearly = ids.contains('pearly') || lower.contains('pearly');
    final hasSpangle = ids.contains('spangle') || lower.contains('spangle');
    final hasBlackface =
        ids.contains('blackface') || lower.contains('blackface');
    final hasEnglishFallow =
        ids.contains('fallow_english') || lower.contains('english fallow');
    final hasGermanFallow =
        ids.contains('fallow_german') || lower.contains('german fallow');
    final hasTexasClearbody =
        ids.contains('texas_clearbody') || lower.contains('texas clearbody');
    final hasDominantClearbody =
        ids.contains('dominant_clearbody') ||
        lower.contains('dominant clearbody');
    final hasSaddleback =
        ids.contains('saddleback') || lower.contains('saddleback');

    final isBlueSeries = _isBlueSeries(
      ids,
      lower,
      hasBlue,
      hasAqua,
      hasTurquoise,
    );
    final isDoubleFactorSpangle =
        lower.contains('double factor spangle') || lower.contains('df spangle');
    final isDarkEyedClear = lower.contains('dark-eyed clear');
    final isAlbino = lower.contains('albino');
    final isLutino = lower.contains('lutino');
    final isCreamino = lower.contains('creamino');
    final isLacewing =
        lower.contains('lacewing') || lower.contains('pallidino');

    var body = _resolveBaseBodyColor(
      ids: ids,
      lower: lower,
      isBlueSeries: isBlueSeries,
      hasAqua: hasAqua,
      hasTurquoise: hasTurquoise,
    );
    var mask = isBlueSeries
        ? BudgiePhenotypePalette.maskWhite
        : BudgiePhenotypePalette.maskYellow;
    var wingMarkings = BudgiePhenotypePalette.wingBlack;
    var wingFill = Colors.transparent;
    var cheekPatch = _resolveBaseCheekPatch(
      isBlueSeries: isBlueSeries,
      hasGrey: hasGrey,
      hasAnthracite: hasAnthracite,
      hasSlate: hasSlate,
      lower: lower,
    );
    var piedPatch = mask;
    var showPiedPatch = false;
    var showMantleHighlight = hasOpaline || hasPearly || hasSaddleback;
    var hideWingMarkings = false;
    final carrierAccentColor = _resolveCarrierAccent(carriedIds);
    final showCarrierAccent = carriedIds.isNotEmpty;

    if (hasBlueFactor1 || hasBlueFactor2 || hasYf1 || hasYf2 || hasGoldenface) {
      if (lower.contains('whitefaced')) {
        mask = BudgiePhenotypePalette.maskWhite;
      } else if (isBlueSeries) {
        mask = BudgiePhenotypePalette.maskYellow;
      }
    }

    if (isBlueSeries && mask == BudgiePhenotypePalette.maskYellow) {
      if (hasGoldenface) {
        body = _mix(body, BudgiePhenotypePalette.maskYellow, 0.30);
      } else if (hasYf2 || hasBlueFactor2) {
        body = _mix(body, BudgiePhenotypePalette.maskYellow, 0.22);
      } else if (hasYf1 || hasBlueFactor1) {
        body = _mix(body, BudgiePhenotypePalette.maskYellow, 0.10);
      }
    }

    if (isDarkEyedClear) {
      body = isBlueSeries
          ? BudgiePhenotypePalette.maskWhite
          : BudgiePhenotypePalette.maskYellow;
      mask = body;
      wingMarkings = Colors.transparent;
      wingFill = Colors.transparent;
      cheekPatch = BudgiePhenotypePalette.maskWhite;
      hideWingMarkings = true;
      showMantleHighlight = false;
    } else if (isDoubleFactorSpangle) {
      body = isBlueSeries
          ? BudgiePhenotypePalette.maskWhite
          : BudgiePhenotypePalette.maskYellow;
      mask = body;
      wingMarkings = Colors.transparent;
      wingFill = Colors.transparent;
      cheekPatch = BudgiePhenotypePalette.cheekSilver;
      hideWingMarkings = true;
      showMantleHighlight = false;
    } else if (isAlbino || isLutino || isCreamino || isLacewing) {
      if (isAlbino) {
        body = BudgiePhenotypePalette.maskWhite;
        mask = BudgiePhenotypePalette.maskWhite;
        cheekPatch = BudgiePhenotypePalette.maskWhite;
      } else if (isCreamino) {
        body = BudgiePhenotypePalette.cream;
        mask = BudgiePhenotypePalette.warmIvory;
        cheekPatch = BudgiePhenotypePalette.cheekPaleViolet;
      } else {
        body = BudgiePhenotypePalette.lutino;
        mask = BudgiePhenotypePalette.maskYellow;
        cheekPatch = BudgiePhenotypePalette.maskWhite;
      }

      if (isLacewing) {
        body = isBlueSeries
            ? BudgiePhenotypePalette.warmIvory
            : BudgiePhenotypePalette.cream;
        mask = body;
        wingMarkings = BudgiePhenotypePalette.cinnamon;
        cheekPatch = BudgiePhenotypePalette.cheekPaleViolet;
      } else {
        wingMarkings = Colors.transparent;
        hideWingMarkings = true;
      }
    } else {
      if (hasTexasClearbody) {
        body = _mix(
          isBlueSeries
              ? BudgiePhenotypePalette.maskWhite
              : BudgiePhenotypePalette.maskYellow,
          body,
          0.30,
        );
        mask = isBlueSeries
            ? BudgiePhenotypePalette.maskWhite
            : BudgiePhenotypePalette.maskYellow;
        wingMarkings = BudgiePhenotypePalette.wingPaleBlack;
      } else if (hasDominantClearbody) {
        body = _mix(
          isBlueSeries
              ? BudgiePhenotypePalette.maskWhite
              : BudgiePhenotypePalette.maskYellow,
          body,
          0.48,
        );
        cheekPatch = BudgiePhenotypePalette.cheekSmokeGrey;
      }

      final hasFullBodyGreywing = hasClearwing && hasGreywing;
      if (hasFullBodyGreywing) {
        body = _mix(body, mask, 0.10);
        wingMarkings = BudgiePhenotypePalette.wingGrey;
        wingFill = BudgiePhenotypePalette.maskWhite.withValues(alpha: 0.18);
        cheekPatch = BudgiePhenotypePalette.cheekViolet;
      } else {
        if (hasGreywing) {
          body = _mix(body, mask, 0.50);
          wingMarkings = BudgiePhenotypePalette.wingGrey;
          cheekPatch = hasGrey || lower.contains('grey-green')
              ? BudgiePhenotypePalette.cheekSilver
              : BudgiePhenotypePalette.cheekPaleViolet;
        }
        if (hasClearwing) {
          body = _saturate(_lighten(body, 0.04), 0.08);
          wingMarkings = isBlueSeries
              ? BudgiePhenotypePalette.maskWhite
              : _mix(BudgiePhenotypePalette.maskYellow, Colors.white, 0.25);
          wingFill = wingMarkings.withValues(alpha: 0.30);
        }
      }

      if (hasDilute) {
        body = _mix(body, mask, 0.58);
        wingMarkings = BudgiePhenotypePalette.wingSoftGrey;
        wingFill = BudgiePhenotypePalette.maskWhite.withValues(alpha: 0.20);
        cheekPatch = _mix(cheekPatch, mask, 0.55);
      }

      if (hasEnglishFallow) {
        body = _mix(body, BudgiePhenotypePalette.warmIvory, 0.42);
        wingMarkings = BudgiePhenotypePalette.fallowTaupe;
        cheekPatch = _mix(cheekPatch, BudgiePhenotypePalette.warmIvory, 0.25);
      } else if (hasGermanFallow) {
        body = _mix(body, BudgiePhenotypePalette.warmIvory, 0.28);
        wingMarkings = BudgiePhenotypePalette.fallowTaupe;
        cheekPatch = _mix(cheekPatch, BudgiePhenotypePalette.warmIvory, 0.18);
      }

      if (hasPallid) {
        body = _mix(body, mask, 0.18);
        wingMarkings = _mix(
          wingMarkings,
          BudgiePhenotypePalette.cinnamon,
          0.35,
        );
        cheekPatch = _mix(cheekPatch, mask, 0.20);
      }

      if (hasCinnamon) {
        body = _mix(body, mask, 0.50);
        wingMarkings = BudgiePhenotypePalette.cinnamon;
      }

      if (hasSpangle) {
        wingFill = mask.withValues(alpha: 0.60);
        wingMarkings = _mix(body, wingMarkings, 0.85);
      }

      if (hasOpaline) {
        wingMarkings = _mix(wingMarkings, body, 0.18);
        if (wingFill == Colors.transparent) {
          wingFill = body.withValues(alpha: 0.16);
        }
      }

      if (hasPearly) {
        wingMarkings = _mix(wingMarkings, mask, 0.20);
        wingFill = mask.withValues(alpha: 0.20);
      }

      if (hasBlackface) {
        mask = BudgiePhenotypePalette.wingBlack;
        wingMarkings = BudgiePhenotypePalette.wingBlack;
        cheekPatch = BudgiePhenotypePalette.cheekViolet;
      }

      if (hasAnthracite) {
        cheekPatch = body;
      } else if (hasGrey || lower.contains('grey-green')) {
        cheekPatch = hasDominantClearbody
            ? BudgiePhenotypePalette.cheekSmokeGrey
            : BudgiePhenotypePalette.grey;
      }
    }

    final hasRecessivePied =
        ids.contains('recessive_pied') || lower.contains('recessive pied');
    final hasDominantPied =
        ids.contains('dominant_pied') || lower.contains('dominant pied');
    final hasClearflightPied =
        ids.contains('clearflight_pied') || lower.contains('clearflight pied');
    final hasDutchPied =
        ids.contains('dutch_pied') || lower.contains('dutch pied');

    if (!isDarkEyedClear &&
        (hasRecessivePied ||
            hasDominantPied ||
            hasClearflightPied ||
            hasDutchPied)) {
      showPiedPatch = true;
      piedPatch = _mix(mask, body, 0.30);
      if (hasRecessivePied) {
        body = _mix(body, mask, 0.10);
      }
      if (hasClearflightPied) {
        wingFill = mask.withValues(alpha: 0.28);
      }
    }

    return BudgieColorAppearance(
      bodyColor: body,
      maskColor: mask,
      wingMarkingColor: wingMarkings,
      wingFillColor: wingFill,
      cheekPatchColor: cheekPatch,
      piedPatchColor: piedPatch,
      carrierAccentColor: carrierAccentColor,
      showCheekPatch: true,
      showPiedPatch: showPiedPatch,
      showMantleHighlight: showMantleHighlight,
      showCarrierAccent: showCarrierAccent,
      hideWingMarkings: hideWingMarkings,
    );
  }

  static Color _resolveBaseBodyColor({
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

    if (lower.contains('double factor anthracite')) {
      return BudgiePhenotypePalette.anthraciteDouble;
    }
    if (lower.contains('single factor anthracite') || hasAnthracite) {
      return BudgiePhenotypePalette.anthraciteSingle;
    }
    if (lower.contains('slate') || hasSlate) {
      return BudgiePhenotypePalette.slate;
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

  static Color _resolveBaseCheekPatch({
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

  static bool _isBlueSeries(
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

  static bool _containsAny(String input, List<String> terms) {
    for (final term in terms) {
      if (input.contains(term)) return true;
    }
    return false;
  }

  static bool _containsPhrase(String input, String phrase) {
    final pattern = RegExp(
      '(^|[^a-z])${RegExp.escape(phrase)}([^a-z]|\$)',
      caseSensitive: false,
    );
    return pattern.hasMatch(input);
  }

  static String _normalizeMutationId(String raw) {
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

  static Color _resolveCarrierAccent(Set<String> carriedIds) {
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

  static Color _mix(Color a, Color b, double amount) {
    return Color.lerp(a, b, amount.clamp(0.0, 1.0)) ?? a;
  }

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _saturate(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static const List<String> _blueTerms = [
    'skyblue',
    'cobalt',
    'mauve',
    'blue',
    'albino',
    'creamino',
    'whitefaced',
    'yellowface',
    'goldenface',
  ];
}
