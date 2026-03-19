import 'package:flutter/material.dart';

part 'budgie_color_resolver_core.dart';
part 'budgie_color_resolver_helpers.dart';

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
  static const grey = Color(0xFF8A9098);
  static const slate = Color(0xFF647E90);
  static const anthraciteSingle = Color(0xFF57646E);
  static const anthraciteDouble = Color(0xFF3F474F);
  static const anthraciteGreenSingle = Color(0xFF4F8120);
  static const anthraciteGreenDouble = Color(0xFF4B5A24);

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
