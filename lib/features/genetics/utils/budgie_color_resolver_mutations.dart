part of 'budgie_color_resolver.dart';

typedef _MutationResult = ({
  Color body,
  Color mask,
  Color wingMarkings,
  Color wingFill,
  Color cheekPatch,
  bool showMantleHighlight,
});

extension _MutationModifiers on BudgieColorResolver {
  static _MutationResult applyMutationModifiers({
    required Color body,
    required Color mask,
    required Color wingMarkings,
    required Color wingFill,
    required Color cheekPatch,
    required bool showMantleHighlight,
    required bool isBlueSeries,
    required bool isDoubleAnthracite,
    required bool hasTexasClearbody,
    required bool hasDominantClearbody,
    required bool hasClearwing,
    required bool hasGreywing,
    required bool hasDilute,
    required bool hasEnglishFallow,
    required bool hasGermanFallow,
    required bool hasPallid,
    required bool hasCinnamon,
    required bool hasSpangle,
    required bool hasOpaline,
    required bool hasPearly,
    required bool hasBlackface,
    required bool hasAnthracite,
    required bool hasGrey,
    required String lower,
  }) {
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

    return (
      body: body,
      mask: mask,
      wingMarkings: wingMarkings,
      wingFill: wingFill,
      cheekPatch: cheekPatch,
      showMantleHighlight: showMantleHighlight,
    );
  }
}
