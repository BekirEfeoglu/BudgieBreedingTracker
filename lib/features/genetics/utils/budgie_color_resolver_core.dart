part of 'budgie_color_resolver.dart';

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
    final isDoubleAnthracite =
        lower.contains('double factor anthracite') ||
        lower.contains('df anthracite');

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
      }
      // YF1 / Blue Factor I: yellow confined to mask only, no body suffusion.
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
        wingMarkings = BudgiePhenotypePalette.wingBlack;
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
        cheekPatch = isDoubleAnthracite
            ? body
            : _mix(
                cheekPatch,
                isBlueSeries
                    ? BudgiePhenotypePalette.anthraciteSingle
                    : BudgiePhenotypePalette.anthraciteGreenSingle,
                0.18,
              );
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
}
