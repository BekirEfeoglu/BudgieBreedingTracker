import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

enum BirdGender {
  male,
  female,
  unknown;

  String toJson() => name;
  static BirdGender fromJson(String json) => values.byName(json);
}

enum BirdStatus {
  alive,
  dead,
  sold,
  unknown;

  String toJson() => name;
  static BirdStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return BirdStatus.unknown;
    }
  }
}

enum Species {
  budgie,
  canary,
  finch,
  other,
  unknown;

  String toJson() => name;
  static Species fromJson(String json) => switch (json) {
    'budgie' || 'muhabbet' => Species.budgie,
    'canary' || 'kanarya' => Species.canary,
    'finch' || 'ispinoz' => Species.finch,
    'other' => Species.other,
    _ => Species.unknown,
  };
}

enum BirdColor {
  green,
  blue,
  yellow,
  white,
  grey,
  violet,
  lutino,
  albino,
  cinnamon,
  opaline,
  spangle,
  pied,
  clearwing,
  other,
  unknown;

  String toJson() => name;
  static BirdColor fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return BirdColor.unknown;
    }
  }
}

/// Returns the appropriate SVG icon widget for a [Species].
/// Uses species-specific custom SVG assets.
Widget speciesIconWidget(Species species, {double? size, Color? color}) =>
    switch (species) {
      Species.budgie => AppIcon(AppIcons.budgie, size: size, color: color),
      Species.canary => AppIcon(AppIcons.canary, size: size, color: color),
      Species.finch => AppIcon(AppIcons.finch, size: size, color: color),
      Species.other ||
      Species.unknown => AppIcon(AppIcons.birdOther, size: size, color: color),
    };
