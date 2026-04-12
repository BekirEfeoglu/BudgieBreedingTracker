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
  // Violet applied BEFORE cobalt/mauve so it modifies dark factor bases
  if ((lower.contains('violet') || hasViolet) && isBlueSeries) {
    if (lower.contains('mauve')) {
      return _mix(BudgiePhenotypePalette.mauve, BudgiePhenotypePalette.violet, 0.40);
    }
    if (lower.contains('cobalt') || lower.contains('visual violet')) {
      return BudgiePhenotypePalette.violet;
    }
    return _mix(
      BudgiePhenotypePalette.skyBlue,
      BudgiePhenotypePalette.violet,
      0.55,
    );
  }
  if (lower.contains('mauve')) {
    return BudgiePhenotypePalette.mauve;
  }
  if (lower.contains('cobalt')) {
    return BudgiePhenotypePalette.cobalt;
  }
  if (isBlueSeries) {
    return BudgiePhenotypePalette.skyBlue;
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
      BudgiePhenotypePalette.slate,
      0.40,
    );
  }
  return _mix(
    BudgiePhenotypePalette.lightGreen,
    BudgiePhenotypePalette.slate,
    0.40,
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
      0.50,
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

typedef SpecialPhenotypeResult = ({
  Color body,
  Color mask,
  Color wingMarkings,
  Color cheekPatch,
  bool hideWingMarkings,
  bool showMantleHighlight,
});

typedef SpecialPhenotypeFlags = ({
  bool isDarkEyedClear,
  bool isDoubleFactorSpangle,
  bool isAlbino,
  bool isLutino,
  bool isCreamino,
  bool isLacewing,
  bool isBlueSeries,
  bool currentShowMantleHighlight,
});

/// Resolves complete color overrides for special compound phenotypes
/// (Dark-Eyed Clear, Double Factor Spangle, and Ino variants).
///
/// Returns null if no special phenotype applies, allowing the caller
/// to fall through to individual mutation modifiers.
SpecialPhenotypeResult? _resolveSpecialPhenotype(SpecialPhenotypeFlags f) {
  if (f.isDarkEyedClear) return _resolveDarkEyedClear(f.isBlueSeries);
  if (f.isDoubleFactorSpangle) return _resolveDoubleFactorSpangle(f.isBlueSeries);
  if (f.isAlbino || f.isLutino || f.isCreamino || f.isLacewing) {
    return _resolveInoVariant(f);
  }
  return null;
}

SpecialPhenotypeResult _resolveDarkEyedClear(bool isBlueSeries) {
  final body = isBlueSeries
      ? BudgiePhenotypePalette.maskWhite
      : BudgiePhenotypePalette.maskYellow;
  return (
    body: body,
    mask: body,
    wingMarkings: Colors.transparent,
    cheekPatch: BudgiePhenotypePalette.maskWhite,
    hideWingMarkings: true,
    showMantleHighlight: false,
  );
}

SpecialPhenotypeResult _resolveDoubleFactorSpangle(bool isBlueSeries) {
  final body = isBlueSeries
      ? BudgiePhenotypePalette.maskWhite
      : BudgiePhenotypePalette.maskYellow;
  return (
    body: body,
    mask: body,
    wingMarkings: const Color(0x28808080),
    cheekPatch: BudgiePhenotypePalette.cheekSilver,
    hideWingMarkings: false,
    showMantleHighlight: false,
  );
}

SpecialPhenotypeResult _resolveInoVariant(SpecialPhenotypeFlags f) {
  Color body, mask, cheekPatch;
  if (f.isAlbino) {
    body = BudgiePhenotypePalette.maskWhite;
    mask = BudgiePhenotypePalette.maskWhite;
    cheekPatch = BudgiePhenotypePalette.maskWhite;
  } else if (f.isCreamino) {
    body = BudgiePhenotypePalette.cream;
    mask = BudgiePhenotypePalette.warmIvory;
    cheekPatch = BudgiePhenotypePalette.cheekPaleViolet;
  } else {
    body = BudgiePhenotypePalette.lutino;
    mask = BudgiePhenotypePalette.maskYellow;
    cheekPatch = BudgiePhenotypePalette.maskWhite;
  }

  if (f.isLacewing) {
    body = f.isBlueSeries
        ? BudgiePhenotypePalette.warmIvory
        : BudgiePhenotypePalette.cream;
    return (
      body: body,
      mask: body,
      wingMarkings: BudgiePhenotypePalette.cinnamon,
      cheekPatch: BudgiePhenotypePalette.cheekPaleViolet,
      hideWingMarkings: false,
      showMantleHighlight: f.currentShowMantleHighlight,
    );
  }

  return (
    body: body,
    mask: mask,
    wingMarkings: Colors.transparent,
    cheekPatch: cheekPatch,
    hideWingMarkings: true,
    showMantleHighlight: f.currentShowMantleHighlight,
  );
}

