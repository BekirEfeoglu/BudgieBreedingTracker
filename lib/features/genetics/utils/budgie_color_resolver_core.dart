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

    final isBlueSeries =
        _isBlueSeries(ids, lower, hasBlue, hasAqua, hasTurquoise);
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

    final special = _resolveSpecialPhenotype((
      isDarkEyedClear: isDarkEyedClear,
      isDoubleFactorSpangle: isDoubleFactorSpangle,
      isAlbino: isAlbino,
      isLutino: isLutino,
      isCreamino: isCreamino,
      isLacewing: isLacewing,
      isBlueSeries: isBlueSeries,
      currentShowMantleHighlight: showMantleHighlight,
    ));

    if (special != null) {
      body = special.body;
      mask = special.mask;
      wingMarkings = special.wingMarkings;
      cheekPatch = special.cheekPatch;
      hideWingMarkings = special.hideWingMarkings;
      showMantleHighlight = special.showMantleHighlight;
    } else {
      if (hasTexasClearbody) {
        body = _mix(
          isBlueSeries
              ? BudgiePhenotypePalette.maskWhite
              : BudgiePhenotypePalette.maskYellow,
          body,
          0.48,
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
          0.28,
        );
        cheekPatch = BudgiePhenotypePalette.cheekSmokeGrey;
      }

      final hasFullBodyGreywing = hasClearwing && hasGreywing;
      if (hasFullBodyGreywing) {
        body = _mix(body, mask, 0.10);
        wingMarkings = BudgiePhenotypePalette.wingGrey;
        wingFill = BudgiePhenotypePalette.maskWhite.withValues(alpha: 0.18);
        cheekPatch = isBlueSeries
            ? BudgiePhenotypePalette.cheekViolet
            : BudgiePhenotypePalette.cheekBlue;
      } else {
        if (hasGreywing) {
          body = _mix(body, mask, 0.28);
          wingMarkings = BudgiePhenotypePalette.wingGrey;
        }
        if (hasClearwing) {
          body = _saturate(body, 0.18);
          wingMarkings = isBlueSeries
              ? BudgiePhenotypePalette.maskWhite
              : _mix(BudgiePhenotypePalette.maskYellow, Colors.white, 0.25);
          wingFill = wingMarkings.withValues(alpha: 0.30);
        }
      }

      if (hasDilute) {
        body = _mix(body, mask, 0.72);
        wingMarkings = BudgiePhenotypePalette.wingSoftGrey;
        wingFill = BudgiePhenotypePalette.maskWhite.withValues(alpha: 0.22);
        cheekPatch = _mix(cheekPatch, mask, 0.20);
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
        body = _mix(body, mask, 0.30);
        wingMarkings = _mix(
          wingMarkings,
          BudgiePhenotypePalette.wingGrey,
          0.50,
        );
        cheekPatch = _mix(cheekPatch, mask, 0.28);
      }

      if (hasCinnamon) {
        body = _mix(body, mask, 0.35);
        wingMarkings = BudgiePhenotypePalette.cinnamon;
      }

      if (hasSpangle) {
        wingFill = mask.withValues(alpha: 0.60);
        wingMarkings = _mix(body, wingMarkings, 0.85);
      }

      if (hasOpaline) {
        wingMarkings = _mix(wingMarkings, body, 0.35);
        if (wingFill == Colors.transparent) {
          wingFill = body.withValues(alpha: 0.35);
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

    final piedResult = _detectAndApplyPied(
      ids: ids,
      lower: lower,
      isDarkEyedClear: isDarkEyedClear,
      body: body,
      mask: mask,
      wingFill: wingFill,
    );
    if (piedResult != null) {
      body = piedResult.body;
      piedPatch = piedResult.piedPatch;
      wingFill = piedResult.wingFill;
      showPiedPatch = true;
    }

    final hasRecessivePied =
        ids.contains('recessive_pied') || lower.contains('recessive pied');
    final anatomy = _resolveAnatomyDetails(
      isAlbino: isAlbino, isLutino: isLutino,
      isCreamino: isCreamino, isLacewing: isLacewing,
      isDarkEyedClear: isDarkEyedClear,
      isDoubleFactorSpangle: isDoubleFactorSpangle,
      isBlueSeries: isBlueSeries, hasOpaline: hasOpaline,
      hasCinnamon: hasCinnamon, hasDilute: hasDilute,
      hasGreywing: hasGreywing, hasEnglishFallow: hasEnglishFallow,
      hasGermanFallow: hasGermanFallow, hasRecessivePied: hasRecessivePied,
      hasTexasClearbody: hasTexasClearbody, body: body,
    );

    final hasDutchPied =
        ids.contains('dutch_pied') || lower.contains('dutch pied');
    final hasDominantPied =
        ids.contains('dominant_pied') || lower.contains('dominant pied');

    return BudgieColorAppearance(
      bodyColor: body, maskColor: mask,
      wingMarkingColor: wingMarkings, wingFillColor: wingFill,
      cheekPatchColor: cheekPatch, piedPatchColor: piedPatch,
      carrierAccentColor: carrierAccentColor,
      eyeColor: anatomy.eyeColor, eyeRingColor: anatomy.eyeRingColor,
      showEyeRing: anatomy.showEyeRing, backColor: anatomy.backColor,
      tailColor: anatomy.tailColor, throatSpotColor: anatomy.throatSpotColor,
      showThroatSpots: anatomy.showThroatSpots,
      throatSpotCount: anatomy.throatSpotCount, beakColor: anatomy.beakColor,
      showPiedPatch: showPiedPatch, showMantleHighlight: showMantleHighlight,
      showCarrierAccent: showCarrierAccent, hideWingMarkings: hideWingMarkings,
      isSpangle: hasSpangle && !isDoubleFactorSpangle,
      isDutchPied: hasDutchPied,
      isDominantPied: hasDominantPied,
    );
  }
}
